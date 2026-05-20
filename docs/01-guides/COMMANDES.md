# ⚡ COMMANDES ESSENTIELLES - KASED APP

## 🚀 DÉMARRAGE RAPIDE

### Lire la documentation
```bash
# Point d'entrée
cat README_MIGRATION.md

# Démarrage rapide (15 min)
cat QUICK_START.md

# Résumé visuel
cat RESUME_VISUEL.md

# Index complet
cat INDEX_DOCUMENTATION.md
```

---

## 📱 FLUTTER

### Installation et setup
```bash
# Aller dans le dossier de l'app
cd cotis_app

# Installer les dépendances
flutter pub get

# Générer les fichiers Isar
flutter pub run build_runner build --delete-conflicting-outputs

# Ou forcer la régénération
flutter pub run build_runner build --delete-conflicting-outputs
```

### Développement
```bash
# Lancer l'app
flutter run

# Lancer sur un device spécifique
flutter run -d <device_id>

# Lister les devices
flutter devices

# Hot reload (dans l'app en cours)
# Appuyer sur 'r'

# Hot restart (dans l'app en cours)
# Appuyer sur 'R'
```

### Build
```bash
# Build Android APK
flutter build apk

# Build Android App Bundle
flutter build appbundle

# Build iOS
flutter build ios

# Build pour release
flutter build apk --release
```

### Tests
```bash
# Lancer tous les tests
flutter test

# Lancer un test spécifique
flutter test test/models/membre_test.dart

# Tests avec coverage
flutter test --coverage

# Voir le coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Nettoyage
```bash
# Clean
flutter clean

# Réinstaller les dépendances
flutter pub get

# Régénérer les fichiers
flutter pub run build_runner build --delete-conflicting-outputs
```

### Logs et debug
```bash
# Voir les logs
flutter logs

# Analyser le code
flutter analyze

# Formater le code
flutter format lib/

# Vérifier les dépendances obsolètes
flutter pub outdated
```

---

## 🗄️ BASE DE DONNÉES (via InsForge MCP)

### Vérification
```sql
-- Vérifier les tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Compter les données
SELECT 
  'membres' as table_nom, COUNT(*) as nb_lignes FROM membres
UNION ALL
SELECT 
  'cultes' as table_nom, COUNT(*) as nb_lignes FROM cultes
UNION ALL
SELECT 
  'cotisations' as table_nom, COUNT(*) as nb_lignes FROM cotisations;

-- Vérifier les vues
SELECT viewname FROM pg_views 
WHERE schemaname = 'public' 
ORDER BY viewname;

-- Vérifier les fonctions
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;
```

### Dashboard et stats
```sql
-- Dashboard global
SELECT * FROM v_dashboard;

-- Résumé des cultes
SELECT * FROM v_resume_culte 
ORDER BY date_culte DESC 
LIMIT 5;

-- Membres en retard
SELECT * FROM v_retards_membres 
ORDER BY montant_du_fcfa DESC;

-- Membres à jour
SELECT * FROM v_membres_a_jour 
ORDER BY nom;

-- Paiements anticipés
SELECT * FROM v_membres_en_avance 
ORDER BY montant_anticipe DESC;
```

### Opérations courantes
```sql
-- Créer un culte avec cotisations auto
SELECT creer_culte_avec_cotisations(
  CURRENT_DATE,
  'Culte du dimanche',
  50.0
);

-- Toggle paiement
SELECT toggle_paiement(
  '<membre_id>'::uuid,
  '<culte_id>'::uuid
);

-- Marquer absent
SELECT marquer_absent(
  '<membre_id>'::uuid,
  '<culte_id>'::uuid
);

-- Historique d'un membre
SELECT * FROM historique_membre('<membre_id>'::uuid);
```

### Données de test
```sql
-- Créer un membre de test
INSERT INTO membres (nom, prenom, date_adhesion) 
VALUES ('Test', 'User', CURRENT_DATE)
RETURNING *;

-- Créer un culte de test
SELECT creer_culte_avec_cotisations(
  CURRENT_DATE,
  'Culte de test',
  50.0
);

-- Supprimer toutes les données de test
DELETE FROM cotisations;
DELETE FROM cultes;
DELETE FROM membres;
```

### Maintenance
```sql
-- Vérifier les index
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Vérifier les contraintes
SELECT 
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type;

-- Vérifier RLS
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Vérifier les politiques RLS
SELECT 
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

---

## 🔧 GIT

### Commits
```bash
# Status
git status

# Ajouter des fichiers
git add .
git add lib/models/cotisation.dart

# Commit
git commit -m "feat: add Cotisation model with StatutCotisation enum"

# Push
git push origin main
```

### Branches
```bash
# Créer une branche
git checkout -b feature/update-providers

# Changer de branche
git checkout main

# Lister les branches
git branch -a

# Supprimer une branche
git branch -d feature/old-feature
```

