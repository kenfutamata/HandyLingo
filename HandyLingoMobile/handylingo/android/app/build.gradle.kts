plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.handylingo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // Fix: Use double quotes and a simple string to avoid deprecation warnings
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.handylingo"
        // Fix: Set explicitly to 26 for TFLite compatibility
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Fix: Correct Kotlin DSL syntax for noCompress
    aaptOptions {
        noCompress.add("tflite")
        noCompress.add("lite")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
