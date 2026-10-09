plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.attendly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.attendly.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// On Windows, AGP's incremental jniLibs merge leaks a handle on the ABI folder it removes when the
// target ABI changes (e.g. running on a 64-bit phone, then a 32-bit tablet). The folder stays locked
// until the Gradle daemon exits and the build fails with AccessDeniedException. Never treating the
// outputs as up to date forces a full (non-incremental) merge, which avoids that path. The merge only
// copies libapp.so, so this is cheap.
tasks.named { it.startsWith("merge") && it.endsWith("JniLibFolders") }.configureEach {
    outputs.upToDateWhen { false }
}