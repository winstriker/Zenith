import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "it.winstriker.zenith"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Needed by flutter_local_notifications' scheduled notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "it.winstriker.zenith"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavors can't be named like a build type, such as "debug".
    flavorDimensions += "app"
    productFlavors {
        create("dev") {
            dimension = "app"
            applicationId = "it.winstriker.zenithdebug"
            manifestPlaceholders["appName"] = "Zenith Debug"
        }
        create("prod") {
            dimension = "app"
            manifestPlaceholders["appName"] = "Zenith"
        }
    }

    // With --split-per-abi, also build the universal APK in the same run.
    splits {
        abi {
            isUniversalApk = true
        }
    }

    // Flutter doesn't run on x86, but plugins ship x86 libraries, which the
    // universal APK above would otherwise include.
    packaging {
        jniLibs {
            excludes += "lib/x86/**"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key until android/key.properties exists.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// --dart-define=DISABLE_GOOGLE_PLAY_SERVICES=true builds without Google Play
// Services (fully free build). Geolocator then falls back to Android's
// LocationManager. Flutter hands dart-defines to Gradle base64-encoded.
val disableGooglePlayServices = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.any { String(Base64.getDecoder().decode(it)) == "DISABLE_GOOGLE_PLAY_SERVICES=true" }
    ?: false

if (disableGooglePlayServices) {
    configurations.all { exclude(group = "com.google.android.gms") }
}
