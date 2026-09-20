import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/obstacle_interpreter.dart';
import 'package:gabn2/services/obstacle_vocabulary.dart';

/// Covers what the app decides to tell you about.
///
/// The old filter used box width alone as a stand-in for distance, which
/// got two things badly wrong: a person a couple of metres away is narrow
/// and tall, so they read as far away, and a parked car across the street
/// is wide, so it read as close. Everything here is pure geometry, so it
/// runs with no camera and no model.
void main() {
  /// A box in normalised frame coordinates.
  Rect box({
    required double left,
    required double top,
    required double width,
    required double height,
  }) =>
      Rect.fromLTWH(left, top, width, height);

  RawDetection detect(String className, Rect where, {double confidence = 0.9}) =>
      RawDetection(className: className, confidence: confidence, box: where);

  /// A big object filling the lower middle of the frame - right in front.
  Rect underfoot({double left = 0.35}) =>
      box(left: left, top: 0.35, width: 0.3, height: 0.6);

  /// Something small and high up - down the street.
  Rect faraway({double left = 0.45}) =>
      box(left: left, top: 0.30, width: 0.07, height: 0.09);

  late ObstacleInterpreter interpreter;
  final t0 = DateTime(2024, 1, 1, 12);

  setUp(() => interpreter = ObstacleInterpreter());

  group('proximity', () {
    test('a tall narrow shape close by is not mistaken for something far', () {
      // A person two metres away: barely any width, most of the height.
      final person = box(left: 0.4, top: 0.1, width: 0.18, height: 0.85);

      expect(ObstacleInterpreter.proximityOf(person),
          greaterThanOrEqualTo(ObstacleInterpreter.nearThreshold),
          reason: 'height counts as much as width - this is the case the '
              'old width-only proxy got wrong');
    });

    test('something small and high in the frame reads as far away', () {
      expect(ObstacleInterpreter.proximityOf(faraway()),
          lessThan(ObstacleInterpreter.hazardThreshold));
    });

    test('the same size lower in the frame reads as nearer', () {
      final high = box(left: 0.4, top: 0.05, width: 0.25, height: 0.25);
      final low = box(left: 0.4, top: 0.70, width: 0.25, height: 0.25);

      expect(ObstacleInterpreter.proximityOf(low),
          greaterThan(ObstacleInterpreter.proximityOf(high)),
          reason: 'an object whose base is near the bottom of the frame is '
              'near your feet');
    });
  });

  group('what gets announced', () {
    test('distant clutter is left unmentioned', () {
      final reading = interpreter.interpret(
        [detect('chair', faraway()), detect('bench', faraway(left: 0.2))],
        now: t0,
      );

      expect(reading.detections, isEmpty);
      expect(reading.description, ObstacleVocabulary.pathClear);
    });

    test('something right in front is announced', () {
      final reading =
          interpreter.interpret([detect('chair', underfoot())], now: t0);

      expect(reading.detections, hasLength(1));
      expect(reading.description, contains('chair'));
      expect(reading.description, contains('directly ahead'));
    });

    test('a vehicle is announced from further away than furniture', () {
      // Same box for both - only the class differs.
      final middling = box(left: 0.4, top: 0.4, width: 0.2, height: 0.22);

      final car = ObstacleInterpreter()
          .interpret([detect('car', middling)], now: t0);
      final chair = ObstacleInterpreter()
          .interpret([detect('chair', middling)], now: t0);

      expect(car.detections, hasLength(1),
          reason: 'hearing about a car early costs little; late costs a lot');
      expect(chair.detections, isEmpty);
    });

    test('things that cannot obstruct anyone are never mentioned', () {
      final reading = interpreter.interpret(
        [detect('cell phone', underfoot()), detect('banana', underfoot())],
        now: t0,
      );

      expect(reading.detections, isEmpty);
    });
  });

  group('approaching traffic', () {
    /// Two frames [gap] apart, with the box growing from [base] by [growth].
    ///
    /// Sizes are chosen so the object stays *below* the plain hazard
    /// threshold throughout - otherwise it would be announced on size alone
    /// and these would not be testing the approach path at all.
    ObstacleReading approach(
      String className, {
      double base = 0.05,
      required double growth,
      Duration gap = const Duration(milliseconds: 300),
    }) {
      interpreter.interpret([
        detect(className, box(left: 0.4, top: 0.4, width: base, height: base)),
      ], now: t0);

      return interpreter.interpret([
        detect(
          className,
          box(left: 0.4, top: 0.4, width: base + growth, height: base + growth),
        ),
      ], now: t0.add(gap));
    }

    test('a car closing fast is announced while still small', () {
      final reading = approach('car', growth: 0.08);

      expect(reading.detections, hasLength(1),
          reason: 'a vehicle closing at speed has to be called before it is '
              'big enough to count as near on size alone');
      expect(reading.detections.single.isApproaching, isTrue);
      expect(reading.detections.single.proximity,
          lessThan(ObstacleInterpreter.hazardThreshold),
          reason: 'it is still too far to qualify any other way');
      expect(reading.description, contains('approaching'));
    });

    test('a parked car at the same distance stays quiet', () {
      final reading = approach('car', growth: 0.0);

      expect(reading.detections, isEmpty,
          reason: 'not everything far away is worth saying - only the ones '
              'getting closer');
    });

    test('a slowly growing box is not treated as closing', () {
      final reading = approach('car', growth: 0.01);

      expect(reading.detections, isEmpty,
          reason: 'drifting slightly larger is not the same as bearing down '
              'on you');
    });

    test('only hazards get the wider approaching radius', () {
      // A chair cannot come at you; if it is growing, you are walking at it,
      // and it will cross the normal near threshold soon enough.
      final reading = approach('chair', growth: 0.08);

      expect(reading.detections, isEmpty);
    });

    test('approach beats a static obstacle in the phrasing', () {
      // A chair directly underfoot, and a car closing from the left.
      interpreter.interpret([
        detect('car', box(left: 0.05, top: 0.4, width: 0.10, height: 0.10)),
      ], now: t0);

      final reading = interpreter.interpret([
        detect('car', box(left: 0.05, top: 0.4, width: 0.45, height: 0.45)),
        detect('chair', underfoot()),
      ], now: t0.add(const Duration(seconds: 1)));

      expect(reading.description, contains('approaching'));
      expect(reading.description.toLowerCase(), contains('car'));
    });

    test('a first sighting is never already approaching', () {
      final reading = interpreter.interpret(
        [detect('car', underfoot())],
        now: t0,
      );

      expect(reading.detections.single.isApproaching, isFalse,
          reason: 'there is nothing to compare a first frame against');
    });

    test('reset() drops motion history across a camera restart', () {
      interpreter.interpret([
        detect('car', box(left: 0.4, top: 0.4, width: 0.10, height: 0.10)),
      ], now: t0);

      interpreter.reset();

      final reading = interpreter.interpret([
        detect('car', box(left: 0.4, top: 0.4, width: 0.45, height: 0.45)),
      ], now: t0.add(const Duration(seconds: 1)));

      expect(reading.detections.single.isApproaching, isFalse,
          reason: 'a box from before the gap says nothing about motion '
              'after it');
    });

    test('a stale track is not compared against', () {
      interpreter.interpret([
        detect('car', box(left: 0.4, top: 0.4, width: 0.10, height: 0.10)),
      ], now: t0);

      // Well past the track lifetime.
      final reading = interpreter.interpret([
        detect('car', box(left: 0.4, top: 0.4, width: 0.45, height: 0.45)),
      ], now: t0.add(const Duration(seconds: 30)));

      expect(reading.detections.single.isApproaching, isFalse);
    });
  });

  group('phrasing', () {
    test('a blockage straight ahead outranks a hazard to the side', () {
      final reading = interpreter.interpret([
        detect('car', box(left: 0.0, top: 0.4, width: 0.3, height: 0.35)),
        detect('person', underfoot()),
      ], now: t0);

      expect(reading.description, startsWith('Watch out'));
      expect(reading.description, contains('person'));
    });

    test('a hazard to the side is named with its side', () {
      final reading = interpreter.interpret([
        detect('car', box(left: 0.7, top: 0.4, width: 0.3, height: 0.35)),
      ], now: t0);

      expect(reading.description, contains('right'));
    });

    test('several of the same thing are counted, not repeated', () {
      final reading = interpreter.interpret([
        detect('chair', box(left: 0.02, top: 0.45, width: 0.28, height: 0.45)),
        detect('chair', box(left: 0.04, top: 0.50, width: 0.26, height: 0.44)),
      ], now: t0);

      expect(reading.description, contains('2 chairs'));
    });

    test('nothing near reads as path clear', () {
      expect(ObstacleInterpreter.describe(const []),
          ObstacleVocabulary.pathClear);
    });
  });

  group('proximity alert', () {
    test('something large dead ahead raises the alert', () {
      final reading = interpreter.interpret(
        [detect('person', box(left: 0.3, top: 0.2, width: 0.45, height: 0.75))],
        now: t0,
      );

      expect(reading.dangerousProximity, isTrue);
    });

    test('the same thing off to one side does not', () {
      final reading = interpreter.interpret(
        [detect('person', box(left: 0.0, top: 0.2, width: 0.2, height: 0.75))],
        now: t0,
      );

      expect(reading.dangerousProximity, isFalse);
    });
  });
}
