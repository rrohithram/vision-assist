import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Smoke tests for app-level configuration.
///
/// HomeScreen itself is not pumped here: it initialises the camera, sensors,
/// GPS and speech engines on mount, none of which exist under `flutter test`.
/// Exercising it needs an integration test on a device.
void main() {
  testWidgets('localization delegates resolve English strings',
      (WidgetTester tester) async {
    late AppLocalizations strings;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
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

    expect(strings.appTitle, 'Accessibility Navigator');
    expect(strings.youHaveArrived, isNotEmpty);
  });

  testWidgets('Hindi locale resolves translated strings',
      (WidgetTester tester) async {
    late AppLocalizations strings;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('hi'),
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

    expect(strings.appTitle, isNot('Accessibility Navigator'));
    expect(strings.appTitle, isNotEmpty);
  });
}
