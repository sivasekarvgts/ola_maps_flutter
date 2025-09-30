plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.olakrutrim.ola_maps_flutter_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.olakrutrim.ola_maps_flutter_example"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

dependencies {

    implementation(files("libs/OlaMapSdk-1.8.4.aar"))

//Maplibre
    implementation ("org.maplibre.gl:android-sdk:11.13.1")
    implementation ("org.maplibre.gl:android-plugin-annotation-v9:3.0.2")
    implementation ("org.maplibre.gl:android-plugin-markerview-v9:3.0.2")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")


//    // OlaMapSDK AAR file - use local copy in example app
//    implementation(files("libs/OlaMapSDK.aar"))
//
//    // Required dependencies for OlaMaps
//    implementation("org.maplibre.gl:android-sdk:10.2.0")
//    implementation("com.moengage:moe-android-sdk:12.6.01")
//    implementation("androidx.cardview:cardview:1.0.0")
//    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
