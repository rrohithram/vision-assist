import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Maps key comes from local.properties (gitignored) or the environment, so it
// never lands in a committed file. Empty is tolerated: the rest of the app
// works, only the map view degrades.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY")
    ?: System.getenv("MAPS_API_KEY")
    ?: ""

// Upload keystore, read from android/key.properties (gitignored). Absent on
// most machines - CI and anyone just running the app locally - so release
// falls back to the debug key rather than failing the build. See the README
// for how to generate one.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKeystore: Boolean = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.gabn.navigator"
    compileSdk = flutter.compileSdkVersion

    // Highest NDK required by any plugin (ultralytics_yolo needs 28.2).
    // NDK releases are backward compatible, so the highest wins.
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Permanent once the first build reaches Play - it cannot be changed
        // afterwards without shipping a different app.
        applicationId = "com.gabn.navigator"
        minSdk = 24  // Required for TFLite
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (hasUploadKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Still builds and installs; Play will reject it. The build
                // log line below is the only warning you get.
                project.logger.warn(
                    "WARNING: no android/key.properties - signing the release " +
                        "build with the debug key. It cannot be uploaded to Play."
                )
                signingConfigs.getByName("debug")
            }

            // Minification stays off deliberately: this app loads models and
            // plugin classes reflectively (LiteRT, ML Kit, the background
            // service engine), and a release-only R8 crash in the SOS path is
            // worse than a larger APK. proguard-rules.pro is kept current so
            // it can be switched on once there is a device to test it on.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    // Don't compress TFLite model files - the detector memory-maps them.
    androidResources {
        noCompress += listOf("tflite")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // camera_android_camerax compiles against CallbackToFutureAdapter through
    // camera-core, but that class is not on the compile classpath under
    // AGP 8.13, so javac cannot resolve its type annotations. Declaring it
    // here puts it back.
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
}

flutter {
    source = "../.."
}
