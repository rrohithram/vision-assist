import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gabn2/l10n/app_localizations.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';
import 'screens/background_sos_banner.dart';
import 'screens/home_screen.dart';
import 'services/background_monitor_service.dart';

/// Lets the background-SOS listeners below push/pop a full-screen route from
/// outside any widget's BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.missingKeys.isNotEmpty) {
    debugPrint(
      'Missing API keys: ${AppConfig.missingKeys.join(', ')}. '
      'Pass them with --dart-define-from-file=dart_defines.json',
    );
  }

  await _initializeCrashReporting();

  try {
    await BackgroundMonitorService.configure();
    _wireBackgroundSosBanner();
  } catch (e) {
    debugPrint('Background monitor service unavailable: $e');
  }

  // Lock to portrait mode for consistent navigation experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI for immersive experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const AccessibilityNavApp());
}

/// Reports uncaught errors to Crashlytics.
///
/// Uses placeholder values (see firebase_options.dart) until someone runs
/// `flutterfire configure` against a real Firebase project. That call fails
/// with those placeholders, so this is wrapped rather than left to crash
/// app startup - the rest of the app works identically either way.
Future<void> _initializeCrashReporting() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint(
      'Crashlytics not configured (run `flutterfire configure` to enable '
      'crash reporting): $e',
    );
  }
}

/// Shows a full-screen cancel prompt whenever the background monitor
/// service (running in its own isolate - see BackgroundMonitorService)
/// starts or ends an automatic SOS countdown.
void _wireBackgroundSosBanner() {
  Route<void>? bannerRoute;

  FlutterBackgroundService().on('sosStarted').listen((_) {
    final nav = navigatorKey.currentState;
    if (nav == null || bannerRoute != null) return;
    bannerRoute = MaterialPageRoute<void>(
      builder: (_) => const BackgroundSosBanner(),
    );
    nav.push(bannerRoute!);
  });

  FlutterBackgroundService().on('sosEnded').listen((_) {
    final route = bannerRoute;
    bannerRoute = null;
    if (route == null) return;
    final nav = navigatorKey.currentState;
    if (nav?.canPop() ?? false) nav!.removeRoute(route);
  });
}

class AccessibilityNavApp extends StatelessWidget {
  const AccessibilityNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Accessibility Navigator',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
      ],
      theme: ThemeData(
        // High contrast dark theme for accessibility
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.orange,
          error: Colors.red,
          surface: Colors.grey[900]!,
        ),
        // Large touch targets
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Accessible text styles
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        // Enable Material 3
        useMaterial3: true,
      ),
      home: const HomeScreen(
        mapsApiKey: AppConfig.googleMapsApiKey,
        geminiApiKey: AppConfig.geminiApiKey,
        geminiModel: AppConfig.geminiModel,
      ),
    );
  }
}
