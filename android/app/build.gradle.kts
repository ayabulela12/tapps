plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.appmaniazar.tapp"
    compileSdk = 36
    ndkVersion = "27.0.12077973"  // Updated to match plugin requirements
    
    // Enable multidex support
    defaultConfig.multiDexEnabled = true

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.appmaniazar.tapp"
        minSdk = flutter.minSdkVersion  // Updated to meet Flutter's minimum requirement
        targetSdk = 34
        versionCode = 5
        versionName = "1.0.1"
        multiDexEnabled = true
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
