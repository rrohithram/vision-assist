import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import 'obstacle_vocabulary.dart';

/// One box straight off the detector, normalised to the 0..1 frame.
///
/// Deliberately not the plugin's own result type: everything below is pure
/// geometry and phrasing, and keeping it free of `YOLOResult` is what makes
/// it testable without a model or a camera.
class RawDetection {
  final String className;
  final double confidence;
  final Rect box;

  const RawDetection({
    required this.className,
    required this.confidence,
    required this.box,
  });
}

/// A single detected object, described in terms that matter for walking:
/// what it is, which way it lies, and how close it is.
class DetectionResult {
  final String label;
  final double confidence;

  /// "left", "center" or "right".
  final String position;

  /// Close enough to matter for the next few steps.
  final bool isClose;

  /// Width of the object as a fraction of the frame. Kept for callers that
  /// still reason about raw size; [proximity] is the better signal.
  final double relativeWidth;

  /// 0..1 estimate of how near this is, from apparent size and how low it
  /// sits in the frame. See [ObstacleInterpreter.proximityOf].
  final double proximity;

  /// Growing fast enough between frames to be closing on the user.
  final bool isApproaching;

  /// How much this object matters when walking. See [ObstacleVocabulary].
  final ObstaclePriority priority;

  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.position,
    required this.isClose,
    required this.relativeWidth,
    this.proximity = 0,
    this.isApproaching = false,
    this.priority = ObstaclePriority.background,
  });

  String getDescription() {
    final distance = isClose ? 'close' : 'ahead';
    return '$label $distance on your $position';
  }
}

/// What the current frame amounts to.
class ObstacleReading {
  final List<DetectionResult> detections;
  final String description;

  /// Something large is directly ahead - drives the torch strobe.
  final bool dangerousProximity;

  const ObstacleReading({
    required this.detections,
    required this.description,
    required this.dangerousProximity,
  });
}

class _Track {
  double proximity;
  DateTime seenAt;
  _Track(this.proximity, this.seenAt);
}

/// Turns raw detector boxes into something worth saying out loud.
///
/// Two things make this more than a size filter:
///
/// **Distance is not width.** A person two metres away fills most of the
/// frame vertically and almost none of it horizontally, so the old
/// width-only proxy called them far away. Apparent size here is the larger
/// of the two dimensions, weighted by how low the object sits - something
/// whose base is near the bottom of the frame is near your feet, something
/// floating in the top third is down the street.
///
/// **Far things are ignored, except when they are coming at you.** Static
/// clutter below [nearThreshold] is dropped so the app stops narrating the
/// whole street. Vehicles get a wider radius, and anything whose apparent
/// size is growing quickly between frames is announced no matter how small
/// it currently looks - which is the only way a car closing at speed gets
/// mentioned before it arrives.
class ObstacleInterpreter {
  /// A static obstacle must look at least this near to be worth saying.
  static const double nearThreshold = 0.42;

  /// Hazards - vehicles, animals - are announced from further out, because
  /// the cost of hearing about a car early is much lower than hearing about
  /// it late.
  static const double hazardThreshold = 0.26;

  /// Floor for an approaching hazard. Below this the box is a handful of
  /// pixels and its growth is noise.
  static const double approachFloor = 0.10;

  /// Proximity units per second above which something counts as closing.
  /// Roughly: a box that doubles in apparent size within a second.
  static const double approachRate = 0.22;

  /// Tracks older than this are dropped rather than matched against.
  static const Duration trackTtl = Duration(seconds: 3);

  final Map<String, _Track> _tracks = {};

  /// Apparent nearness, 0..1.
  ///
  /// Size dominates; the vertical position of the object's base breaks the
  /// tie between "small because it is far" and "small because it is small".
  @visibleForTesting
  static double proximityOf(Rect box) {
    final size = math.max(box.width.abs(), box.height.abs()).clamp(0.0, 1.0);
    final groundedness = box.bottom.clamp(0.0, 1.0);
    return (0.72 * size + 0.28 * groundedness).clamp(0.0, 1.0);
  }

  @visibleForTesting
  static String positionOf(Rect box) {
    final centerX = box.center.dx.clamp(0.0, 1.0);
    if (centerX < 0.35) return 'left';
    if (centerX > 0.65) return 'right';
    return 'center';
  }

  /// Forgets motion history. Called when the camera restarts, so a box from
  /// before the gap is not compared against one after it.
  void reset() => _tracks.clear();

