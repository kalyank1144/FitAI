plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fitai.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.fitai.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += listOf("env")
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationId = "com.fitai.app.dev"
            resValue("string", "app_name", "FitAI Dev")
            resValue("string", "google_maps_api_key", "AIza...dev")
            manifestPlaceholders["authRedirectScheme"] = "fitai-dev"
        }
        create("stg") {
            dimension = "env"
            applicationId = "com.fitai.app.stg"
            resValue("string", "app_name", "FitAI Staging")
            resValue("string", "google_maps_api_key", "AIza...stg")
            manifestPlaceholders["authRedirectScheme"] = "fitai-stg"
        }
        create("prod") {
            dimension = "env"
            applicationId = "com.fitai.app"
            resValue("string", "app_name", "FitAI")
            resValue("string", "google_maps_api_key", "AIza...prod")
            manifestPlaceholders["authRedirectScheme"] = "fitai"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".debug"
        }
    }
}

flutter {
    source = "../.."
}
