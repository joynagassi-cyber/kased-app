# ⚡ DÉMARRAGE RAPIDE - KASED APP

## 🎯 Pour les développeurs pressés

### 1️⃣ Comprendre ce qui a changé (5 min)

```bash
# Lire le résumé
cat RESUME_MIGRATION.md
```

**En bref :**
- ✅ Table `membres` découplée de Google Auth
- ✅ Nouveau modèle `Cotisation` avec statuts (non_paye, paye, absent, en_avance)
- ✅ 5 vues SQL pour stats en temps réel
- ✅ 4 fonctions SQL pour automatiser les opérations
- ✅ 3 triggers pour génération automatique

---

### 2️⃣ Vérifier la base de données (2 min)

```sql
-- Exécuter ce script
\i prompt_files/VERIFICATION_DB.sql

-- Ou vérifier manuellement
SELECT COUNT(*) FROM membres;
SELECT COUNT(*) FROM cultes;
SELECT COUNT(*) FROM cotisations;
SELECT * FROM v_dashboard;
```

**Résultat attendu :**
- 0 membres, 0 cultes, 0 cotisations (données de test nettoyées)
- Dashboard retourne 1 ligne avec des zéros

---

### 3️⃣ Consulter les exemples de code (10 min)

```bash
# Voir les exemples prêts à l'emploi
cat CODE_EXAMPLES.md
```

**Exemples clés :**
- Créer un culte avec cotisations auto
- Toggle paiement en une ligne
- Charger le dashboard
- Afficher les retards

---

### 4️⃣ Mettre à jour l'app (10-15h)

```bash
# Voir la checklist complète
cat TODO_APP_UPDATES.md
```

**Ordre recommandé :**
1. Providers (2-3h)
2. Écrans principaux (4-6h)
3. Écrans secondaires (2-3h)
4. Widgets (1-2h)
5. Tests (2-3h)

---

## 🚀 COMMANDES ESSENTIELLES

### Flutter
```bash
cd cotis_app

# Générer les fichiers Isar (déjà fait)
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer l'app
flutter run

# Tests
flutter test
```

### SQL (via InsForge MCP)
```sql
-- Dashboard
SELECT * FROM v_dashboard;

-- Retards
SELECT * FROM v_retards_membres;

-- Créer un culte de test
SELECT creer_culte_avec_cotisations(CURRENT_DATE, 'Test', 50);

-- Toggle paiement
SELECT toggle_paiement(
  '<membre_id>'::uuid,
  '<culte_id>'::uuid
);
```

---

## 📋 CHECKLIST RAPIDE

### Base de données
- [x] Migration SQL exécutée
- [x] Vues créées
- [x] Fonctions créées
- [x] Triggers créés
- [x] RLS activé
- [x] Données de test nettoyées

### Application Flutter
- [x] Modèles mis à jour
- [x] Service InsForge enrichi
- [x] Fichiers Isar générés
- [ ] Providers mis à jour
- [ ] Écrans mis à jour
- [ ] Widgets mis à jour
- [ ] Tests effectués

---

## 🎨 NOUVEAUX STATUTS DE COTISATION

```dart
enum StatutCotisation {
  nonPaye,   // 🟠 Orange - Culte passé, pas encore payé
  paye,      // 🟢 Vert   - Payé (le jour même ou en rattrapage)
  absent,    // ⚫ Gris   - Membre absent ce dimanche
  enAvance   // 🔵 Bleu   - Payé AVANT la date du culte
}
```

**Utilisation :**
```dart
// Afficher avec couleur
Color getStatutColor(StatutCotisation statut) {
  switch (statut) {
    case StatutCotisation.paye: return Colors.green;
    case StatutCotisation.nonPaye: return Colors.orange;
    case StatutCotisation.absent: return Colors.grey;
    case StatutCotisation.enAvance: return Colors.blue;
  }
}
```

---

## 🔧 NOUVELLES MÉTHODES - CHEAT SHEET

### Cultes
```dart
// Créer avec cotisations auto
final culteId = await service.creerCulteAvecCotisations(
  dateCulte: DateTime.now(),
  titre: 'Culte du dimanche',
  montantCotisation: 50.0,
);
```

