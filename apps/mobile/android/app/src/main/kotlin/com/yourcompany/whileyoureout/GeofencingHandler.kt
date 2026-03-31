package com.yourcompany.whileyoureout

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Flutter plugin that bridges Android GeofencingClient to the Dart platform channel. */
class GeofencingHandler : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var geofencingClient: GeofencingClient
    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        geofencingClient = LocationServices.getGeofencingClient(context)

        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "com.yourcompany.whileyoureout/geofencing"
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "com.yourcompany.whileyoureout/geofencing/events"
        )
        eventChannel.setStreamHandler(this)

        // Make the event sink available to the BroadcastReceiver
        GeofenceEventBus.handler = this
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        GeofenceEventBus.handler = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "registerRegion" -> {
                val id = call.argument<String>("id") ?: return result.error("INVALID_ARGS", "Missing id", null)
                val latitude = call.argument<Double>("latitude") ?: return result.error("INVALID_ARGS", "Missing latitude", null)
                val longitude = call.argument<Double>("longitude") ?: return result.error("INVALID_ARGS", "Missing longitude", null)
                val radius = (call.argument<Double>("radius") ?: 100.0).coerceIn(100.0, 5000.0).toFloat()
                val trigger = call.argument<String>("trigger") ?: "enter"

                val transitionTypes = when (trigger) {
                    "exit" -> Geofence.GEOFENCE_TRANSITION_EXIT
                    "enterAndExit" -> Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT
                    else -> Geofence.GEOFENCE_TRANSITION_ENTER
                }

                val geofence = Geofence.Builder()
                    .setRequestId(id)
                    .setCircularRegion(latitude, longitude, radius)
                    .setExpirationDuration(Geofence.NEVER_EXPIRE)
                    .setTransitionTypes(transitionTypes)
                    .build()

                val request = GeofencingRequest.Builder()
                    .setInitialTrigger(0)
                    .addGeofence(geofence)
                    .build()

                try {
                    geofencingClient.addGeofences(request, getGeofencePendingIntent())
                        .addOnSuccessListener { result.success(null) }
                        .addOnFailureListener { e -> result.error("ADD_FAILED", e.message, null) }
                } catch (e: SecurityException) {
                    result.error("PERMISSION_DENIED", e.message, null)
                }
            }

            "unregisterRegion" -> {
                val id = call.argument<String>("id") ?: return result.error("INVALID_ARGS", "Missing id", null)
                geofencingClient.removeGeofences(listOf(id))
                    .addOnSuccessListener { result.success(null) }
                    .addOnFailureListener { e -> result.error("REMOVE_FAILED", e.message, null) }
            }

            "unregisterAll" -> {
                geofencingClient.removeGeofences(getGeofencePendingIntent())
                    .addOnSuccessListener { result.success(null) }
                    .addOnFailureListener { e -> result.error("REMOVE_FAILED", e.message, null) }
            }

            else -> result.notImplemented()
        }
    }

    // MARK: StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendEvent(regionId: String, transitionType: Int) {
        val type = if (transitionType == Geofence.GEOFENCE_TRANSITION_ENTER) "enter" else "exit"
        val timestamp = java.time.Instant.now().toString()
        eventSink?.success(mapOf("regionId" to regionId, "type" to type, "timestamp" to timestamp))
    }

    private fun getGeofencePendingIntent(): PendingIntent {
        val intent = Intent(context, GeofenceReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }
}

/** Simple singleton bus so GeofenceReceiver can forward events to the handler. */
object GeofenceEventBus {
    var handler: GeofencingHandler? = null
}