  ObstacleReading interpret(List<RawDetection> raw, {required DateTime now}) {
    _pruneTracks(now);

    final kept = <DetectionResult>[];
    var dangerousProximity = false;

    for (final detection in raw) {
      final priority = ObstacleVocabulary.priorityFor(detection.className);
      if (priority == ObstaclePriority.ignored) continue;

      final box = detection.box;
      final proximity = proximityOf(box);
      final position = positionOf(box);
      final label = ObstacleVocabulary.speakableLabel(detection.className);

      final approaching = _updateTrack(
        key: '$label|$position',
        proximity: proximity,
        now: now,
      );

      if (!_worthAnnouncing(
        priority: priority,
        proximity: proximity,
        approaching: approaching,
      )) {
        continue;
      }

      if (proximity > 0.62 && position == 'center') dangerousProximity = true;

      kept.add(DetectionResult(
        label: label,
        confidence: detection.confidence,
        position: position,
        isClose: proximity >= nearThreshold,
        relativeWidth: box.width.abs().clamp(0.0, 1.0),
        proximity: proximity,
        isApproaching: approaching,
        priority: priority,
      ));
    }

    return ObstacleReading(
      detections: kept,
      description: describe(kept),
      dangerousProximity: dangerousProximity,
    );
  }

  static bool _worthAnnouncing({
    required ObstaclePriority priority,
    required double proximity,
    required bool approaching,
  }) {
    if (priority == ObstaclePriority.hazard) {
      // A vehicle closing on you matters while it is still far away.
      if (approaching && proximity >= approachFloor) return true;
      return proximity >= hazardThreshold;
    }
    return proximity >= nearThreshold;
  }

  /// Returns whether this thing is closing, and records its size for the
  /// next frame to compare against.
  bool _updateTrack({
    required String key,
    required double proximity,
    required DateTime now,
  }) {
    final previous = _tracks[key];
    _tracks[key] = _Track(proximity, now);

    if (previous == null) return false;

    final elapsed = now.difference(previous.seenAt).inMilliseconds / 1000.0;
    if (elapsed <= 0) return false;

    final rate = (proximity - previous.proximity) / elapsed;
    return rate >= approachRate;
  }

  void _pruneTracks(DateTime now) {
    _tracks.removeWhere((_, track) => now.difference(track.seenAt) > trackTtl);
  }

  /// Turns detections into one spoken sentence.
  ///
  /// Ordered by what a walking user needs first: something closing on them,
  /// then anything blocking the path directly ahead, then hazards to the
  /// side, then a summary of what else is near.
  @visibleForTesting
  static String describe(List<DetectionResult> detections) {
    if (detections.isEmpty) return ObstacleVocabulary.pathClear;

    // 1. Anything coming at you, hazards first.
    final approaching = detections.where((d) => d.isApproaching).toList()
      ..sort((a, b) {
        if (a.priority != b.priority) {
          return a.priority == ObstaclePriority.hazard ? -1 : 1;
        }
        return b.proximity.compareTo(a.proximity);
      });

    if (approaching.isNotEmpty) {
      final nearest = approaching.first;
      return nearest.position == 'center'
          ? '${_capitalize(nearest.label)} approaching straight ahead'
          : '${_capitalize(nearest.label)} approaching on your '
              '${nearest.position}';
    }

    // 2. Immediate blockage straight ahead.
    final blocking = detections
        .where((d) => d.position == 'center' && d.isClose)
        .toList()
      ..sort((a, b) => b.proximity.compareTo(a.proximity));

    if (blocking.isNotEmpty) {
      return 'Watch out, ${blocking.first.label} directly ahead';
    }

    // 3. Hazards worth calling out wherever they are - a vehicle to the side
    //    matters more than a chair straight ahead.
    final hazards = detections
        .where((d) => d.priority == ObstaclePriority.hazard)
        .toList()
      ..sort((a, b) => b.proximity.compareTo(a.proximity));

    if (hazards.isNotEmpty) {
      final nearest = hazards.first;
      return '${_capitalize(nearest.label)} on your ${nearest.position}';
    }

    // 4. Otherwise summarise what is near.
    final counts = <String, int>{};
    for (final d in detections) {
      counts['${d.label}|${d.position}'] =
          (counts['${d.label}|${d.position}'] ?? 0) + 1;
    }

    final parts = <String>[];
    counts.forEach((key, count) {
      final split = key.split('|');
      final label = split[0];
      final position = split[1];
      parts.add(count == 1
          ? 'a $label on your $position'
          : '$count ${ObstacleVocabulary.pluralize(label)} on your $position');
    });

    if (parts.isEmpty) return ObstacleVocabulary.pathClear;
    return 'I see ${parts.join(', ')}';
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}
