import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The app's colour vocabulary.
///
/// Colour here means **identity, not state**: each action keeps the same hue
/// for the life of the app, so someone with usable but poor sight can find
/// the photo button by its pink or the voice button by its lime without
/// reading anything. The hues are spread around the wheel deliberately -
/// "tells itself apart at a glance, out of focus" is the whole job, which is
/// the opposite of a tasteful matched palette.
///
/// State is never carried by colour alone. A toggle that is off keeps its
/// hue and changes its fill, its icon and its label instead, which is what
/// keeps this readable for the colour-blind (WCAG 1.4.1).
///
/// Every colour is checked against [surface] for a 4.5:1 contrast floor, and
/// against each other for distinctness, in `home_widgets_test.dart` - so a
/// later tweak cannot quietly make a control unreadable or ambiguous.
class ControlPalette {
  const ControlPalette._();

  /// Panel behind the controls. Opaque rather than translucent: text over a
  /// moving camera feed is unreadable at any contrast setting.
  static const Color surface = Color(0xFF12161A);
  static const Color surfaceRaised = Color(0xFF1C2228);

  // --- Action identities -------------------------------------------------

  /// Go. Also the next step of a route, which is the same idea.
  static const Color navigate = Color(0xFF3DDC84);

  /// Stops something that is running.
  static const Color halt = Color(0xFFFFA726);

  /// Emergency only. Nothing else in the UI may use this.
  static const Color danger = Color(0xFFFF453A);

  static const Color detection = Color(0xFF40C4FF); // obstacle camera
  static const Color describe = Color(0xFF69F0AE); // spoken descriptions
  static const Color contacts = Color(0xFFFFD54F);

  /// Warm rather than the obvious map-cyan: cyan sat too close to
  /// [detection] to be told apart by someone who cannot focus, which the
  /// distinctness test caught.
  static const Color map = Color(0xFFFF8A65);

  static const Color photo = Color(0xFFFF80AB);
  /// Lighter than a natural violet: the darker shade fell under 4.5:1 once
  /// its own wash sat behind the label.
  static const Color readText = Color(0xFFCBB2FF);

  /// Deliberately the loudest colour on the panel. For someone with light
  /// perception only, this is the button that reaches every other feature.
  static const Color voice = Color(0xFFC6FF00);

  static const Color settings = Color(0xFFB0BEC5);

  /// Non-action chrome: field icons, footer links. Not an identity, so it is
  /// excluded from the distinctness test below.
  static const Color chrome = Color(0xFF9AA5B1);

  static const Color onDark = Colors.white;

  /// A control that cannot be used right now. The one case where the hue is
  /// dropped, because "unavailable" must not read as any live action.
  static const Color disabled = Color(0xFF5F6A75);

  /// Every action colour, for the contrast and distinctness tests.
  static const List<Color> actionColours = [
    navigate,
    halt,
    danger,
    detection,
    describe,
    contacts,
    map,
    photo,
    readText,
    voice,
    settings,
  ];

  /// The subset drawn as a tinted [_ActionTile], where the label sits on a
  /// wash of its own colour. The primaries ([navigate], [halt], [danger])
  /// are solid-filled with black or white text instead, so they are held to
  /// a different contrast pairing.
  static const List<Color> tileColours = [
    detection,
    describe,
    contacts,
    map,
    photo,
    readText,
    voice,
    settings,
  ];
}

