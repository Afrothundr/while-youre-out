package com.yourcompany.whileyoureout

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.android.gms.location.Geofence
import java.io.File

/**
 * WorkManager [CoroutineWorker] that handles a geofence-entry event entirely
 * in native code.
 *
 * This worker is enqueued by [GeofenceReceiver] when the Flutter engine is NOT
 * attached (i.e. the app process has been killed by Android). It:
 *   1. Opens the on-device SQLite database written by drift/Flutter.
 *   2. Looks up the [TodoList] whose `geofence_id` matches [KEY_REGION_ID].
 *   3. Counts the list's incomplete todo items.
 *   4. Posts a [NotificationCompat] notification so the user is alerted even
 *      though the Flutter layer is not running.
 *
 * The worker is idempotent — if the geofence region maps to no list, or if
 * `notify_on_enter` is 0 for that list, it exits cleanly without posting.
 *
 * Database path convention:
 *   [Context.getFilesDir] / "while_youre_out.db"
 * This matches the path produced by `path_provider`'s
 * `getApplicationDocumentsDirectory()` on Android, which drift uses in
 * `packages/data/lib/src/database/app_database.dart`.
 */
class GeofenceWorker(
    private val appContext: Context,
    workerParams: WorkerParameters,
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val regionId = inputData.getString(KEY_REGION_ID)
        val transitionType = inputData.getInt(KEY_TRANSITION_TYPE, TRANSITION_UNKNOWN)

        if (regionId.isNullOrBlank()) {
            Log.w(TAG, "doWork: missing regionId — skipping")
            return Result.failure()
        }

        // This worker only handles entry transitions.
        if (transitionType != Geofence.GEOFENCE_TRANSITION_ENTER) {
            Log.d(TAG, "doWork: ignoring non-enter transition $transitionType for region $regionId")
            return Result.success()
        }

        Log.d(TAG, "doWork: handling ENTER for region $regionId")

        return try {
            handleEntry(regionId)
            Result.success()
        } catch (e: SQLiteException) {
            Log.e(TAG, "doWork: SQLiteException for region $regionId", e)
            // Retry once; if the DB is still unavailable, give up.
            if (runAttemptCount < MAX_RETRY_COUNT) Result.retry() else Result.failure()
        } catch (e: Exception) {
            Log.e(TAG, "doWork: unexpected error for region $regionId", e)
            Result.failure()
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Opens the SQLite database, resolves the matching todo list, counts
     * incomplete items, then posts a notification.
     *
     * The database is opened read-only; we never mutate app data from this
     * background worker.
     */
    private fun handleEntry(regionId: String) {
        val dbFile = File(appContext.filesDir, DB_NAME)
        if (!dbFile.exists()) {
            Log.w(TAG, "handleEntry: database not found at ${dbFile.absolutePath}")
            return
        }

        SQLiteDatabase.openDatabase(
            dbFile.absolutePath,
            /* factory = */ null,
            SQLiteDatabase.OPEN_READONLY,
        ).use { db ->
            val listRow = queryListByGeofenceId(db, regionId) ?: run {
                Log.d(TAG, "handleEntry: no list found for geofence $regionId")
                return
            }

            val (listId, listTitle, notifyOnEnter) = listRow

            if (!notifyOnEnter) {
                Log.d(TAG, "handleEntry: notify_on_enter=false for list $listId — skipping")
                return
            }

            val incompleteCount = countIncompleteItems(db, listId)
            Log.d(TAG, "handleEntry: posting notification for '$listTitle' ($incompleteCount incomplete)")
            postNotification(listId, listTitle, incompleteCount)
        }
    }

    /**
     * Returns a [ListRow] for the list whose `geofence_id` equals [regionId],
     * or null if none exists.
     */
    private fun queryListByGeofenceId(db: SQLiteDatabase, regionId: String): ListRow? {
        db.rawQuery(
            """
            SELECT id, title, notify_on_enter
              FROM todo_lists
             WHERE geofence_id = ?
             LIMIT 1
            """.trimIndent(),
            arrayOf(regionId),
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            return ListRow(
                id = cursor.getString(0),
                title = cursor.getString(1),
                notifyOnEnter = cursor.getInt(2) != 0,
            )
        }
    }

    /**
     * Returns the number of todo items for [listId] where `is_done = 0`.
     */
    private fun countIncompleteItems(db: SQLiteDatabase, listId: String): Int {
        db.rawQuery(
            """
            SELECT COUNT(*)
              FROM todo_items
             WHERE list_id = ?
               AND is_done = 0
            """.trimIndent(),
            arrayOf(listId),
        ).use { cursor ->
            return if (cursor.moveToFirst()) cursor.getInt(0) else 0
        }
    }

    /**
     * Posts a high-importance notification for [listTitle].
     *
     * The notification channel is created if it doesn't already exist (the
     * call is idempotent on Android O+). The channel id matches the one
     * created by `FlutterNotificationService` in the Dart layer so that both
     * code paths share the same channel settings set by the user.
     *
     * The notification id is derived from [listId] so that repeated entry
     * events for the same list replace the previous notification rather than
     * stacking.
     */
    private fun postNotification(listId: String, listTitle: String, incompleteCount: Int) {
        val nm = appContext.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager

        // Ensure the channel exists — idempotent on Android O+.
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = CHANNEL_DESCRIPTION
        }
        nm.createNotificationChannel(channel)

        val body = if (incompleteCount == 1) "1 item remaining"
                   else "$incompleteCount items remaining"

        // Tapping the notification will launch the app. A future improvement
        // could pass the listId as a deep-link extra once the routing layer
        // supports reading launch intents from native code.
        val launchIntent = appContext.packageManager
            .getLaunchIntentForPackage(appContext.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_LIST_ID, listId)
            }

        val pendingIntent = launchIntent?.let {
            PendingIntent.getActivity(
                appContext,
                listId.hashCode(),
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(listTitle)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .apply { pendingIntent?.let { setContentIntent(it) } }
            .build()

        NotificationManagerCompat.from(appContext)
            .notify(listId.hashCode(), notification)
    }

    // -------------------------------------------------------------------------
    // Internal data
    // -------------------------------------------------------------------------

    /** Projection row returned by [queryListByGeofenceId]. */
    private data class ListRow(
        val id: String,
        val title: String,
        val notifyOnEnter: Boolean,
    )

    companion object {
        private const val TAG = "GeofenceWorker"

        /** Input data key: the geofence region id (String). */
        const val KEY_REGION_ID = "region_id"

        /** Input data key: the [Geofence] transition type constant (Int). */
        const val KEY_TRANSITION_TYPE = "transition_type"

        private const val TRANSITION_UNKNOWN = -1
        private const val MAX_RETRY_COUNT = 1

        /**
         * SQLite database file name.
         *
         * Must match the filename used in
         * `packages/data/lib/src/database/app_database.dart`:
         * ```dart
         * final file = File(p.join(dbFolder.path, 'while_youre_out.db'));
         * ```
         */
        private const val DB_NAME = "while_youre_out.db"

        /**
         * Notification channel id.
         *
         * Must stay in sync with the channel id in
         * `packages/notifications/lib/src/flutter_notification_service.dart`
         * so that both the native and Flutter code paths share user-visible
         * channel settings.
         */
        private const val CHANNEL_ID = "geofence_alerts"
        private const val CHANNEL_NAME = "Location Reminders"
        private const val CHANNEL_DESCRIPTION =
            "Notifications when you arrive at a saved location"

        /** Intent extra key carrying the list id to the launched Activity. */
        const val EXTRA_LIST_ID = "list_id"
    }
}
