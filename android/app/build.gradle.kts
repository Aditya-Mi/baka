import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties for local dev; fall back to env vars in CI
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties()
if (keyPropsFile.exists()) keyPropsFile.inputStream().use { keyProps.load(it) }

android {
    namespace = "com.example.baka"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = keyProps.getProperty("storePassword") ?: System.getenv("STORE_PASSWORD") ?: ""
            keyAlias    = keyProps.getProperty("keyAlias")       ?: System.getenv("KEY_ALIAS")       ?: ""
            keyPassword = keyProps.getProperty("keyPassword")    ?: System.getenv("KEY_PASSWORD")    ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.example.baka"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
