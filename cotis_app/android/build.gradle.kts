buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
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

    // Forcer un namespace si manquant (necessaire pour AGP 8+)
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            if (namespace == null) {
                namespace = project.group.toString().replace("-", ".") + "." + project.name
            }
        }
    }
}

// Patch isar_flutter_libs AndroidManifest.xml pour retirer l'attribut 'package'
// (AGP 8+ interdit "package" dans les manifests de bibliothèques)
val patchIsarManifest by tasks.registering {
    val pubCache = file(System.getenv("LOCALAPPDATA") + "/Pub/Cache/hosted/pub.dev")
    val manifests = fileTree(pubCache) { include("isar_flutter_libs*/android/src/main/AndroidManifest.xml") }
    inputs.files(manifests)
    outputs.upToDateWhen { true }
    doLast {
        manifests.forEach { f ->
            val text = f.readText()
            val patched = text.replace("""\spackage="[^"]*"""".toRegex(), "")
            if (text != patched) {
                f.writeText(patched)
                logger.lifecycle("isar_flutter_libs manifest patched: ${f.name}")
            }
        }
    }
}

subprojects {
    afterEvaluateOrNow {
        tasks.matching { it.name.startsWith("compile") }.configureEach {
            dependsOn(rootProject.tasks.named("patchIsarManifest"))
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
