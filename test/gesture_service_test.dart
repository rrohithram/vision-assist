import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/gesture_service.dart';

/// Regression tests for the volume-button gestures.
///
/// These are one of only two routes a fully blind user has into the app
/// without a screen reader, so a pattern that cannot fire is not a cosmetic
/// bug. The triple press in particular is the documented way to reach voice
/// commands, and it used to be unreachable: the double-press callback fired
/// the instant the second press landed and reset the counter, so the third
/// press began a fresh count and the `>= 3` branch was dead code. Every
/// attempt at a triple press took a photo instead.
void main() {
  late GestureService gestures;
  late List<String> fired;

  setUp(() {
    gestures = GestureService();
    fired = [];
    gestures.onVolumePress = () => fired.add('press');
    gestures.onVolumeDoublePress = () => fired.add('double');
    gestures.onVolumeTriplePress = () => fired.add('triple');
  });

  tearDown(() {
    gestures.onVolumePress = null;
    gestures.onVolumeDoublePress = null;
    gestures.onVolumeTriplePress = null;
  });

  /// Presses [count] times in quick succession, then waits out the window.
  void press(FakeAsync async, int count, {Duration? gap}) {
    for (var i = 0; i < count; i++) {
      gestures.handleVolumePressForTest();
      if (i < count - 1) {
        async.elapse(gap ?? const Duration(milliseconds: 120));
      }
    }
    async.elapse(const Duration(seconds: 1));
  }

  test('three presses reach voice commands, not the camera', () {
    fakeAsync((async) {
      press(async, 3);

      expect(fired.where((f) => f == 'triple'), hasLength(1));
      expect(fired, isNot(contains('double')),
          reason: 'a triple press must not also fire the photo gesture');
    });
  });

  test('two presses take a photo', () {
    fakeAsync((async) {
      press(async, 2);

      expect(fired.where((f) => f == 'double'), hasLength(1));
      expect(fired, isNot(contains('triple')));
    });
  });

  test('a single press fires no multi-press gesture', () {
    fakeAsync((async) {
      press(async, 1);

      expect(fired, ['press'], reason: 'only the immediate callback');
    });
  });

  test('every press reports immediately, before the pattern resolves', () {
    fakeAsync((async) {
      gestures.handleVolumePressForTest();

      // Not a single tick elapsed: cancelling an emergency cannot wait for a
      // double/triple press to be ruled out.
      expect(fired, ['press']);

      async.elapse(const Duration(seconds: 1));
    });
  });

  test('a fourth press still reaches voice commands', () {
    fakeAsync((async) {
      press(async, 4);

      expect(fired.where((f) => f == 'triple'), hasLength(1),
          reason: 'an over-eager press must not silently do nothing');
      expect(fired, isNot(contains('double')));
    });
  });

  test('presses spread out past the window count separately', () {
    fakeAsync((async) {
      gestures.handleVolumePressForTest();
      async.elapse(const Duration(seconds: 2));
      gestures.handleVolumePressForTest();
      async.elapse(const Duration(seconds: 2));

      expect(fired, ['press', 'press'],
          reason: 'two deliberate single presses are not a double press');
    });
  });

  test('the count resets, so a second triple press still works', () {
    fakeAsync((async) {
      press(async, 3);
      fired.clear();

      press(async, 3);

      expect(fired.where((f) => f == 'triple'), hasLength(1));
    });
  });
}
