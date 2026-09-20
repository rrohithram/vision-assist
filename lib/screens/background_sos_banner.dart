import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/background_monitor_service.dart';

/// Full-screen route shown when the background monitor (see
/// [BackgroundMonitorService]) detects a fall while the app was not in the
/// foreground. Tapping anywhere - matching the in-app SOS cancel zone -
/// tells the background isolate's countdown to stand down.
///
/// This does not reuse [SosOverlay]/the in-app cancel zone: those read the
/// foreground isolate's own SosService, which is a different instance from
/// the one actually running this countdown in the background isolate.
class BackgroundSosBanner extends StatelessWidget {
  const BackgroundSosBanner({super.key});

  void _cancel(BuildContext context) {
    BackgroundMonitorService.cancel();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => _cancel(context),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: Colors.red[900],
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 96),
                    const SizedBox(height: 24),
                    Text(
                      l10n.backgroundSosBannerTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.backgroundSosBannerBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 72,
                      child: ElevatedButton(
                        onPressed: () => _cancel(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[900],
                        ),
                        child: Text(
                          l10n.backgroundSosCancelButton,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
