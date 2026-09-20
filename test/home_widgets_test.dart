import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/l10n/app_localizations.dart';
import 'package:gabn2/screens/widgets/camera_preview_layer.dart';
import 'package:gabn2/screens/widgets/home_control_bar.dart';
import 'package:gabn2/screens/widgets/status_banner.dart';

/// Covers the presentational widgets lifted out of HomeScreen's build method.
///
/// None of this was reachable from a test before: it lived inside a 450-line
/// build method on a widget that starts the camera, GPS, sensors and speech
/// engines the moment it mounts.
void main() {
  Widget wrap(Widget child, {String languageCode = 'en'}) {
    return MaterialApp(
      locale: Locale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi')],
      home: Scaffold(body: child),
    );
  }

  group('CameraPreviewLayer', () {
    testWidgets('says the camera is starting when there is no feed yet',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const CameraPreviewLayer(
        controller: null,
        cameraEnabled: true,
        contrast: 1.0,
      )));

      expect(find.text('Initializing camera...'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('distinguishes a disabled camera from one still starting',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const CameraPreviewLayer(
        controller: null,
        cameraEnabled: false,
        contrast: 1.0,
      )));

      expect(find.text('Camera disabled'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    });

    testWidgets('placeholder is localized', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const CameraPreviewLayer(
          controller: null,
          cameraEnabled: true,
          contrast: 1.0,
        ),
        languageCode: 'hi',
      ));

      expect(find.text('Initializing camera...'), findsNothing);
    });
  });

  group('StatusBanner', () {
    testWidgets('shows status and scene description',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusBanner(
        statusText: 'Ready',
        sceneDescription: 'chair directly ahead',
        isListening: false,
        textSize: 18,
        contrast: 1.0,
      )));

      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('chair directly ahead'), findsOneWidget);
    });

    testWidgets('hides the scene line when there is nothing to say',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusBanner(
        statusText: 'Ready',
        sceneDescription: '',
        isListening: false,
        textSize: 18,
        contrast: 1.0,
      )));

      expect(find.text('Ready'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('surfaces an open microphone', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusBanner(
        statusText: 'Ready',
        sceneDescription: '',
        isListening: true,
        textSize: 18,
        contrast: 1.0,
      )));

      expect(find.text('Listening...'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('honours the high-contrast setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusBanner(
        statusText: 'Ready',
        sceneDescription: '',
        isListening: false,
        textSize: 18,
        contrast: 1.8,
      )));

      final text = tester.widget<Text>(find.text('Ready'));
      expect(text.style?.color, Colors.yellow,
          reason: 'high contrast must change the palette, not just the size');
    });

    testWidgets('scales text with the accessibility setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const StatusBanner(
        statusText: 'Ready',
        sceneDescription: '',
        isListening: false,
        textSize: 28,
        contrast: 1.0,
      )));

      final text = tester.widget<Text>(find.text('Ready'));
      expect(text.style?.fontSize, 28);
    });
  });

  group('HomeControlBar', () {
    late TextEditingController destination;

    setUp(() => destination = TextEditingController());
    tearDown(() => destination.dispose());

    Widget bar({
      bool isNavigating = false,
      bool isCameraEnabled = true,
      bool isAutoDescribing = true,
      bool isCapturingPhoto = false,
      bool isMockMode = false,
      Map<String, int>? taps,
      String languageCode = 'en',
    }) {
      void record(String name) => taps?[name] = (taps[name] ?? 0) + 1;

      return wrap(
        HomeControlBar(
          destinationController: destination,
          isNavigating: isNavigating,
          isCameraEnabled: isCameraEnabled,
          isAutoDescribing: isAutoDescribing,
          isCapturingPhoto: isCapturingPhoto,
          isMockMode: isMockMode,
          buttonSize: 1.0,
          contrast: 1.0,
          onToggleNavigation: () => record('navigation'),
          onSos: () => record('sos'),
          onToggleCamera: () => record('camera'),
          onToggleAutoDescribe: () => record('auto'),
          onNextStep: () => record('next'),
          onShowContacts: () => record('contacts'),
          onOpenMap: () => record('map'),
          onCapturePhoto: () => record('photo'),
          onReadText: () => record('readText'),
          onVoiceCommand: () => record('voice'),
          onOpenSettings: () => record('settings'),
          onOpenTutorial: () => record('tutorial'),
          onToggleMockMode: () => record('mock'),
        ),
        languageCode: languageCode,
      );
    }

    testWidgets('start becomes stop while navigating',
        (WidgetTester tester) async {
      await tester.pumpWidget(bar());
      expect(find.text('START'), findsOneWidget);
      expect(find.text('STOP'), findsNothing);

      await tester.pumpWidget(bar(isNavigating: true));
      expect(find.text('STOP'), findsOneWidget);
      expect(find.text('START'), findsNothing);
    });

    testWidgets('the destination field is hidden while navigating',
        (WidgetTester tester) async {
      await tester.pumpWidget(bar());
      expect(find.byType(TextField), findsOneWidget);

      await tester.pumpWidget(bar(isNavigating: true));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('next step only appears while navigating',
        (WidgetTester tester) async {
      await tester.pumpWidget(bar());
      expect(find.text('NEXT'), findsNothing);

      await tester.pumpWidget(bar(isNavigating: true));
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('SOS reports through its callback',
        (WidgetTester tester) async {
      final taps = <String, int>{};
      await tester.pumpWidget(bar(taps: taps));

      await tester.tap(find.text('SOS'));
      await tester.pump();

      expect(taps['sos'], 1);
    });

    testWidgets('camera and auto-describe labels follow their state',
        (WidgetTester tester) async {
      await tester.pumpWidget(bar());
      expect(find.text('CAM ON'), findsOneWidget);
      expect(find.text('AUTO ON'), findsOneWidget);

      await tester.pumpWidget(
          bar(isCameraEnabled: false, isAutoDescribing: false));
      expect(find.text('CAM OFF'), findsOneWidget);
      expect(find.text('AUTO OFF'), findsOneWidget);
    });

    testWidgets('the photo button is disabled mid-capture',
        (WidgetTester tester) async {
      final taps = <String, int>{};
      await tester.pumpWidget(bar(isCapturingPhoto: true, taps: taps));

      expect(find.text('CAPTURING...'), findsOneWidget);

      await tester.tap(find.text('CAPTURING...'), warnIfMissed: false);
      await tester.pump();

      expect(taps['photo'], isNull,
          reason: 'a second capture must not start while one is running');
    });

    testWidgets('each control reaches its own callback',
        (WidgetTester tester) async {
      final taps = <String, int>{};
      await tester.pumpWidget(bar(taps: taps));

      for (final label in ['CONTACTS', 'MAP', 'READ TEXT', 'VOICE',
        'SETTINGS', 'TUTORIAL']) {
        await tester.tap(find.text(label));
        await tester.pump();
      }

      expect(taps['contacts'], 1);
      expect(taps['map'], 1);
      expect(taps['readText'], 1);
      expect(taps['voice'], 1);
      expect(taps['settings'], 1);
      expect(taps['tutorial'], 1);
    });

    testWidgets('demo toggle reflects its state', (WidgetTester tester) async {
      await tester.pumpWidget(bar());
      expect(find.text('Demo OFF'), findsOneWidget);

      await tester.pumpWidget(bar(isMockMode: true));
      expect(find.text('Demo ON'), findsOneWidget);
    });

    testWidgets('renders in Hindi without English labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(bar(languageCode: 'hi'));

      expect(find.text('START'), findsNothing);
      expect(find.text('CONTACTS'), findsNothing);
      expect(find.text('शुरू'), findsOneWidget);
    });

    /// A blind user reaches this UI through TalkBack, so the semantic label
    /// is the whole interface. The visible labels are abbreviations chosen to
    /// fit the tile ("CAM ON"), which is not something anyone wants read to
    /// them - these tests pin the spoken form and the state that goes with it.
    group('screen reader', () {
      testWidgets('every control is a button with a label and a hint',
          (WidgetTester tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(bar());

        const expected = <String, String>{
          'Start navigation':
              'Starts spoken turn by turn directions to the destination above',
          'Emergency SOS':
              'Starts a ten second countdown, then texts and calls your '
                  'emergency contacts. Tap anywhere to cancel during the countdown',
          'Read text': 'Reads out any text the camera can see',
          'Voice command':
              'Opens voice commands. You can also triple tap the screen',
          'Describe a photo': 'Takes a photo and describes what is in it',
          'MAP': 'Opens the live map of your location',
        };

        expected.forEach((label, hint) {
          expect(
            tester.getSemantics(find.bySemanticsLabel(label)),
            containsSemantics(
              label: label,
              hint: hint,
              isButton: true,
              hasTapAction: true,
            ),
            reason: '"$label" must be reachable and self-explanatory',
          );
        });

        handle.dispose();
      });

      testWidgets('toggles announce whether they are on or off',
          (WidgetTester tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(bar());
        expect(
          tester.getSemantics(find.bySemanticsLabel('Obstacle detection, on')),
          containsSemantics(hasToggledState: true, isToggled: true),
        );

        await tester.pumpWidget(
            bar(isCameraEnabled: false, isAutoDescribing: false));
        expect(
          tester.getSemantics(find.bySemanticsLabel('Obstacle detection, off')),
          containsSemantics(hasToggledState: true, isToggled: false),
        );
        expect(
          find.bySemanticsLabel('Spoken descriptions, off'),
          findsOneWidget,
        );

        handle.dispose();
      });

      testWidgets('start and stop are distinct spoken labels',
          (WidgetTester tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(bar());
        expect(find.bySemanticsLabel('Start navigation'), findsOneWidget);
        expect(find.bySemanticsLabel('Stop navigation'), findsNothing);

        await tester.pumpWidget(bar(isNavigating: true));
        expect(find.bySemanticsLabel('Stop navigation'), findsOneWidget);
        expect(find.bySemanticsLabel('Next step'), findsOneWidget);

        handle.dispose();
      });

      testWidgets('a control that cannot be used says so',
          (WidgetTester tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(bar(isCapturingPhoto: true));

        expect(
          tester.getSemantics(find.bySemanticsLabel('CAPTURING...')),
          containsSemantics(isEnabled: false, hasEnabledState: true),
        );

        handle.dispose();
      });

      testWidgets('activating by semantic tap reaches the callback',
          (WidgetTester tester) async {
        final handle = tester.ensureSemantics();
        final taps = <String, int>{};
        await tester.pumpWidget(bar(taps: taps));

        // What TalkBack's double-tap actually does. The visual button is
        // hidden from the semantics tree, so this is the only path a screen
        // reader user has.
        tester.semantics.performAction(
          find.semantics.byLabel('Emergency SOS'),
          SemanticsAction.tap,
        );
        await tester.pump();

        expect(taps['sos'], 1);

        handle.dispose();
      });
    });
  });

  /// Colour is how a user with usable but poor sight identifies a control
  /// without reading it, so these are functional requirements, not taste.
  group('ControlPalette', () {
    /// WCAG relative luminance.
    double luminance(Color c) {
      double channel(double v) {
        final s = v;
        return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4) as double;
      }

      return 0.2126 * channel(c.r) +
          0.7152 * channel(c.g) +
          0.0722 * channel(c.b);
    }

    double contrastRatio(Color a, Color b) {
      final la = luminance(a);
      final lb = luminance(b);
      final lighter = la > lb ? la : lb;
      final darker = la > lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('every action colour clears 4.5:1 against the panel', () {
      for (final colour in ControlPalette.actionColours) {
        final ratio = contrastRatio(colour, ControlPalette.surface);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '${colour.toARGB32().toRadixString(16)} is only '
                '${ratio.toStringAsFixed(1)}:1 on the panel');
      }
    });

    test('action colours stay legible on the tinted tile background', () {
      // The tile fills with the colour at 20% over surfaceRaised, and the
      // label sits on top of that - so the wash must not eat the contrast.
      for (final colour in ControlPalette.tileColours) {
        final tinted = Color.alphaBlend(
          colour.withValues(alpha: 0.20),
          ControlPalette.surfaceRaised,
        );
        expect(contrastRatio(colour, tinted), greaterThanOrEqualTo(4.5),
            reason: 'the wash behind the label must stay dark enough');
      }
    });

    test('no two actions share a colour', () {
      final seen = <int>{};
      for (final colour in ControlPalette.actionColours) {
        expect(seen.add(colour.toARGB32()), isTrue,
            reason: 'two controls with the same colour defeat the point');
      }
    });

    test('action colours are far enough apart to tell apart', () {
      // Crude but effective: compare in RGB space and require a real gap.
      // Anything closer than this reads as "the same colour" at a glance to
      // someone who cannot focus on the icon.
      for (var i = 0; i < ControlPalette.actionColours.length; i++) {
        for (var j = i + 1; j < ControlPalette.actionColours.length; j++) {
          final a = ControlPalette.actionColours[i];
          final b = ControlPalette.actionColours[j];
          final distance = math.sqrt(
            math.pow((a.r - b.r) * 255, 2) +
                math.pow((a.g - b.g) * 255, 2) +
                math.pow((a.b - b.b) * 255, 2),
          );
          expect(distance, greaterThan(60),
              reason: 'colours $i and $j are only '
                  '${distance.toStringAsFixed(0)} apart');
        }
      }
    });

    test('red belongs to the emergency and nothing else', () {
      final others = ControlPalette.actionColours
          .where((c) => c != ControlPalette.danger);

      for (final colour in others) {
        final looksLikeAlarmRed =
            colour.r > 0.8 && colour.g < 0.45 && colour.b < 0.45;
        expect(looksLikeAlarmRed, isFalse,
            reason: 'only SOS may read as red');
      }
    });
  });

  group('HomeControlBar colour identity', () {
    late TextEditingController destination;
    setUp(() => destination = TextEditingController());
    tearDown(() => destination.dispose());

    Widget bar({bool isCameraEnabled = true}) => wrap(
          HomeControlBar(
            destinationController: destination,
            isNavigating: false,
            isCameraEnabled: isCameraEnabled,
            isAutoDescribing: true,
            isCapturingPhoto: false,
            isMockMode: false,
            buttonSize: 1.0,
            contrast: 1.0,
            onToggleNavigation: () {},
            onSos: () {},
            onToggleCamera: () {},
            onToggleAutoDescribe: () {},
            onNextStep: () {},
            onShowContacts: () {},
            onOpenMap: () {},
            onCapturePhoto: () {},
            onReadText: () {},
            onVoiceCommand: () {},
            onOpenSettings: () {},
            onOpenTutorial: () {},
            onToggleMockMode: () {},
          ),
        );

    testWidgets('a toggle keeps its hue when switched off',
        (WidgetTester tester) async {
      Color hueOf(WidgetTester t, String label) =>
          t.widget<Text>(find.text(label)).style!.color!;

      await tester.pumpWidget(bar());
      final on = hueOf(tester, 'CAM ON');

      await tester.pumpWidget(bar(isCameraEnabled: false));
      final off = hueOf(tester, 'CAM OFF');

      expect(off, on,
          reason: 'the colour identifies the control; the label and icon '
              'carry the state, so it stays findable when off');
    });

    testWidgets('different controls really do render different colours',
        (WidgetTester tester) async {
      await tester.pumpWidget(bar());

      final colours = <String, Color>{
        for (final label in ['CAM ON', 'CONTACTS', 'MAP', 'VOICE', 'SETTINGS'])
          label: tester.widget<Text>(find.text(label)).style!.color!,
      };

      expect(colours.values.toSet(), hasLength(colours.length),
          reason: 'adjacent tiles must not share a colour');
    });
  });

  group('StatusBanner screen reader', () {
    testWidgets('is a live region so changes are announced unprompted',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(const StatusBanner(
        statusText: 'Ready',
        sceneDescription: 'chair directly ahead',
        isListening: false,
        textSize: 18,
        contrast: 1.0,
      )));

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Ready'))),
        containsSemantics(
          label: 'Ready. chair directly ahead',
          isLiveRegion: true,
        ),
        reason: 'status and scene must arrive as one announcement, not two '
            'nodes the user has to go looking for',
      );

      handle.dispose();
    });

    testWidgets('an open microphone is part of the announcement',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(const StatusBanner(
        statusText: 'Ready',
        sceneDescription: '',
        isListening: true,
        textSize: 18,
        contrast: 1.0,
      )));

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Listening'))),
        containsSemantics(label: 'Ready. Listening...'),
      );

      handle.dispose();
    });
  });
}
