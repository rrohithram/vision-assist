import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// A camera frame flattened into plain data so it can cross an isolate
/// boundary. [CameraImage] itself holds platform resources and cannot be sent.
class FramePayload {
  final int width;
  final int height;
  final Uint8List yPlane;
  final Uint8List uPlane;
  final Uint8List vPlane;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;

  /// Clockwise rotation, in degrees, needed to make the frame upright.
  final int rotationDegrees;

  /// Longest edge of the encoded output. 640 matches the YOLO input size, so
  /// anything larger is work the model immediately throws away.
  final int targetSize;

  /// JPEG quality. The detector only needs structure, not fidelity.
  final int jpegQuality;

  const FramePayload({
    required this.width,
    required this.height,
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.rotationDegrees,
    this.targetSize = 640,
    this.jpegQuality = 80,
  });

  /// Builds a payload from a YUV420 camera frame.
  ///
  /// Returns null for frame layouts we cannot interpret, rather than throwing
  /// into the camera's stream callback.
  static FramePayload? fromCameraImage(
    CameraImage image, {
    required int rotationDegrees,
    int targetSize = 640,
  }) {
    if (image.planes.length < 3) return null;

    return FramePayload(
      width: image.width,
      height: image.height,
      yPlane: image.planes[0].bytes,
      uPlane: image.planes[1].bytes,
      vPlane: image.planes[2].bytes,
      yRowStride: image.planes[0].bytesPerRow,
      uvRowStride: image.planes[1].bytesPerRow,
      uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
      rotationDegrees: rotationDegrees,
      targetSize: targetSize,
    );
  }
}

/// Converts a camera frame to JPEG bytes the detector can decode.
///
/// Runs on a background isolate via [compute]. The previous implementation did
/// its YUV conversion inline on the UI isolate, which meant roughly 1.4M byte
/// operations per processed frame competing with rendering.
Future<Uint8List?> encodeFrameForDetection(FramePayload payload) {
  return compute(_convertFrameToJpeg, payload);
}

/// Isolate entry point. Must be a top-level function.
Uint8List? _convertFrameToJpeg(FramePayload payload) {
  try {
    final rgb = _yuv420ToImage(payload);
    if (rgb == null) return null;

    var output = rgb;

    if (payload.rotationDegrees % 360 != 0) {
      output = img.copyRotate(output, angle: payload.rotationDegrees);
    }

    final longestEdge =
        output.width > output.height ? output.width : output.height;
    if (longestEdge > payload.targetSize) {
      output = output.width >= output.height
          ? img.copyResize(output, width: payload.targetSize)
          : img.copyResize(output, height: payload.targetSize);
    }

    return Uint8List.fromList(
      img.encodeJpg(output, quality: payload.jpegQuality),
    );
  } catch (e) {
    debugPrint('Frame conversion failed: $e');
    return null;
  }
}

/// YUV420 -> RGB.
///
/// Subsamples on the way in when the frame is well above the target size, so
/// the expensive per-pixel loop runs over roughly the pixels we actually keep
/// instead of the full sensor output.
img.Image? _yuv420ToImage(FramePayload payload) {
  final width = payload.width;
  final height = payload.height;
  if (width <= 0 || height <= 0) return null;

  final longestEdge = width > height ? width : height;
  final step = longestEdge > payload.targetSize * 2
      ? (longestEdge / payload.targetSize).floor().clamp(1, 4)
      : 1;

  final outWidth = width ~/ step;
  final outHeight = height ~/ step;
  if (outWidth <= 0 || outHeight <= 0) return null;

  final out = img.Image(width: outWidth, height: outHeight);

  final yBytes = payload.yPlane;
  final uBytes = payload.uPlane;
  final vBytes = payload.vPlane;

  for (var outY = 0; outY < outHeight; outY++) {
    final srcY = outY * step;
    final yRowStart = srcY * payload.yRowStride;
    final uvRowStart = (srcY >> 1) * payload.uvRowStride;

    for (var outX = 0; outX < outWidth; outX++) {
      final srcX = outX * step;

      final yIndex = yRowStart + srcX;
      final uvIndex = uvRowStart + (srcX >> 1) * payload.uvPixelStride;

      if (yIndex >= yBytes.length ||
          uvIndex >= uBytes.length ||
          uvIndex >= vBytes.length) {
        continue;
      }

      final yValue = yBytes[yIndex];
      final uValue = uBytes[uvIndex] - 128;
      final vValue = vBytes[uvIndex] - 128;

      final r = (yValue + 1.402 * vValue).round().clamp(0, 255);
      final g = (yValue - 0.344136 * uValue - 0.714136 * vValue)
          .round()
          .clamp(0, 255);
      final b = (yValue + 1.772 * uValue).round().clamp(0, 255);

      out.setPixelRgb(outX, outY, r, g, b);
    }
  }

  return out;
}
