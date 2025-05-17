plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin") 
    id("com.google.gms.google-services")  
}


android {
    namespace  = "com.example.doitmoney" // ← manifest 와 동일하게
    compileSdk = 35                   // ▲ 35

    defaultConfig {
        applicationId = "com.example.doitmoney"
        minSdk  = 23                  // ▲ 21 → 23  (another_telephony 때문)
        targetSdk = 35
        versionCode  = flutter.versionCode
        versionName  = flutter.versionName
    }

    compileOptions {
        sourceCompatibility          = JavaVersion.VERSION_17
        targetCompatibility          = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "17" }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

