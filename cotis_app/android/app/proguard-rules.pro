# ════════════════════════════════════════════════════
# PROGUARD — kased_app
# Règles complètes pour tous les packages utilisés
# ════════════════════════════════════════════════════

# ─── Flutter Engine ──────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# ─── Kotlin ──────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep interface kotlin.** { *; }
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Lazy { *; }
-dontwarn kotlin.**

# ─── Coroutines ──────────────────────────────────────
-keepclassmembernames class kotlinx.** { volatile <fields>; }
-dontwarn kotlinx.**

# ─── Isar (base locale native) ───────────────────────
-keep class dev.isar.** { *; }
-keep class com.isar.** { *; }
-keepclassmembers class * { @dev.isar.annotations.* <fields>; }
-keepclassmembers class * extends dev.isar.** { *; }
-keep class ** implements dev.isar.isar_core.IsarCollection { *; }
-keepclassmembers class **.IsarImpl { *; }

# ─── Isar : modèles (CRITIQUE — sans ça Isar crash) ──
-keep class com.kasedapp.** { *; }
-keepclassmembers class com.kasedapp.** { *; }

# ─── Dio + OkHttp ────────────────────────────────────
-keep class io.ktor.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# ─── Flutter Secure Storage ──────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keepclassmembers class com.it_nomads.fluttersecurestorage.** { *; }

# ─── Google Sign-In ──────────────────────────────────
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ─── Flutter Local Notifications ─────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# ─── Image Picker ────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }

# ─── Share Plus ──────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }

# ─── Connectivity Plus ───────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ─── Path Provider ───────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ─── dio_retry_plus ──────────────────────────────────
-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.**

# ─── Attributs critiques (sérialisation, réflexion) ──
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile
-keepattributes LineNumberTable

# ─── Multidex ────────────────────────────────────────
-keep class androidx.multidex.** { *; }
