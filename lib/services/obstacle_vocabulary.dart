/// How much a detected class matters to someone walking.
enum ObstaclePriority {
  /// Can cause injury: vehicles, bicycles, animals that move unpredictably.
  hazard,

  /// Solid things you can walk into.
  obstacle,

  /// Worth mentioning when describing a scene, harmless underfoot.
  background,

  /// Never announced. Things that cannot obstruct a pedestrian.
  ignored,
}

/// Maps YOLO26's COCO class names onto walking-relevant meaning.
///
/// This is the payoff from moving off ML Kit's stock detector: that model only
/// emitted five coarse categories ("Home good", "Fashion good", "Food",
/// "Place", "Plant"), so the app could never actually name what was in the way.
/// COCO's 80 classes include the things that matter on a pavement.
class ObstacleVocabulary {
  const ObstacleVocabulary._();

  static const String pathClear = 'Path clear';

  /// Moving or injurious. Announced wherever they appear, not just ahead.
  static const Set<String> _hazards = {
    'car',
    'motorcycle',
    'bus',
    'truck',
    'train',
    'bicycle',
    'boat',
    'airplane',
    'dog',
    'horse',
    'cow',
    'sheep',
    'bear',
    'elephant',
    'zebra',
    'giraffe',
  };

  /// Solid, static, walk-into-able.
  static const Set<String> _obstacles = {
    'person',
    'chair',
    'couch',
    'bench',
    'dining table',
    'bed',
    'toilet',
    'tv',
    'refrigerator',
    'oven',
    'microwave',
    'sink',
    'potted plant',
    'suitcase',
    'backpack',
    'fire hydrant',
    'stop sign',
    'parking meter',
    'traffic light',
    'umbrella',
    'skateboard',
    'surfboard',
    'snowboard',
    'skis',
    'sports ball',
    'cat',
    'bird',
  };

  /// Small enough that announcing them would be noise underfoot.
  static const Set<String> _ignored = {
    'tie',
    'fork',
    'knife',
    'spoon',
    'bowl',
    'cup',
    'banana',
    'apple',
    'sandwich',
    'orange',
    'broccoli',
    'carrot',
    'hot dog',
    'pizza',
    'donut',
    'cake',
    'book',
    'clock',
    'vase',
    'scissors',
    'teddy bear',
    'hair drier',
    'toothbrush',
    'remote',
    'keyboard',
    'mouse',
    'cell phone',
    'toaster',
  };

  /// Names that are clearer when spoken aloud than the raw COCO label.
  static const Map<String, String> _spokenNames = {
    'dining table': 'table',
    'potted plant': 'plant',
    'tv': 'screen',
    'couch': 'sofa',
    'motorcycle': 'motorbike',
    'fire hydrant': 'hydrant',
    'sports ball': 'ball',
  };

  /// Words whose plural is not formed by adding "s".
  static const Map<String, String> _irregularPlurals = {
    'person': 'people',
    'bus': 'buses',
    'sheep': 'sheep',
    'skis': 'skis',
    'bench': 'benches',
  };

  static ObstaclePriority priorityFor(String className) {
    final name = className.toLowerCase().trim();
    if (_hazards.contains(name)) return ObstaclePriority.hazard;
    if (_obstacles.contains(name)) return ObstaclePriority.obstacle;
    if (_ignored.contains(name)) return ObstaclePriority.ignored;
    return ObstaclePriority.background;
  }

  /// The word to say for a detected class.
  static String speakableLabel(String className) {
    final name = className.toLowerCase().trim();
    return _spokenNames[name] ?? name;
  }

  static String pluralize(String label) {
    final name = label.toLowerCase().trim();
    final irregular = _irregularPlurals[name];
    if (irregular != null) return irregular;
    if (name.endsWith('s') || name.endsWith('x') || name.endsWith('ch')) {
      return '${name}es';
    }
    return '${name}s';
  }
}
