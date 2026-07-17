buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
        classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.3")
    }
}

fun Project.afterEvaluateOrNow(action: Project.() -> Unit) {
    if (state.executed) {
        action()
    } else {
        afterEvaluate { action() }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Forcer CMake 3.30.5 pour TOUS les sous-projets (y compris :jni)
    // CMake 3.22.1 est incompatible avec NDK 28 (--no-rosegment, --no-undefined-version)
    afterEvaluateOrNow {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let { android ->
            try {
                android.externalNativeBuild.cmake.version = "3.30.5"
            } catch (_: Exception) {
                // Ignorer si le projet n'a pas de build CMake
            }
            // Forcer compileSdk >= 31 pour resoudre android:attr/lStar (isar_flutter_libs)
            val current = android.compileSdkVersion?.removePrefix("android-")?.toIntOrNull() ?: 0
            if (current < 31) {
                android.compileSdkVersion(31)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")

    // Forcer un namespace pour TOUS les com.android.library qui n'en ont pas.
    // Cela couvre isar_flutter_libs, sqflite_darwin, etc. (AGP 8+ exige un namespace).
    plugins.withId("com.android.library") {
        afterEvaluateOrNow {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { libExt ->
                if (libExt.namespace.isNullOrEmpty()) {
                    libExt.namespace = "io.flutter.plugins.${project.name}"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
