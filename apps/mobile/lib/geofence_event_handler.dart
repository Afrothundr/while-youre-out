import 'dart:async';

import 'package:domain/domain.dart';

/// Subscribes to [GeofenceService.events] and dispatches entry events to
/// [HandleGeofenceEntryUseCase].
///
/// Create one instance at app startup (after DI is ready) and call [start].
/// Call [dispose] when the app is shutting down to cancel the stream
/// subscription and free resources.
///
/// Example:
/// ```dart
/// final handler = GeofenceEventHandler(
///   geofenceService: ref.read(geofenceServiceProvider),
///   handleEntry: ref.read(handleGeofenceEntryUseCaseProvider),
/// );
/// handler.start();
/// ```
class GeofenceEventHandler {
  /// Creates a [GeofenceEventHandler].
  GeofenceEventHandler({
    required GeofenceService geofenceService,
    required HandleGeofenceEntryUseCase handleEntry,
  })  : _geofenceService = geofenceService,
        _handleEntry = handleEntry;

  final GeofenceService _geofenceService;
  final HandleGeofenceEntryUseCase _handleEntry;

  StreamSubscription<GeofenceEvent>? _subscription;

  /// Starts listening to [GeofenceService.events].
  ///
  /// Safe to call multiple times — subsequent calls are no-ops if already
  /// started.
  void start() {
    if (_subscription != null) return;

    _subscription = _geofenceService.events.listen((event) async {
      if (event.type == GeofenceEventType.enter) {
        await _handleEntry(event.regionId);
      }
    });
  }

  /// Cancels the stream subscription and releases resources.
  ///
  /// After calling [dispose], [start] may be called again to re-subscribe.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
