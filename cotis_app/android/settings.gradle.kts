pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

// Set default compileSdk for ALL subprojects (including prebuilt pub.dev plugins)
// This fixes "resource android:attr/lStar not found" in isar_flutter_libs
gradle.beforeEvaluation {
    allprojects {
        try {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let { android ->
                val current = android.compileSdkVersion?.toString()?.removePrefix("android-")?.toIntOrNull() ?: 0
                if (current < 31) {
                    android.compileSdkVersion(31)
                }
            }
        } catch (_: Exception) {
            // Not an Android project
        }
    }
}

include(":app")
