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

// NOTE: compileSdk for library modules (Flutter plugins) is forced to 36 by the
// CI workflow patch (see .github/workflows/build-release.yml), which edits the
// plugin's own build.gradle so its compileSdkVersion line cannot override it.
// An afterEvaluate/projectsEvaluated override here is NOT reliable: plugin build
// files run after plugin application, and AGP has already finalized the DSL by
// the time the whole graph is evaluated.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
