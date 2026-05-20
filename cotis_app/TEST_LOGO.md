# 🧪 Guide de Test - Logo Kased-app

## Commandes Rapides

### 1. Nettoyer et Relancer

```bash
# Nettoyer le build
flutter clean

# Récupérer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### 2. Build APK Release

```bash
# Générer l'APK de production
flutter build apk --release

# L'APK sera dans :
# build/app/outputs/flutter-apk/app-release.apk
```

### 3. Vérifier les Diagnostics

```bash
# Analyser le code
flutter analyze

# Résultat attendu : No issues found!
```

---

## Checklist de Test

### Tests Visuels

#### Page Signup
- [ ] Le logo Kased s'affiche correctement
- [ ] Le logo a des coins arrondis
- [ ] Le logo a une ombre portée
- [ ] Le logo a la bonne taille (100x100 dp)
- [ ] Le logo est centré

#### Page Login
- [ ] Le logo Kased s'affiche correctement
- [ ] Le logo a des coins arrondis
- [ ] Le logo a une ombre portée
- [ ] Le logo a la bonne taille (100x100 dp)
- [ ] Le logo est centré

### Tests Techniques

- [ ] Aucune erreur de compilation
- [ ] Hot reload fonctionne
- [ ] Pas de lag lors du chargement
- [ ] L'application démarre sans erreur

### Tests sur Appareil

- [ ] Icône Kased visible sur l'écran d'accueil
- [ ] Icône Kased visible dans la liste des applications
- [ ] Logo s'affiche correctement sur différentes tailles d'écran
- [ ] Logo s'affiche correctement en mode portrait
- [ ] Logo s'affiche correctement en mode paysage

---

## Problèmes Courants

### Problème 1 : "Unable to load asset"

**Erreur :**
```
Unable to load asset: assets/images/kased_logo.png
```

**Solution :**
1. Vérifiez que le fichier existe : `assets/images/kased_logo.png`
2. Vérifiez que l'asset est déclaré dans `pubspec.yaml`
3. Exécutez `flutter clean` puis `flutter pub get`

### Problème 2 : "Logo ne s'affiche pas"

**Solution :**
1. Vérifiez que le fichier `kased_logo.png` existe
2. Vérifiez que le chemin est correct dans le code
3. Redémarrez l'application (hot restart : R)

### Problème 3 : "Icône d'application ne change pas"

**Solution :**
1. Désinstallez l'application de l'appareil
2. Réinstallez l'application
3. L'icône devrait maintenant être mise à jour

---

## Commandes de Débogage

### Vérifier les Assets

```bash
# Lister les assets dans le build
flutter build apk --debug
unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep kased_logo
```

### Vérifier les Icônes Android

```bash
# Lister les icônes générées
ls -la android/app/src/main/res/mipmap-*/ic_launcher.png
```

### Logs en Temps Réel

```bash
# Afficher les logs de l'application
flutter run --verbose
```

---

## Tests de Performance

### Mesurer le Temps de Chargement

```bash
# Lancer avec profiling
flutter run --profile

# Observer les métriques dans DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Vérifier la Taille de l'APK

```bash
# Build release
flutter build apk --release

# Vérifier la taille
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

---

## Captures d'Écran

### Prendre des Captures d'Écran

```bash
# Lancer l'application
flutter run

# Dans un autre terminal, prendre une capture
flutter screenshot --out=screenshot_signup.png
```

### Captures Recommandées

1. **Page Signup** : Logo + Bouton Google
2. **Page Login** : Logo + Badge "Bon retour !"
3. **Écran d'accueil** : Icône Kased dans la liste des apps

---

## Tests Automatisés (Optionnel)

### Test Widget pour le Logo

Créer `test/widget/logo_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotis_app/screens/signup_screen.dart';

void main() {
  testWidgets('Logo Kased s\'affiche sur la page Signup', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(),
      ),
    );

    // Vérifier que l'image du logo est présente
    expect(find.byType(Image), findsOneWidget);
    
    // Vérifier que le chemin de l'asset est correct
    final Image image = tester.widget(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/images/kased_logo.png');
  });
}
```

### Exécuter les Tests

```bash
flutter test test/widget/logo_test.dart
```

---

## Résumé des Commandes

```bash
# 1. Nettoyer
flutter clean

# 2. Récupérer les dépendances
flutter pub get

# 3. Analyser le code
flutter analyze

# 4. Lancer l'application
flutter run

# 5. Build APK release
flutter build apk --release
```

---

## Résultat Attendu

### Page Signup

```
┌─────────────────────────────────────────────┐
│                                             │
│         [Logo Kased 100x100]                │
│         • Fond bleu avec église             │
│         • Cercle doré                       │
│         • Pièces avec coche                 │
│         • Mains en soutien                  │
│         • Texte "KASED"                     │
│         • Slogan "GIVE • GROW • IMPACT"     │
│                                             │
│         Créer un compte                     │
│         Gérez les cotisations...            │
│                                             │
│    [🔵🟢🟡🔴] S'inscrire avec Google        │
│                                             │
└─────────────────────────────────────────────┘
```

### Page Login

```
┌─────────────────────────────────────────────┐
│                                             │
│         [Logo Kased 100x100]                │
│         (même design que Signup)            │
│                                             │
│         ✓ Bon retour !                      │
│                                             │
│         Se connecter                        │
│         Accédez à votre espace...           │
│                                             │
│    [🔵🟢🟡🔴] Continuer avec Google         │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Support

Si vous rencontrez des problèmes :

1. Vérifiez la checklist ci-dessus
2. Consultez les problèmes courants
3. Exécutez `flutter doctor` pour vérifier votre environnement
4. Consultez la documentation complète : `LOGO_KASED_INTEGRATION_COMPLETE.md`

---

*Guide créé le 3 mai 2026*
