# Detection model

The app detects obstacles with **YOLO26 nano** via the `ultralytics_yolo` plugin.

## How the model is loaded

`VisionService` tries two sources, in order:

1. `assets/models/yolo26n.tflite` — bundled in the APK. Preferred, because
   detection then works with no network at all.
2. `yolo26n` — the official Ultralytics model id. The plugin downloads it once
   and caches it in app storage.

If neither resolves, the app still runs: navigation, OCR, voice commands and
SOS are unaffected, and obstacle announcements are simply disabled.

## Bundling the model (recommended)

The model is not committed, to keep the repo small. To bundle it:

```bash
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('yolo26n.pt').export(format='litert', imgsz=640)"
```

Copy the resulting `.tflite` to `assets/models/yolo26n.tflite`, then rebuild.
Nothing else needs changing — `VisionService` picks it up automatically.

## Why not ML Kit

This previously used `google_mlkit_object_detection`. Its stock classifier only
emits five coarse categories — Home good, Fashion good, Food, Place, Plant — so
it could never name the things the app needs to announce ("chair", "car",
"person"). YOLO26n returns the 80 COCO classes, which `obstacle_vocabulary.dart`
maps onto hazard / obstacle / ignored.
