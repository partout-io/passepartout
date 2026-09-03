import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.play.publisher)
}

val localPlayPublisherCredentials = rootProject.file("play-publisher-credentials.json")
val releaseSigning = Properties().apply {
    rootProject.file("signing.properties").takeIf { it.isFile }?.inputStream()?.use {
        load(it)
    }

    mapOf(
        "storeFile" to "ANDROID_KEYSTORE_PATH",
        "storePassword" to "ANDROID_KEYSTORE_PASSWORD",
        "keyAlias" to "ANDROID_KEY_ALIAS",
        "keyPassword" to "ANDROID_KEY_PASSWORD",
    ).forEach { (property, environment) ->
        providers.environmentVariable(environment).orNull
            ?.takeIf { it.isNotBlank() }
            ?.let { setProperty(property, it) }
    }
}

fun releaseSigningValue(name: String): String =
    releaseSigning.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: error("Missing Android release signing property: $name")

android {
    namespace = "com.algoritmico.passepartout"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.algoritmico.passepartout"
        minSdk = 24
        targetSdk = 36
        versionCode = 4147
        versionName = "3.11.2"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        ndk {
            //noinspection ChromeOsAbiSupport
            abiFilters += listOf("arm64-v8a")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    val releaseSigningConfig = if (releaseSigning.isEmpty) {
        null
    } else {
        signingConfigs.create("release") {
            storeFile = rootProject.file(releaseSigningValue("storeFile"))
            storePassword = releaseSigningValue("storePassword")
            keyAlias = releaseSigningValue("keyAlias")
            keyPassword = releaseSigningValue("keyPassword")
        }
    }
    buildTypes {
        release {
            signingConfig = releaseSigningConfig
            isMinifyEnabled = true
            isShrinkResources = true
            ndk {
                debugSymbolLevel = "FULL"
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    buildFeatures {
        compose = true
    }
    ndkVersion = "29.0.14206865"
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

play {
    defaultToAppBundles.set(true)

    // CI uses GPP's ANDROID_PUBLISHER_CREDENTIALS environment variable.
    if (!providers.environmentVariable("ANDROID_PUBLISHER_CREDENTIALS").isPresent &&
        localPlayPublisherCredentials.isFile
    ) {
        serviceAccountCredentials.set(localPlayPublisherCredentials)
    }
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
    jvmToolchain(17)
}
