import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "task.manager.flutter.AppAcademia"
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
        applicationId = "task.manager.flutter.AppAcademia"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
            }
            storeFile     = file(keystoreProperties.getProperty("storeFile") ?: System.getenv("ANDROID_KEYSTORE_PATH") ?: "keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: System.getenv("ANDROID_STORE_PASSWORD") ?: ""
            keyAlias      = keystoreProperties.getProperty("keyAlias") ?: System.getenv("ANDROID_KEY_ALIAS") ?: "upload"
            keyPassword   = keystoreProperties.getProperty("keyPassword") ?: System.getenv("ANDROID_KEY_PASSWORD") ?: ""
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig    = signingConfigs.getByName("release")
            isMinifyEnabled  = false
            isShrinkResources = false
        }
    }}

flutter {
    source = "../.."
}

dependencies {
    androidTestImplementation("tools.fastlane:screengrab:2.1.1")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test:rules:1.5.0")
}
