buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
        classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
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
}

// Skip Kotlin metadata version check for plugins compiled with newer Kotlin versions
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    kotlinOptions.freeCompilerArgs += "-Xskip-metadata-version-check"
}

// Force a recent compileSdk on every Android library module (Flutter plugins).
// Older plugins (e.g. isar_flutter_libs 3.1.0) link against a lower compileSdk
// but merge resources from SDK 35+ AARs (android:attr/lStar), which fails with
// "resource android:attr/lStar not found" unless compileSdk is at least 35.
//
// NOTE: use pluginManager.withPlugin (NOT afterEvaluate). afterEvaluate throws
// "Cannot run Project.afterEvaluate(Action) when the project is already evaluated"
// when combined with the evaluationDependsOn(":app") block above, because some
// subprojects are already evaluated by then. withPlugin fires when the plugin is
// applied (or immediately if it already is), so it is safe in both cases.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure(com.android.build.gradle.LibraryExtension::class.java) {
            compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
