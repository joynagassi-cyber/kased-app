// Fix for prebuilt plugins that lack namespace/compileSdk declarations.
// This runs before subproject evaluation to set defaults for plugins loaded from pub.dev.
gradle.beforeProject {
    if (plugins.hasPlugin("com.android.library")) {
        android {
            compileSdk = 34
        }
    }
}
