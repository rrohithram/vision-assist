import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Full-bleed camera preview, or a labelled placeholder when there is no feed.
///
/// The contrast filter is a low-vision accommodation: [contrast] above 1.0
/// pushes the preview towards higher separation for users with some sight.
class CameraPreviewLayer extends StatelessWidget {
  final CameraController? controller;
  final bool cameraEnabled;
  final double contrast;

  const CameraPreviewLayer({
    super.key,
    required this.controller,
    required this.cameraEnabled,
    required this.contrast,
  });

  bool get _hasFeed =>
      cameraEnabled && controller != null && controller!.value.isInitialized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_hasFeed) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                cameraEnabled ? Icons.camera_alt : Icons.videocam_off,
                size: 80,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                cameraEnabled ? l10n.initializingCamera : l10n.cameraDisabled,
                style: const TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final preview = CameraPreview(controller!);

    // ColorFiltered forces an offscreen composite every frame. At the
    // default contrast the matrix is the identity anyway, so skip the layer
    // entirely rather than pay for it on every rebuild.
    if (contrast == 1.0) return preview;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_contrastMatrix(contrast)),
      child: preview,
    );
  }

  /// Scales each colour channel around mid-grey, leaving alpha untouched.
  static List<double> _contrastMatrix(double contrast) {
    final offset = (1 - contrast) * 0.5 * 255;
    return [
      contrast, 0, 0, 0, offset, //
      0, contrast, 0, 0, offset, //
      0, 0, contrast, 0, offset, //
      0, 0, 0, 1, 0, //
    ];
  }
}
