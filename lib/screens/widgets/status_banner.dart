import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'home_control_bar.dart' show ControlPalette;

/// Top banner: current status, the latest scene description, and whether the
/// microphone is open.
///
/// Everything here is also spoken. The visual form serves low-vision users and
/// sighted helpers, so it follows the text-size and contrast settings.
///
/// The whole banner is a semantic live region: it is the one part of the
/// screen that changes on its own, and without this a screen-reader user
/// would have to keep swiping back to it to find out that anything had.
class StatusBanner extends StatelessWidget {
  final String statusText;
  final String sceneDescription;
  final bool isListening;
  final double textSize;
  final double contrast;

  const StatusBanner({
    super.key,
    required this.statusText,
    required this.sceneDescription,
    required this.isListening,
    required this.textSize,
    required this.contrast,
  });

  /// Above this, the palette switches to the high-contrast variant.
  static const double _highContrastThreshold = 1.2;

  bool get _highContrast => contrast > _highContrastThreshold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      liveRegion: true,
      label: _spokenSummary(l10n),
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ControlPalette.surface.withValues(
            alpha: 0.86 + (contrast - 1.0).clamp(0.0, 0.14),
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _highContrast
                ? Colors.yellow.withValues(alpha: 0.6)
                : Colors.white24,
            width: _highContrast ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusText,
              style: TextStyle(
                color: _highContrast ? Colors.yellow : Colors.white,
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sceneDescription.isNotEmpty) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 60),
                child: SingleChildScrollView(
                  child: Text(
                    sceneDescription,
                    style: TextStyle(
                      color: _highContrast ? Colors.white : Colors.white70,
                      fontSize: textSize * 0.8,
                      height: 1.3,
                      fontWeight:
                          _highContrast ? FontWeight.w500 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            if (isListening) ...[
              const SizedBox(height: 8),
              _ListeningPill(label: l10n.listeningIndicator),
            ],
          ],
        ),
      ),
    );
  }

  /// One sentence for the screen reader, instead of three separate nodes it
  /// would have to be swiped through one at a time.
  String _spokenSummary(AppLocalizations l10n) {
    final parts = <String>[statusText];
    if (sceneDescription.isNotEmpty && sceneDescription != statusText) {
      parts.add(sceneDescription);
    }
    if (isListening) parts.add(l10n.listeningIndicator);
    return parts.join('. ');
  }
}

class _ListeningPill extends StatelessWidget {
  final String label;

  const _ListeningPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: ControlPalette.voice.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ControlPalette.voice, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, color: ControlPalette.voice, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: ControlPalette.voice,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
