import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// Subscribes to [GeofenceService.events] and dispatches entry events to
/// [HandleGeofenceEntryUseCase].
///
/// Create one instance at app startup (after DI is ready) and call [start].
/// Call [dispose] when the app is shutting down to cancel the stream
/// subscription and free resources.
///
/// In debug builds, each [HandleGeofenceEntryUseCase] invocation is wrapped
/// with a [Stopwatch]. A debug-mode assertion fires if the call exceeds 8 s —
/// the iOS background execution budget for a location event.
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
        await _dispatchEntry(event.regionId);
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

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Calls [HandleGeofenceEntryUseCase] for [regionId].
  ///
  /// In debug builds, wraps the call in a [Stopwatch] and prints the elapsed
  /// time. A debug assertion fires if the call exceeds 8 s — the iOS
  /// background-execution budget for a location event.
  Future<void> _dispatchEntry(String regionId) async {
    if (kDebugMode) {
      final sw = Stopwatch()..start();
      await _handleEntry(regionId);
      sw.stop();
      debugPrint(
        '[Geofence] HandleEntry for $regionId completed in '
        '${sw.elapsedMilliseconds} ms',
      );
      assert(
        sw.elapsedMilliseconds < 8000,
        'HandleGeofenceEntryUseCase exceeded the 8 s iOS background budget '
        '(took ${sw.elapsedMilliseconds} ms for region $regionId).',
      );
    } else {
      await _handleEntry(regionId);
    }
  }
}
