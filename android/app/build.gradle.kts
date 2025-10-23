plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")       // pakai id resmi Kotlin Android
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ganti sesuai package kamu (harus sama dengan applicationId)
    namespace = "com.example.ocr_sederhana"

    // gunakan versi dari Flutter toolchain (template baru Flutter)
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.ocr_sederhana"

        // ML Kit butuh minSdk 21
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // aman-aman saja diaktifkan; untuk minSdk 21+ tidak perlu dependency multidex runtime
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // untuk awal, pakai debug keystore supaya `flutter run --release` jalan
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // konfigurasi tambahan jika perlu
        }
    }

    // AGP 8.x membutuhkan Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // hindari bentrok lisensi bawaan beberapa dependensi
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}
