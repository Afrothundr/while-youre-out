import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.yourcompany.whileyoureout/geofencing');
const _eventChannel =
    EventChannel('com.yourcompany.whileyoureout/geofencing/events');

/// A production implementation of [GeofenceService] backed by Flutter platform
/// channels.
///
/// On iOS the native side communicates via `CLLocationManager`; on Android via
/// `GeofencingClient`. Construct this once and inject it wherever a
/// [GeofenceService] is needed.
///
/// Call [dispose] when the service is no longer required to release the
/// underlying stream resources.
class RealGeofenceService implements GeofenceService {
  /// Creates a [RealGeofenceService] and immediately begins forwarding native
  /// geofence events onto [events].
  RealGeofenceService() {
    _eventsController = StreamController<GeofenceEvent>.broadcast();
    _eventChannel.receiveBroadcastStream().listen(
          _onNativeEvent,
          onError: _eventsController.addError,
        );
  }

  late final StreamController<GeofenceEvent> _eventsController;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _onNativeEvent(dynamic rawEvent) {
    final map = Map<String, dynamic>.from(rawEvent as Map);
    final regionId = map['regionId'] as String;
    final rawType = map['type'] as String;
    final rawTimestamp = map['timestamp'] as String;

    final type =
        rawType == 'exit' ? GeofenceEventType.exit : GeofenceEventType.enter;

    _eventsController.add(
      GeofenceEvent(
        regionId: regionId,
        type: type,
        timestamp: DateTime.parse(rawTimestamp),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GeofenceService
  // ---------------------------------------------------------------------------

  @override
  Future<void> registerRegion(GeofenceRegion region) async {
    await _channel.invokeMethod<void>(
      'registerRegion',
      <String, Object>{
        'id': region.id,
        'latitude': region.latitude,
        'longitude': region.longitude,
        'radius': region.radiusMeters.clamp(100, 5000),
        'trigger': region.trigger.name,
      },
    );
  }

  @override
  Future<void> unregisterRegion(String regionId) async {
    await _channel.invokeMethod<void>(
      'unregisterRegion',
      <String, String>{'id': regionId},
    );
  }

  @override
  Future<void> unregisterAll() async {
    await _channel.invokeMethod<void>('unregisterAll');
  }

  @override
  Stream<GeofenceEvent> get events => _eventsController.stream;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Closes the internal broadcast controller and releases all resources.
  ///
  /// After calling [dispose], [events] will no longer emit items. Any callers
  /// still subscribed to the stream will receive an `onDone` notification.
  Future<void> dispose() => _eventsController.close();
}
