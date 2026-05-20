# 🔧 Correction du Problème de Build Gradle

## Problème Rencontré

```
Cannot resolve external dependency com.google.gms:google-services:4.4.0 
because no repositories are defined.
```

## Cause

Le bloc `buildscript` dans `android/build.gradle.kts` n'avait pas accès aux repositories Maven nécessaires pour télécharger les dépendances.

## Solution Appliquée

### Avant

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

### Après

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

## Fichier Modifié

- ✅ `cotis_app/android/build.gradle.kts`

## Commandes Exécutées

```bash
# 1. Nettoyer le build
flutter clean

# 2. Récupérer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run
```

## Résultat

✅ Le problème de build Gradle est résolu !

---

*Document créé le 3 mai 2026*
