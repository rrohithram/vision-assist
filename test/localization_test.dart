import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/l10n/app_localizations.dart';
import 'package:gabn2/services/sos_service.dart';
import 'package:gabn2/services/voice_command_service.dart';

/// Guards the localization work.
///
/// The app ships a Hindi locale, so an English string that never made it into
/// the ARB files is a user-visible defect, not a style problem.
void main() {
  Future<AppLocalizations> load(WidgetTester tester, String languageCode) async {
    late AppLocalizations strings;
    await tester.pumpWidget(MaterialApp(
      locale: Locale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi')],
      home: Builder(builder: (context) {
        strings = AppLocalizations.of(context)!;
        return const SizedBox.shrink();
      }),
    ));
    return strings;
  }

  group('ARB coverage', () {
    test('every English key has a Hindi translation', () {
      Map<String, dynamic> read(String path) =>
          json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

      final en = read('lib/l10n/app_en.arb');
      final hi = read('lib/l10n/app_hi.arb');

      // '@'-prefixed entries are metadata, not translatable strings.
      final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
      final hiKeys = hi.keys.where((k) => !k.startsWith('@')).toSet();

      expect(enKeys.difference(hiKeys), isEmpty,
          reason: 'keys missing a Hindi translation');
      expect(hiKeys.difference(enKeys), isEmpty,
          reason: 'Hindi keys with no English source');
    });

    test('no Hindi value is left as its English source', () {
      final en = json.decode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      final hi = json.decode(File('lib/l10n/app_hi.arb').readAsStringSync())
          as Map<String, dynamic>;

      final untranslated = <String>[];
      for (final key in en.keys.where((k) => !k.startsWith('@'))) {
        final source = en[key];
        final target = hi[key];
        // Placeholder-only strings can legitimately match; real prose cannot.
        if (source is String && target is String && source == target &&
            source.replaceAll(RegExp(r'\{\w+\}'), '').trim().length > 3) {
          untranslated.add(key);
        }
      }
      expect(untranslated, isEmpty);
    });
  });

  group('spoken strings', () {
    testWidgets('SOS cancel instructions differ by locale',
        (WidgetTester tester) async {
      final en = await load(tester, 'en');
      final hi = await load(tester, 'hi');

      // The single most important sentence in the app: how to call off an
      // emergency. It must reach a Hindi user in Hindi.
      expect(en.sosSequenceActivated('10'), contains('10'));
      expect(hi.sosSequenceActivated('10'), contains('10'));
      expect(hi.sosSequenceActivated('10'),
          isNot(en.sosSequenceActivated('10')));
    });

    testWidgets('placeholders are substituted, not printed literally',
        (WidgetTester tester) async {
      final en = await load(tester, 'en');

      expect(en.navigatingTo('the park'), contains('the park'));
      expect(en.navigatingTo('the park'), isNot(contains('{name}')));
      expect(en.batteryLevelIs('80 percent'), contains('80 percent'));
      expect(en.obstacleWarning('chair ahead'), contains('chair ahead'));
    });
  });

  group('SosStrings injection', () {
    test('falls back to English before the UI injects anything', () {
      const fallback = SosStrings.fallback;

      expect(fallback.sequenceActivated('10'), contains('10'));
      expect(fallback.sequenceActivated('10'), contains('tap anywhere'));
      expect(fallback.sequenceCancelled, isNotEmpty);
      expect(fallback.spokenCallMessage, isNotEmpty);
    });

    testWidgets('accepts localized phrases from AppLocalizations',
        (WidgetTester tester) async {
      final hi = await load(tester, 'hi');

      final injected = SosStrings(
        sequenceActivated: hi.sosSequenceActivated,
        secondsRemaining: hi.sosSecondsRemaining,
        sequenceCancelled: hi.sosSequenceCancelled,
        spokenCallMessage: hi.sosSpokenCallMessage,
      );

      expect(injected.sequenceCancelled,
          isNot(SosStrings.fallback.sequenceCancelled));
      expect(injected.sequenceActivated('10'), contains('10'));
    });
  });

  group('singleton lifecycle', () {
    test('releasing the voice service leaves it usable', () async {
      final voice = VoiceCommandService();

      // HomeScreen tears its services down on every disposal, including each
      // hot restart. release() must not destroy the notifier: calling
      // ChangeNotifier.dispose() on a singleton is unrecoverable, and every
      // later notifyListeners() would throw for the rest of the process.
      await voice.release();

      expect(voice.isListening, isFalse);

      var notified = 0;
      void listener() => notified++;

      // Would throw "was used after being disposed" under the old dispose().
      expect(() => voice.addListener(listener), returnsNormally);
      voice.setLocale('hi');
      expect(voice.localeId, 'hi_IN');
      voice.removeListener(listener);
    });

    test('voice locale falls back to English for unknown languages', () {
      final voice = VoiceCommandService();
      voice.setLocale('xx');
      expect(voice.localeId, 'en_US');
      voice.setLocale('en');
      expect(voice.localeId, 'en_US');
    });
  });

  group('no hardcoded user-facing English left in screens', () {
    // A literal that never reached the ARB files is invisible until a Hindi
    // user meets it. This walks the screen sources rather than trusting that
    // every one was found by hand.
    test('Text() and speak() take no bare English literals', () {
      final offenders = <String>[];

      // Two shapes of user-facing copy: sentence case ("Save Location") and
      // the ALL-CAPS button labels this UI uses ("CANCEL"). Both start
      // uppercase and run 4+ characters, which keeps icon names and short
      // enum values out of the results.
      final literal = RegExp(
        r'''(?:Text|speak)\(\s*(?:const\s+)?['"]([A-Z][A-Za-z][^'"]{3,})['"]''',
      );

      for (final file in Directory('lib/screens').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;

        final source = file.readAsStringSync();
        for (final match in literal.allMatches(source)) {
          offenders.add('${file.uri.pathSegments.last}: "${match.group(1)}"');
        }
      }

      expect(offenders, isEmpty,
          reason: 'these strings never reach a Hindi user:\n'
              '${offenders.join('\n')}');
    });
  });
}
