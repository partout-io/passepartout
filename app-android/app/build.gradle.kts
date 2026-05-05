plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
    kotlin("plugin.serialization") version "1.9.0"
}

android {
    namespace = "com.algoritmico.passepartout"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.algoritmico.passepartout"
        minSdk = 28
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

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
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
            jniLibs.srcDirs("src/main/cpp/libs")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
        getByName("androidTest") {
            java.srcDirs("src/androidTest/kotlin")
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
    implementation(libs.androidx.activity.compose)
    implementation(libs.kotlinx.serialization.json)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    debugImplementation(libs.androidx.ui.tooling)
}
kotlin {
    jvmToolchain(21)
}
