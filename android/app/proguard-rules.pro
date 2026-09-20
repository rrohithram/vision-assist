# ML Kit text recognition ships one artifact per script. This app bundles only
# the Latin recognizer, but the Flutter plugin references all of them, so R8
# sees the others as missing classes. They are genuinely absent and never
# reached at runtime, so silence them rather than pulling in the extra models.
#
# If Devanagari OCR is added later (the app already ships a Hindi locale), add
#   implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
# and drop the matching -dontwarn line.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep the ML Kit entry points the plugin reflects over.
-keep class com.google.mlkit.vision.text.** { *; }

# The YOLO detector loads models and classes reflectively through LiteRT.
-keep class com.ultralytics.yolo.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**

# Flutter plugins that register via reflection.
-keep class io.flutter.plugins.** { *; }

# The background fall-detection service starts a second FlutterEngine and
# looks its Dart entry point up by callback handle, so none of this is
# reachable statically.
-keep class id.flutter.flutter_background_service.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.view.FlutterCallbackInformation { *; }

# Crashlytics needs line numbers and source files to symbolicate a report,
# and both are stripped by default.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Flutter deferred components (Play Core is not used by this app)
-dontwarn com.google.android.play.core.**
