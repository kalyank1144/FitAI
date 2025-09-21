plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services")
}

android {
    namespace = "com.codesnesthorizon.FitAi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.codesnesthorizon.FitAi"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += listOf("env")
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationId = "com.codesnesthorizon.FitAi"
            resValue("string", "app_name", "FitAI Dev")
            resValue("string", "google_maps_api_key", "AIza...dev")
            manifestPlaceholders["authRedirectScheme"] = "fitai-dev"
        }
        create("stg") {
            dimension = "env"
            applicationId = "com.codesnesthorizon.FitAi"
            resValue("string", "app_name", "FitAI Staging")
            resValue("string", "google_maps_api_key", "AIza...stg")
            manifestPlaceholders["authRedirectScheme"] = "fitai-stg"
        }
        create("prod") {
            dimension = "env"
            applicationId = "com.codesnesthorizon.FitAi"
            resValue("string", "app_name", "FitAI")
            resValue("string", "google_maps_api_key", "AIza...prod")
            manifestPlaceholders["authRedirectScheme"] = "fitai"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".debug"
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
