plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing from environment variables (used by CI; see
// docs/release/RELEASE_CHECKLIST.md). When ANDROID_KEYSTORE_PATH points to an
// existing file, release builds are signed with that stable upload key so
// users can upgrade in place — debug-key signing differs per build and forces
// an uninstall (wiping app data) on every upgrade. Falls back to debug signing
// for local `flutter run --release` and fork builds without secrets.
val envKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val releaseKeystoreFile = envKeystorePath?.let { file(it) }?.takeIf { it.exists() }

android {
    namespace = "com.museflow.museflow"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.museflow.museflow"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (releaseKeystoreFile != null) {
        signingConfigs {
            create("release") {
                storeFile = releaseKeystoreFile
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (releaseKeystoreFile != null) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
