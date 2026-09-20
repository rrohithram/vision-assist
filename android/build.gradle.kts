allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// These two blocks must come before the `evaluationDependsOn(":app")` below.
// That call forces every subproject to evaluate, and afterEvaluate cannot be
// registered on an already-evaluated project.
subprojects {
    // Several pinned plugins (battery_plus, flutter_native_contact_picker, ...)
    // still declare compileSdk 33, while their own AndroidX dependencies
    // require 34+. Raising compileSdk only changes which APIs they compile
    // against - it does not touch their minSdk or runtime behaviour.
    project.afterEvaluate {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.BaseExtension) {
            val current = androidExtension.compileSdkVersion
                ?.removePrefix("android-")
                ?.toIntOrNull()
            if (current != null && current < 36) {
                androidExtension.compileSdkVersion(36)
            }
        }
    }

    // camera_android_camerax compiles against CallbackToFutureAdapter via
    // camera-core's API surface, but under AGP 8.13 that class is not on the
    // module's compile classpath, so javac fails resolving its type
    // annotations. Put it back for the module that needs it.
    if (project.name == "camera_android_camerax") {
        project.afterEvaluate {
            project.dependencies.add(
                "implementation",
                "androidx.concurrent:concurrent-futures:1.1.0",
            )
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
