import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

// Load the keystore properties from the local.properties file
val keystorePropertiesFile = rootProject.file("local.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.caloriewheel.app"
    compileSdk = 35

    signingConfigs {
        create("release") {
            keyAlias = "my-key-alias"
            keyPassword = keystoreProperties.getProperty("keyPassword", "YOUR_KEY_ALIAS_PASSWORD")
            storeFile = file("../my-release-key.keystore")
            storePassword = keystoreProperties.getProperty("storePassword", "YOUR_KEYSTORE_PASSWORD")
        }
    }

    defaultConfig {
        applicationId = "com.esacu.caloriewheel"
        minSdk = 23
        targetSdk = 35
        versionCode = 5
        versionName = "1.1.1"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("androidx.preference:preference-ktx:1.2.1")
}
