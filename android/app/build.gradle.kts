import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

dependencies {
    // Required by flutter_local_notifications (java.time etc. on minSdk < 26)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase BoM (Manages versions automatically)
    implementation(platform("com.google.firebase:firebase-bom:34.9.0"))

    // Firebase Messaging (For Push Notification)
    implementation("com.google.firebase:firebase-messaging")
}

android {
    namespace = "co.micampus.app"
    // Google Play target API requirement: Android 16 (API 36). Explicitly pin
    // (Flutter 3.32.x defaults compileSdk/targetSdk to 35 via flutter.*Version).
    compileSdk = 36
    // NDK r28+ builds native libs with 16 KB ELF alignment (Google Play requirement for apps targeting Android 15+).
    // Install via SDK Manager → SDK Tools → NDK if Gradle reports a missing revision.
    ndkVersion = "28.0.13004108"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Must match package_name in google-services.json for FCM
        applicationId = "co.micampus.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Avoid Metaspace OOM in lintVitalAnalyzeRelease (e.g. webview_flutter_android).
    // Does not affect Play Store review; only skips AGP's release lint pass.
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}
