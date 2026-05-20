# 🔧 Correction du Timeout Gradle

## 🚨 Problème Rencontré

```
Read timed out
Could not download gradle-8.3.1.jar
Could not download builder-8.3.1.jar
BUILD FAILED in 26m 44s
```

## 🔍 Cause

Le téléchargement des dépendances Gradle depuis les serveurs Google prend trop de temps et dépasse le timeout par défaut (généralement 30 secondes).

Cela arrive souvent avec :
- ❌ Connexion internet lente
- ❌ Connexion instable
- ❌ Distance géographique des serveurs Google
- ❌ Première compilation (téléchargement de ~500 MB)

## ✅ Solution Appliquée

### 1. Augmentation des timeouts dans `gradle.properties`

Ajout des propriétés suivantes dans `cotis_app/android/gradle.properties` :

```properties
# Augmenter les timeouts pour connexions lentes (10 minutes)
systemProp.http.connectionTimeout=600000
systemProp.http.socketTimeout=600000
systemProp.https.connectionTimeout=600000
systemProp.https.socketTimeout=600000

# Activer le cache Gradle pour accélérer les builds suivants
org.gradle.caching=true
org.gradle.parallel=true
```

**Explication :**
- `connectionTimeout` : Temps max pour établir la connexion (10 min)
- `socketTimeout` : Temps max pour lire les données (10 min)
- `org.gradle.caching=true` : Active le cache local
- `org.gradle.parallel=true` : Téléchargements parallèles

### 2. Timeouts configurés

| Timeout    | Avant | Après         |
| ---------- | ----- | ------------- |
| Connection | 30s   | 600s (10 min) |
| Socket     | 30s   | 600s (10 min) |

## 🚀 Commandes à Exécuter

### Étape 1 : Nettoyer le cache Gradle (optionnel)
```bash
cd cotis_app
flutter clean
```

### Étape 2 : Relancer le build
```bash
flutter build apk --debug
```

**Note :** Le premier build peut prendre **15-30 minutes** selon votre connexion, car Gradle doit télécharger :
- Gradle wrapper (~100 MB)
- Android Gradle Plugin (~150 MB)
- Dépendances du projet (~200 MB)
- Dépendances des plugins (~50 MB)

### Étape 3 : Si le timeout persiste encore

Si même avec 10 minutes de timeout ça échoue, essayez :

```bash
# Option 1 : Build avec plus de logs pour voir la progression
flutter build apk --debug --verbose

# Option 2 : Utiliser flutter run (plus tolérant aux timeouts)
flutter run
```

## 📊 Taille des téléchargements (première fois)

| Composant             | Taille approximative |
| --------------------- | -------------------- |
| Gradle wrapper        | ~100 MB              |
| Android Gradle Plugin | ~150 MB              |
| Dépendances Flutter   | ~200 MB              |
| Dépendances plugins   | ~50 MB               |
| **TOTAL**             | **~500 MB**          |

## 💡 Conseils

### Pour accélérer les builds futurs :

1. **Ne jamais supprimer** le dossier `.gradle` dans votre home directory
   - Windows : `C:\Users\<username>\.gradle\`
   - Les dépendances y sont cachées

2. **Utiliser le cache Gradle** (déjà activé dans la solution)

3. **Connexion stable** : Éviter de lancer le build sur une connexion mobile 3G/4G

4. **Builds suivants** : Une fois les dépendances téléchargées, les builds prendront 2-5 minutes seulement

### Si vous avez une connexion très lente :

**Option alternative** : Utiliser `flutter run` au lieu de `flutter build apk`
```bash
flutter run
```

`flutter run` est plus tolérant aux timeouts et peut reprendre le téléchargement en cas d'échec.

## 🎯 Résultat Attendu

Après cette correction, le build devrait :
- ✅ Télécharger toutes les dépendances (peut prendre 15-30 min la première fois)
- ✅ Compiler l'application
- ✅ Générer l'APK dans `build/app/outputs/flutter-apk/app-debug.apk`

## 📝 Fichiers Modifiés

- ✅ `cotis_app/android/gradle.properties` - Timeouts augmentés + cache activé

## 🔄 Prochaines Étapes

1. Relancer le build : `flutter build apk --debug`
2. Patienter (15-30 min pour le premier build)
3. Une fois terminé, installer l'APK : `flutter install`
4. Ou lancer directement : `flutter run`

---

**Note importante** : Les builds suivants seront **beaucoup plus rapides** (2-5 minutes) car les dépendances seront déjà en cache local.

---

*Document créé le 4 mai 2026*
*Pour le projet Kased-App*
