// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.play.publisher) apply false
}

project(":partout") {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            ndkVersion = "30.0.16138531"
            externalNativeBuild.cmake.version = "4.1.2"
            defaultConfig.externalNativeBuild.cmake.arguments +=
                "-DCMAKE_PROJECT_PartoutAndroid_INCLUDE_BEFORE=${rootProject.file("cmake/partout-options.cmake").absolutePath}"
        }
    }
}