/// A secondary action: icon over label, in a tile big enough to hit without
/// looking.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Spoken by the screen reader in place of [label] when the visible text is
  /// an abbreviation ("CAM ON") that would not make sense read aloud.
  final String semanticLabel;

  /// What activating this does, spoken after the label.
  final String hint;

  final Color color;
  final VoidCallback? onPressed;
  final double buttonSize;

  /// Set for controls that flip between two states, so the screen reader can
  /// announce "on"/"off" rather than leaving the user to infer it.
  final bool? toggled;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.hint,
    required this.color,
    required this.onPressed,
    required this.buttonSize,
    this.toggled,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final effective = enabled ? color : ControlPalette.disabled;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      toggled: toggled,
      label: semanticLabel,
      hint: hint,
      onTap: onPressed,
      // The visual label is an abbreviation for sighted use; the semantics
      // above carry the spoken version, and two competing labels on one node
      // read as gibberish.
      excludeSemantics: true,
      child: SizedBox(
        height: 68 * buttonSize,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            // A filled wash rather than an outline: a thin border is the
            // first thing to disappear for someone with low acuity, so the
            // colour needs area behind it to be identifiable at all.
            backgroundColor: enabled
                ? Color.alphaBlend(
                    effective.withValues(alpha: toggled == false ? 0.07 : 0.20),
                    ControlPalette.surfaceRaised,
                  )
                : ControlPalette.surfaceRaised,
            side: BorderSide(
              color: toggled == false
                  ? effective.withValues(alpha: 0.5)
                  : effective,
              width: 2.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: effective, size: 26 * buttonSize),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: effective,
                    fontSize: 12 * buttonSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bottom control panel: destination entry plus every on-screen action.
///
/// Purely presentational - it owns no state and reports every interaction
/// through a callback.
///
/// Every control carries an explicit semantic label and hint. The visible
/// labels are abbreviations chosen to fit ("CAM ON", "AUTO OFF"); a screen
/// reader gets the spelled-out version and a description of what the control
/// actually does, which is the only thing a blind user has to go on.
class HomeControlBar extends StatelessWidget {
  final TextEditingController destinationController;

  final bool isNavigating;
  final bool isCameraEnabled;
  final bool isAutoDescribing;
  final bool isCapturingPhoto;
  final bool isMockMode;

  final double buttonSize;
  final double contrast;

  final VoidCallback onToggleNavigation;
  final VoidCallback onSos;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleAutoDescribe;
  final VoidCallback onNextStep;
  final VoidCallback onShowContacts;
  final VoidCallback onOpenMap;
  final VoidCallback onCapturePhoto;
  final VoidCallback onReadText;
  final VoidCallback onVoiceCommand;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenTutorial;
  final VoidCallback onToggleMockMode;

  const HomeControlBar({
    super.key,
    required this.destinationController,
    required this.isNavigating,
    required this.isCameraEnabled,
    required this.isAutoDescribing,
    required this.isCapturingPhoto,
    required this.isMockMode,
    required this.buttonSize,
    required this.contrast,
    required this.onToggleNavigation,
    required this.onSos,
    required this.onToggleCamera,
    required this.onToggleAutoDescribe,
    required this.onNextStep,
    required this.onShowContacts,
    required this.onOpenMap,
    required this.onCapturePhoto,
    required this.onReadText,
    required this.onVoiceCommand,
    required this.onOpenSettings,
    required this.onOpenTutorial,
    required this.onToggleMockMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: const BoxDecoration(
        color: ControlPalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNavigating) ...[
            _buildDestinationField(l10n),
            const SizedBox(height: 12),
          ],
          _buildPrimaryRow(l10n),
          const SizedBox(height: 10),
          if (isNavigating) ...[
            _buildNextStepRow(l10n),
            const SizedBox(height: 10),
          ],
          _buildToggleRow(l10n),
          const SizedBox(height: 8),
          _buildToolsGrid(l10n),
          const SizedBox(height: 4),
          _buildFooterRow(l10n),
        ],
      ),
    );
  }

  Widget _buildDestinationField(AppLocalizations l10n) {
    return Semantics(
      textField: true,
      label: l10n.destinationHint,
      hint: l10n.hintDestinationField,
      child: TextField(
        controller: destinationController,
        style: const TextStyle(color: ControlPalette.onDark, fontSize: 16),
        decoration: InputDecoration(
          hintText: l10n.destinationHint,
          hintStyle: const TextStyle(color: Color(0xFF8A939D)),
          filled: true,
          fillColor: ControlPalette.surfaceRaised,
          prefixIcon: const Icon(Icons.place_outlined,
              color: ControlPalette.chrome),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// Start/stop navigation and SOS. Deliberately the largest targets on the
  /// screen - they are the two a user needs to hit without looking.
  Widget _buildPrimaryRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Semantics(
            container: true,
            button: true,
            label: isNavigating ? l10n.semanticsStop : l10n.semanticsStart,
            hint: isNavigating ? l10n.hintStopNavigation : l10n.hintNavigate,
            onTap: onToggleNavigation,
            excludeSemantics: true,
            child: SizedBox(
              height: 84 * buttonSize,
              child: ElevatedButton.icon(
                onPressed: onToggleNavigation,
                icon: Icon(isNavigating ? Icons.stop_rounded : Icons.navigation,
                    size: 30 * buttonSize),
                label: Text(
                  isNavigating ? l10n.actionStop : l10n.actionStart,
                  style: TextStyle(
                      fontSize: 19 * buttonSize, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNavigating
                      ? ControlPalette.halt
                      : ControlPalette.navigate,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            container: true,
            button: true,
            label: l10n.semanticsSos,
            hint: l10n.hintSos,
            onTap: onSos,
            excludeSemantics: true,
            child: SizedBox(
              height: 84 * buttonSize,
              child: ElevatedButton(
                onPressed: onSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ControlPalette.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency_share, size: 26 * buttonSize),
                    const SizedBox(height: 2),
                    Text(
                      l10n.actionSos,
                      style: TextStyle(
                          fontSize: 17 * buttonSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Full width while navigating: advancing the route is the main thing the
  /// user does on this screen, and the destination field is hidden anyway.
  Widget _buildNextStepRow(AppLocalizations l10n) {
    return Semantics(
      container: true,
      button: true,
      label: l10n.semanticsNext,
      hint: l10n.hintNext,
      onTap: onNextStep,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: 64 * buttonSize,
        child: ElevatedButton.icon(
          onPressed: onNextStep,
          icon: Icon(Icons.arrow_forward, size: 26 * buttonSize),
          label: Text(
            l10n.actionNext,
            style: TextStyle(
                fontSize: 18 * buttonSize, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            // Same green as START: advancing the route is the same idea, and
            // a consistent hue is the point of the palette.
            backgroundColor: ControlPalette.navigate,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: isCameraEnabled ? Icons.videocam : Icons.videocam_off,
            label: isCameraEnabled ? l10n.actionCameraOn : l10n.actionCameraOff,
            semanticLabel: isCameraEnabled
                ? l10n.semanticsCameraOn
                : l10n.semanticsCameraOff,
            hint: l10n.hintCamera,
            color: ControlPalette.detection,
            toggled: isCameraEnabled,
            buttonSize: buttonSize,
            onPressed: onToggleCamera,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: isAutoDescribing ? Icons.record_voice_over : Icons.voice_over_off,
            label: isAutoDescribing ? l10n.actionAutoOn : l10n.actionAutoOff,
            semanticLabel: isAutoDescribing
                ? l10n.semanticsAutoDescribeOn
                : l10n.semanticsAutoDescribeOff,
            hint: l10n.hintAutoDescribe,
            color: ControlPalette.describe,
            toggled: isAutoDescribing,
            buttonSize: buttonSize,
            onPressed: onToggleAutoDescribe,
          ),
        ),
      ],
    );
  }

  /// Six secondary actions in two rows of three. Four across left each label
  /// about 80 logical pixels, which is why they were rendering at 10pt.
  Widget _buildToolsGrid(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.contacts,
                label: l10n.actionContacts,
                semanticLabel: l10n.actionContacts,
                hint: l10n.hintContacts,
                color: ControlPalette.contacts,
                buttonSize: buttonSize,
                onPressed: onShowContacts,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                icon: Icons.map,
                label: l10n.actionMap,
                semanticLabel: l10n.actionMap,
                hint: l10n.hintMap,
                color: ControlPalette.map,
                buttonSize: buttonSize,
                onPressed: onOpenMap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                icon: Icons.camera_alt,
                label:
                    isCapturingPhoto ? l10n.actionCapturing : l10n.actionPhoto,
                semanticLabel: isCapturingPhoto
                    ? l10n.actionCapturing
                    : l10n.semanticsPhoto,
                hint: l10n.hintPhoto,
                color: ControlPalette.photo,
                buttonSize: buttonSize,
                onPressed: isCapturingPhoto ? null : onCapturePhoto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.text_fields,
                label: l10n.actionReadText,
                semanticLabel: l10n.semanticsReadText,
                hint: l10n.hintReadText,
                color: ControlPalette.readText,
                buttonSize: buttonSize,
                onPressed: onReadText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                icon: Icons.mic,
                label: l10n.actionVoice,
                semanticLabel: l10n.semanticsVoice,
                hint: l10n.hintVoice,
                color: ControlPalette.voice,
                buttonSize: buttonSize,
                onPressed: onVoiceCommand,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                icon: Icons.settings,
                label: l10n.actionSettings,
                semanticLabel: l10n.actionSettings,
                hint: l10n.hintSettings,
                color: ControlPalette.settings,
                buttonSize: buttonSize,
                onPressed: onOpenSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterRow(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Semantics(
          container: true,
          button: true,
          label: l10n.actionTutorial,
          hint: l10n.hintTutorial,
          onTap: onOpenTutorial,
          excludeSemantics: true,
          child: TextButton.icon(
            onPressed: onOpenTutorial,
            icon: const Icon(Icons.school,
                color: ControlPalette.chrome, size: 20),
            label: Text(
              l10n.actionTutorial,
              style: const TextStyle(
                  color: ControlPalette.chrome,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Semantics(
          container: true,
          button: true,
          toggled: isMockMode,
          label: isMockMode ? l10n.demoModeOn : l10n.demoModeOff,
          hint: l10n.hintDemoMode,
          onTap: onToggleMockMode,
          excludeSemantics: true,
          child: TextButton.icon(
            onPressed: onToggleMockMode,
            icon: Icon(
              isMockMode ? Icons.check_box : Icons.check_box_outline_blank,
              color: isMockMode
                  ? ControlPalette.navigate
                  : ControlPalette.disabled,
              size: 20,
            ),
            label: Text(
              isMockMode ? l10n.demoModeOn : l10n.demoModeOff,
              style: TextStyle(
                  color: isMockMode
                      ? ControlPalette.navigate
                      : ControlPalette.disabled,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
