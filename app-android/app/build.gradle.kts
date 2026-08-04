plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.algoritmico.passepartout"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.algoritmico.passepartout"
        minSdk = 24
        targetSdk = 36
        versionCode = 4117
        versionName = "3.9.5"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        ndk {
            //noinspection ChromeOsAbiSupport
            abiFilters += listOf("arm64-v8a")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    buildFeatures {
        compose = true
    }
    ndkVersion = "29.0.13846066"
    externalNativeBuild {
        cmake {
            version = "4.1.2"
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }
    sourceSets {
        getByName("main") {
            kotlin.directories += "../../partout/cross/android"
        }
    }
    buildToolsVersion = "36.0.0"
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.runtime.android)
    implementation(libs.androidx.activity.ktx)
    implementation(libs.androidx.ui.tooling.preview.android)
    implementation(libs.androidx.material3.android)
    implementation(libs.androidx.material.icons.core)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.datastore.preferences.core)
    implementation(libs.kotlinx.serialization.json)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    debugImplementation(libs.androidx.ui.tooling)
}
kotlin {
    jvmToolchain(21)
}
