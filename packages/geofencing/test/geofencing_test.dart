import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofencing/geofencing.dart';

const _methodChannelName = 'com.yourcompany.whileyoureout/geofencing';
const _eventChannelName = 'com.yourcompany.whileyoureout/geofencing/events';

/// A minimal [MockStreamHandler] driven by a single [onListen] callback.
class _MockStreamHandler extends MockStreamHandler {
  _MockStreamHandler({
    required void Function(Object?, MockStreamHandlerEventSink) onListen,
  }) : _onListenCallback = onListen;

  final void Function(Object?, MockStreamHandlerEventSink) _onListenCallback;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) =>
      _onListenCallback(arguments, events);

  @override
  void onCancel(Object? arguments) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel(_methodChannelName);
  const eventChannel = EventChannel(_eventChannelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, null);
  });

  group('RealGeofenceService', () {
    test('registerRegion sends correct method call', () async {
      MethodCall? capturedCall;

      // A no-op stream handler keeps the constructor's .listen() happy.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        _MockStreamHandler(onListen: (_, __) {}),
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall call) async {
          capturedCall = call;
          return null;
        },
      );

      final service = RealGeofenceService();
      final region = GeofenceRegion(
        id: 'test-region-id',
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMeters: 200,
        createdAt: DateTime(2024),
        label: 'Test Region',
      );

      await service.registerRegion(region);

      expect(capturedCall, isNotNull);
      expect(capturedCall!.method, equals('registerRegion'));
      expect(
        capturedCall!.arguments,
        equals(<String, Object>{
          'id': 'test-region-id',
          'latitude': 37.7749,
          'longitude': -122.4194,
          'radius': 200.0,
          'trigger': 'enter',
        }),
      );

      await service.dispose();
    });

    test('unregisterAll sends correct method call', () async {
      MethodCall? capturedCall;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        _MockStreamHandler(onListen: (_, __) {}),
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall call) async {
          capturedCall = call;
          return null;
        },
      );

      final service = RealGeofenceService();
      await service.unregisterAll();

      expect(capturedCall, isNotNull);
      expect(capturedCall!.method, equals('unregisterAll'));

      await service.dispose();
    });

    test('event channel emits GeofenceEvent on enter', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (_) async => null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        _MockStreamHandler(
          onListen: (_, sink) {
            sink.success(<String, String>{
              'regionId': 'test-id',
              'type': 'enter',
              'timestamp': '2024-01-01T00:00:00.000Z',
            });
          },
        ),
      );

      final service = RealGeofenceService();
      final event = await service.events.first;

      expect(event.regionId, equals('test-id'));
      expect(event.type, equals(GeofenceEventType.enter));
      expect(
        event.timestamp,
        equals(DateTime.parse('2024-01-01T00:00:00.000Z')),
      );

      await service.dispose();
    });
  });
}
