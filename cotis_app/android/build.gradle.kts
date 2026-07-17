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

    plugins.withId("com.android.library") {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { libExt ->
                // Set namespace if missing
                if (libExt.namespace.isNullOrEmpty()) {
                    libExt.namespace = "io.flutter.plugins.${this@subprojects.name}"
                }
                // Set compileSdk 31 if lower (fixes android:attr/lStar in isar_flutter_libs)
                val currentCompileSdk = libExt.compileSdkVersion?.toString()?.removePrefix("android-")?.toIntOrNull() ?: 0
                if (currentCompileSdk < 31) {
                    libExt.compileSdkVersion(31)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