### Historique
```bash
# Voir l'historique
git log --oneline

# Voir les changements
git diff

# Voir les changements d'un fichier
git diff lib/models/membre.dart
```

---

## 📦 NPM / YARN (si backend Node.js)

### Installation
```bash
# Installer les dépendances
npm install
# ou
yarn install

# Installer une dépendance
npm install package-name
yarn add package-name
```

### Scripts
```bash
# Lancer le serveur de dev
npm run dev
yarn dev

# Build
npm run build
yarn build

# Tests
npm test
yarn test

# Linter
npm run lint
yarn lint
```

---

## 🐳 DOCKER (si utilisé)

### Containers
```bash
# Lancer les containers
docker-compose up -d

# Arrêter les containers
docker-compose down

# Voir les logs
docker-compose logs -f

# Rebuild
docker-compose up -d --build
```

### Base de données
```bash
# Se connecter à la DB
docker-compose exec postgres psql -U postgres -d kased_app

# Backup
docker-compose exec postgres pg_dump -U postgres kased_app > backup.sql

# Restore
docker-compose exec -T postgres psql -U postgres kased_app < backup.sql
```

---

## 📝 ÉDITEUR DE CODE

### VS Code
```bash
# Ouvrir le projet
code .

# Ouvrir un fichier
code lib/models/cotisation.dart

# Formater le code
Shift + Alt + F (Windows/Linux)
Shift + Option + F (Mac)

# Rechercher dans les fichiers
Ctrl + Shift + F (Windows/Linux)
Cmd + Shift + F (Mac)
```

### Extensions recommandées
```bash
# Flutter
Flutter
Dart

# Git
GitLens

# Formatage
Prettier
```

---

## 🔍 RECHERCHE

### Rechercher dans les fichiers
```bash
# Rechercher un texte
grep -r "Paiement" lib/

# Rechercher et remplacer
find lib/ -type f -name "*.dart" -exec sed -i 's/Paiement/Cotisation/g' {} +

# Compter les occurrences
grep -r "Paiement" lib/ | wc -l
```

### Rechercher des fichiers
```bash
# Trouver un fichier
find . -name "membre.dart"

# Trouver tous les fichiers Dart
find . -name "*.dart"

# Trouver les fichiers modifiés récemment
find . -name "*.dart" -mtime -1
```

---

## 📊 STATISTIQUES

### Compter les lignes de code
```bash
# Compter les lignes Dart
find lib/ -name "*.dart" | xargs wc -l

# Compter les lignes SQL
wc -l prompt_files/KASED_APP_SQL_MIGRATION.md

# Compter les fichiers
find lib/ -name "*.dart" | wc -l
```

### Taille des fichiers
```bash
# Taille du projet
du -sh .

# Taille de chaque dossier
du -sh */

# Fichiers les plus gros
find . -type f -exec du -h {} + | sort -rh | head -20
```

---

## 🚨 DÉPANNAGE

### Flutter ne compile pas
```bash
# Clean complet
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problème de dépendances
```bash
# Mettre à jour les dépendances
flutter pub upgrade

# Vérifier les conflits
flutter pub deps

# Résoudre les conflits
flutter pub upgrade --major-versions
```

### Problème de build_runner
```bash
# Supprimer les fichiers générés
find . -name "*.g.dart" -delete

# Régénérer
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problème de connexion InsForge
```bash
# Vérifier la connexion
curl https://pu74z8pe.us-east.insforge.app/api/health

# Vérifier les credentials
cat cotis_app/lib/core/insforge/insforge_config.dart
```

---

## 📚 DOCUMENTATION

### Générer la documentation
```bash
# Générer la doc Dart
dart doc .

# Ouvrir la doc
open doc/api/index.html
```

### Lire la documentation
```bash
# Lister tous les fichiers de doc
ls -la *.md

# Lire un fichier
cat QUICK_START.md

# Rechercher dans la doc
grep -r "toggle_paiement" *.md
```

---

## 🎯 COMMANDES PAR CAS D'USAGE

### Je veux démarrer le projet
```bash
cd cotis_app
flutter pub get
flutter run
```

### Je veux mettre à jour les modèles
```bash
# Modifier les fichiers .dart
# Puis régénérer
flutter pub run build_runner build --delete-conflicting-outputs
```

### Je veux tester la DB
```sql
-- Via InsForge MCP
SELECT * FROM v_dashboard;
SELECT * FROM v_retards_membres;
```

### Je veux voir les logs
```bash
flutter logs
```

### Je veux faire un commit
```bash
git add .
git commit -m "feat: update providers for cotisations"
git push
```

---

*Commandes essentielles pour kased-app*
*Dernière mise à jour : 2 mai 2026*