### Cotisations
```dart
// Toggle paiement (une seule ligne !)
await service.togglePaiement(
  membreId: membreId,
  culteId: culteId,
);

// Marquer absent
await service.marquerAbsent(
  membreId: membreId,
  culteId: culteId,
);

// Historique
final historique = await service.getHistoriqueMembre(membreId);
```

### Vues
```dart
// Dashboard
final dashboard = await service.getDashboard();
print('Membres en retard: ${dashboard['membres_en_retard']}');
print('Total dû: ${dashboard['total_du_fcfa']} FCFA');

// Retards
final retards = await service.getRetardsMembres();
for (final retard in retards) {
  print('${retard['nom']}: ${retard['montant_du_fcfa']} FCFA');
}

// Résumés des cultes
final resumes = await service.getResumeCultes();
```

---

## 🎯 PRIORITÉS PAR RÔLE

### Si vous êtes Backend Developer
1. ✅ Vérifier que toutes les vues fonctionnent
2. ✅ Tester les fonctions SQL
3. ✅ Vérifier les triggers
4. ✅ Valider les politiques RLS

### Si vous êtes Frontend Developer
1. 📝 Mettre à jour les providers
2. 📝 Mettre à jour les écrans
3. 📝 Mettre à jour les widgets
4. 📝 Tester l'UI

### Si vous êtes Full Stack
1. ✅ Vérifier la DB (déjà fait)
2. 📝 Mettre à jour l'app (10-15h)
3. 📝 Tests end-to-end
4. 📝 Documentation utilisateur

---

## 📚 DOCUMENTATION COMPLÈTE

### Guides
- `README_MIGRATION.md` - Vue d'ensemble
- `RESUME_MIGRATION.md` - Résumé détaillé
- `MIGRATION_GUIDE.md` - Guide technique
- `ARCHITECTURE.md` - Architecture système

### Développement
- `TODO_APP_UPDATES.md` - Checklist complète
- `CODE_EXAMPLES.md` - Exemples de code
- `QUICK_START.md` - Ce fichier

### SQL
- `prompt_files/KASED_APP_SQL_MIGRATION.md` - Scripts complets
- `prompt_files/VERIFICATION_DB.sql` - Script de vérification

---

## 🆘 EN CAS DE PROBLÈME

### La base de données ne répond pas
```bash
# Vérifier la connexion InsForge
curl https://pu74z8pe.us-east.insforge.app/api/health
```

### Les fichiers Isar ne se génèrent pas
```bash
cd cotis_app
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### L'app ne compile pas
```bash
# Vérifier les imports
grep -r "import.*paiement" lib/
# Remplacer par cotisation

# Vérifier les références
grep -r "Paiement" lib/
# Remplacer par Cotisation
```

### Les vues SQL ne retournent rien
```sql
-- Vérifier qu'il y a des données
SELECT COUNT(*) FROM membres;
SELECT COUNT(*) FROM cultes;
SELECT COUNT(*) FROM cotisations;

-- Si vide, créer des données de test
INSERT INTO membres (nom, prenom, date_adhesion) 
VALUES ('Test', 'User', CURRENT_DATE);

SELECT creer_culte_avec_cotisations(CURRENT_DATE, 'Test', 50);
```

---

## ⏱️ ESTIMATION DU TEMPS

### Déjà fait (2h)
- ✅ Migration SQL
- ✅ Mise à jour des modèles
- ✅ Mise à jour du service
- ✅ Documentation

### À faire (10-15h)
- 📝 Providers (2-3h)
- 📝 Écrans (6-9h)
- 📝 Widgets (1-2h)
- 📝 Tests (2-3h)

**Total : 12-17 heures**

---

## 🎊 PRÊT À COMMENCER ?

1. ✅ Lire ce guide (fait !)
2. ✅ Vérifier la DB
3. 📝 Consulter `CODE_EXAMPLES.md`
4. 📝 Suivre `TODO_APP_UPDATES.md`
5. 📝 Tester au fur et à mesure

**Bon courage ! 🚀**

---

*Guide de démarrage rapide*
*Dernière mise à jour : 2 mai 2026*
