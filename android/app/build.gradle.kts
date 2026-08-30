plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.atari.atari"
    compileSdk = flutter.compileSdkVersion
    // Pinned to the NDK actually installed on this machine, not
    // flutter.ndkVersion's default (28.2.13676358) — the SDK's automatic
    // installer (sdkmanager.bat) crashes outright trying to fetch that
    // exact version on this machine (see research/device-results), so
    // Gradle must be told to use what's already present instead of
    // auto-provisioning. No native/JNI code is wired into this Flutter app
    // yet (the native/model llama.cpp harness lives outside it, see
    // native/model/README.md) — this NDK is only here because bundling
    // Flutter's own engine libraries requires one to be configured at all.
    ndkVersion = "30.0.16138531"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.atari.atari"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // arm64 only. `+=` would *add* to the default ABI set rather
            // than replace it, and the 32-bit build then fails outright:
            // GGML_CPU_ARM_ARCH below is an arm64 baseline, which
            // collides with the compatibility shims ggml compiles when
            // __aarch64__ is undefined. Clearing first is what makes
            // this a restriction instead of an addition.
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }

        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DANDROID_STL=c++_shared",
                    "-DCMAKE_BUILD_TYPE=Release",
                )
                // llama.cpp is heavy; release flags here apply to the
                // native library regardless of the Flutter build mode,
                // because a debug-optimised SLM is unusably slow.
                cppFlags += "-O3"
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("../../native/llama/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.10.0")
    // PP-OCRv5 detection + recognition run through here. The AAR ships
    // the native runtime for every ABI, which is why no NDK/JNI code of
    // our own is needed to get real OCR working.
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.20.0")
    // Renders the floating capture bubble's cat animation. Native, not
    // the Flutter `lottie` package — the bubble is a raw WindowManager
    // overlay view (CaptureOverlayService) that lives outside the
    // Flutter engine entirely.
    implementation("com.airbnb.android:lottie:6.6.0")
}
