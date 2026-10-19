import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.washingtonclimaco.task_manager_appacademia"
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
        // ID da listagem existente na Play (Eu Atleta); pode ser sobrescrito por -PplayApplicationId.
        applicationId = providers.gradleProperty("playApplicationId")
            .getOrElse("task.manager.flutter.AppAcademia")
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            // R8: ofusca o codigo DEX e remove recursos nao usados (exigido pela Play para a metrica de ofuscacao).
            isMinifyEnabled  = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
