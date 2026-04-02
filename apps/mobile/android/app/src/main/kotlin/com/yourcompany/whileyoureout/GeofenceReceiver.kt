package com.yourcompany.whileyoureout

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

/**
 * Receives geofence transition broadcasts from the OS and dispatches them to
 * the appropriate handler depending on whether the Flutter engine is alive.
 *
 * ## Dispatch strategy
 *
 * | Flutter engine state | Action taken |
 * |---|---|
 * | Attached (app in foreground or active background process) | Forward to [GeofenceEventBus] → EventChannel → Dart [GeofenceEventHandler] |
 * | Detached (app process killed by Android) | Enqueue a [GeofenceWorker] via WorkManager so the event is handled natively |
 *
 * Using WorkManager for the killed-process case guarantees that geofence
 * entry events are processed reliably: WorkManager survives process death
 * and will start a new process to run the worker if needed.
 *
 * The two paths are mutually exclusive to avoid duplicate notifications:
 * - When the Flutter engine is attached, [GeofenceWorker] is NOT enqueued.
 * - When the Flutter engine is detached, the EventBus call is a no-op anyway
 *   (the handler is null), so we skip it and go straight to WorkManager.
 */
class GeofenceReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: run {
            Log.w(TAG, "onReceive: could not parse GeofencingEvent from intent")
            return
        }

        if (event.hasError()) {
            Log.w(TAG, "onReceive: GeofencingEvent has error code ${event.errorCode}")
            return
        }

        val transition = event.geofenceTransition
        if (transition != Geofence.GEOFENCE_TRANSITION_ENTER &&
            transition != Geofence.GEOFENCE_TRANSITION_EXIT
        ) {
            Log.d(TAG, "onReceive: ignoring unsupported transition type $transition")
            return
        }

        val geofences = event.triggeringGeofences
        if (geofences.isNullOrEmpty()) {
            Log.d(TAG, "onReceive: no triggering geofences — nothing to dispatch")
            return
        }

        val engineAttached = GeofenceEventBus.handler != null

        geofences.forEach { geofence ->
            val regionId = geofence.requestId
            Log.d(
                TAG,
                "onReceive: transition=$transition regionId=$regionId " +
                    "engineAttached=$engineAttached",
            )

            if (engineAttached) {
                // Flutter engine is running — forward via the live EventChannel.
                // The Dart GeofenceEventHandler will call HandleGeofenceEntryUseCase
                // and post the notification through flutter_local_notifications.
                GeofenceEventBus.handler?.sendEvent(regionId, transition)
            } else {
                // Flutter engine is NOT running (app was killed by Android).
                // Enqueue a WorkManager job so the event is handled natively
                // by GeofenceWorker even after the process is restarted.
                enqueueWorker(context, regionId, transition)
            }
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Enqueues a [GeofenceWorker] [OneTimeWorkRequestBuilder] carrying [regionId]
     * and [transitionType] as input data.
     *
     * WorkManager persists the request to its internal Room database and will
     * start a new process to run the worker if the current process is dead,
     * subject to device constraints (battery, network, etc.). For geofence
     * alerts no constraints are required, so the work runs as soon as a
     * worker thread is available.
     */
    private fun enqueueWorker(context: Context, regionId: String, transitionType: Int) {
        val inputData = Data.Builder()
            .putString(GeofenceWorker.KEY_REGION_ID, regionId)
            .putInt(GeofenceWorker.KEY_TRANSITION_TYPE, transitionType)
            .build()

        val workRequest = OneTimeWorkRequestBuilder<GeofenceWorker>()
            .setInputData(inputData)
            .addTag("geofence_$regionId")
            .build()

        WorkManager.getInstance(context).enqueue(workRequest)

        Log.d(TAG, "enqueueWorker: enqueued GeofenceWorker for region $regionId")
    }

    companion object {
        private const val TAG = "GeofenceReceiver"
    }
}
