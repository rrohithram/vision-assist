import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/sensor_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Regression tests for the fall/shake detection state machine.
///
/// This logic decides whether the app dials emergency services on its own,
/// so a false positive and a missed real fall are both real-world harms.
/// Real hardware sensors are never involved: [SensorService.debugClock] and
/// [SensorService.handleAccelerometerEventForTest] drive the state machine
/// directly with synthetic samples and a controlled clock.
void main() {
  late SensorService sensor;
  late DateTime clock;

  void setClock(DateTime time) => clock = time;
  void advance(Duration by) => clock = clock.add(by);

  /// Free fall -> impact -> stillness, the only sequence that should ever
  /// trigger a fall alert. Leaves [clock] at the moment stillness confirms.
  void simulateFullFall(DateTime start) {
    setClock(start);
    sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 1.0));

    advance(const Duration(milliseconds: 300));
    sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 35.0));

    advance(const Duration(milliseconds: 100));
    sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 9.81, 0));

    advance(const Duration(milliseconds: 1500));
    sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 9.81, 0));
  }

  setUp(() {
    sensor = SensorService();
    sensor.resetStateForTest();
    clock = DateTime(2024, 1, 1);
    sensor.debugClock = () => clock;
    sensor.onFallDetected = null;
    sensor.onVigorousShakeDetected = null;
    sensor.onOrientationChanged = null;
    sensor.onOrientationWarning = null;
  });

  group('fall detection', () {
    test('free fall, then impact, then stillness triggers a fall alert', () {
      var calls = 0;
      sensor.onFallDetected = () => calls++;

      simulateFullFall(DateTime(2024, 1, 1));

      expect(calls, 1);
    });

    test('an impact with no preceding free fall never fires - setting the '
        'phone down hard is not a fall', () {
      var calls = 0;
      sensor.onFallDetected = () => calls++;

      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 35.0));
      advance(const Duration(seconds: 2));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 9.81, 0));

      expect(calls, 0);
    });

    test('impact without settling within the window stands down without '
        'alerting - the user caught themselves', () {
      var calls = 0;
      sensor.onFallDetected = () => calls++;

      setClock(DateTime(2024, 1, 1));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 1.0));

      advance(const Duration(milliseconds: 300));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 35.0));

      // Well past stillnessDuration (1.5s) + impactWindow (0.8s) without ever
      // reporting a stillness-range magnitude.
      advance(const Duration(milliseconds: 2400));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 5.0));

      expect(calls, 0);

      // State must have actually reset - a fresh, valid sequence afterwards
      // should still be able to trigger.
      simulateFullFall(clock.add(const Duration(seconds: 1)));
      expect(calls, 1);
    });

    test('a second fall within the cooldown window is suppressed', () {
      var calls = 0;
      sensor.onFallDetected = () => calls++;

      simulateFullFall(DateTime(2024, 1, 1));
      expect(calls, 1);

      // Well inside the 10s cooldown.
      simulateFullFall(clock.add(const Duration(milliseconds: 500)));
      expect(calls, 1, reason: 'cooldown must block a second alert this soon');
    });

    test('a fall after the cooldown expires alerts again', () {
      var calls = 0;
      sensor.onFallDetected = () => calls++;

      simulateFullFall(DateTime(2024, 1, 1));
      expect(calls, 1);

      simulateFullFall(clock.add(const Duration(seconds: 11)));
      expect(calls, 2);
    });
  });

  group('shake-to-SOS', () {
    test('5 shakes within the window trigger SOS once', () {
      var calls = 0;
      sensor.onVigorousShakeDetected = () => calls++;

      setClock(DateTime(2024, 1, 1));
      for (var i = 0; i < 5; i++) {
        sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0));
        advance(const Duration(milliseconds: 300));
      }

      expect(calls, 1);
    });

    test('samples inside the debounce window count as a single shake', () {
      var calls = 0;
      sensor.onVigorousShakeDetected = () => calls++;

      setClock(DateTime(2024, 1, 1));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0)); // counted 1

      advance(const Duration(milliseconds: 100)); // inside the 250ms debounce
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0)); // not counted

      advance(const Duration(milliseconds: 300));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0)); // counted 2
      advance(const Duration(milliseconds: 300));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0)); // counted 3
      advance(const Duration(milliseconds: 300));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0)); // counted 4

      expect(calls, 0, reason: 'only 4 shakes have actually been counted');

      advance(const Duration(milliseconds: 300));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0)); // counted 5

      expect(calls, 1);
    });

    test('the count resets once the shake window elapses', () {
      var calls = 0;
      sensor.onVigorousShakeDetected = () => calls++;

      setClock(DateTime(2024, 1, 1));
      for (var i = 0; i < 4; i++) {
        sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0));
        advance(const Duration(milliseconds: 300));
      }

      // Past the 3s shake window since the first shake.
      advance(const Duration(seconds: 3));
      sensor.handleAccelerometerEventForTest(AccelerometerEvent(0, 0, 30.0));

      expect(calls, 0, reason: 'the stale count must not carry over');
    });
  });
}
