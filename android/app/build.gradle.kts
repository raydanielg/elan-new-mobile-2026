plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import org.gradle.api.GradleException

android {
    namespace = "com.elanledgers.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.elanledgers.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keyProperties = Properties()
    val keyPropertiesFile = rootProject.file("key.properties")
    if (keyPropertiesFile.exists()) {
        keyPropertiesFile.inputStream().use { keyProperties.load(it) }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keyProperties.getProperty("storeFile")
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = rootProject.file(storeFilePath)
            }
            storePassword = keyProperties.getProperty("storePassword")
                ?.takeIf { it.isNotBlank() }
                ?: System.getenv("KEYSTORE_PASSWORD")
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
                ?.takeIf { it.isNotBlank() }
                ?: System.getenv("KEY_PASSWORD")

            if (storeFile == null) {
                throw GradleException("Release signing is not configured: storeFile is missing. Set storeFile in android/key.properties")
            }
            if (storePassword.isNullOrBlank()) {
                throw GradleException(
                    "Release signing is not configured: storePassword is missing. " +
                        "Set storePassword in android/key.properties or set env var KEYSTORE_PASSWORD",
                )
            }
            if (keyAlias.isNullOrBlank()) {
                throw GradleException("Release signing is not configured: keyAlias is missing. Set keyAlias in android/key.properties")
            }
            if (keyPassword.isNullOrBlank()) {
                throw GradleException(
                    "Release signing is not configured: keyPassword is missing. " +
                        "Set keyPassword in android/key.properties or set env var KEY_PASSWORD",
                )
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
