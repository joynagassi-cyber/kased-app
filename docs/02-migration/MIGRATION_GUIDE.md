# 📘 GUIDE DE MIGRATION - KASED APP

## ✅ Changements effectués

### 1. Base de données (PostgreSQL/InsForge)

#### Tables modifiées :
- **`membres`** : Découplée de Google Auth
  - ❌ Supprimé : `google_id`, `photo_url`, `email`, `provider_id`, `auth_user_id`
  - ✅ Ajouté : `telephone`, `notes`
  - ✅ Renommé : `date_inscription` → `date_adhesion`, `is_actif` → `is_active`

- **`cultes`** : Structure ajustée
  - ✅ Ajouté : `titre`, `updated_at`
  - ✅ Renommé : `date` → `date_culte`, `note` → `notes`

#### Nouvelle table :
- **`cotisations`** (remplace `paiement`)
  - Colonnes : `id`, `membre_id`, `culte_id`, `statut`, `montant`, `date_paiement`, `notes`, `created_at`, `updated_at`
  - Type enum : `statut_cotisation` (non_paye, paye, absent, en_avance)

#### Vues calculées créées :
- `v_dashboard` - Statistiques globales
- `v_resume_culte` - Résumé par culte
- `v_retards_membres` - Membres en retard
- `v_membres_a_jour` - Membres à jour
- `v_membres_en_avance` - Paiements anticipés

#### Fonctions SQL créées :
- `creer_culte_avec_cotisations(date, titre, montant)` - Création automatique
- `toggle_paiement(membre_id, culte_id)` - Marquer/démarquer paiement
- `marquer_absent(membre_id, culte_id)` - Marquer absence
- `historique_membre(membre_id)` - Historique complet

#### Triggers automatiques :
- Génération auto des cotisations pour nouveau membre
- Génération auto des cotisations pour nouveau culte
- Mise à jour automatique de `updated_at`

---

### 2. Modèles Flutter (Dart)

#### `Membre` (`lib/models/membre.dart`)
```dart
// Avant
dateInscription, photoUrl, isActif

// Après
dateAdhesion, telephone, notes, isActive
```

#### `Culte` (`lib/models/culte.dart`)
```dart
// Avant
date, note

// Après
dateCulte, titre, notes
```

#### `Cotisation` (`lib/models/cotisation.dart`) - NOUVEAU
```dart
enum StatutCotisation { nonPaye, paye, absent, enAvance }

class Cotisation {
  String id, membreId, culteId;
  StatutCotisation statut;
  double montant;
  DateTime? datePaiement;
  String? notes;
}
```

---

### 3. Service InsForge (`lib/core/insforge/insforge_service.dart`)

#### Nouvelles méthodes :

**Cultes :**
- `creerCulteAvecCotisations()` - Utilise la fonction SQL

**Cotisations :**
- `getCotisations()` - Toutes les cotisations
- `getCotisationsDuCulte(culteId)` - Par culte
- `getCotisationsDuMembre(membreId)` - Par membre
- `togglePaiement(membreId, culteId)` - Toggle paiement
- `marquerAbsent(membreId, culteId)` - Marquer absent
- `getHistoriqueMembre(membreId)` - Historique

**Vues :**
- `getDashboard()` - Stats globales
- `getResumeCultes()` - Résumés des cultes
- `getRetardsMembres()` - Membres en retard
- `getMembresAJour()` - Membres à jour
- `getMembresEnAvance()` - Paiements anticipés

#### Méthodes supprimées :
- ❌ `uploadPhoto()` - Plus nécessaire
- ❌ `getPaiements()`, `createPaiement()`, etc. - Remplacées par cotisations

---

## 🚀 Prochaines étapes

### 1. Générer les fichiers Isar
```bash
cd cotis_app
dart run build_runner build --delete-conflicting-outputs
```

### 2. Mettre à jour les providers
- [ ] `app_data_provider.dart` - Remplacer `Paiement` par `Cotisation`
- [ ] Utiliser les nouvelles méthodes du service InsForge

### 3. Mettre à jour les écrans
- [ ] `screens/dashboard/` - Utiliser `getDashboard()`
- [ ] `screens/cultes/` - Utiliser `creerCulteAvecCotisations()` et `togglePaiement()`
- [ ] `screens/retards/` - Utiliser `getRetardsMembres()`
- [ ] `screens/membres/` - Adapter aux nouveaux champs

### 4. Mettre à jour les widgets
- [ ] `member_pay_tile.dart` - Utiliser `Cotisation` et `StatutCotisation`
- [ ] Supprimer les références à `photoUrl`

### 5. Tests
- [ ] Tester la création de membres
- [ ] Tester la création de cultes avec cotisations auto
- [ ] Tester le toggle de paiement
- [ ] Tester le marquage d'absence
- [ ] Vérifier le dashboard
- [ ] Vérifier les retards

---

## 📝 Notes importantes

1. **Données de test nettoyées** : La base de données est vide et prête pour la production
2. **Triggers automatiques** : Les cotisations sont générées automatiquement
3. **RLS activé** : Sécurité au niveau des lignes pour utilisateurs authentifiés
4. **Pas de photos** : Fonctionnalité de photos de membres supprimée (simplification)
5. **Statuts de cotisation** : 4 états possibles (non_paye, paye, absent, en_avance)

---

## 🔧 Commandes utiles

### Vérifier l'état de la base de données
```sql
SELECT COUNT(*) FROM membres;
SELECT COUNT(*) FROM cultes;
SELECT COUNT(*) FROM cotisations;
SELECT * FROM v_dashboard;
```

### Créer un culte de test
```sql
SELECT creer_culte_avec_cotisations(CURRENT_DATE, 'Culte test', 50);
```

### Voir les retards
```sql
SELECT * FROM v_retards_membres;
```

---

*Migration effectuée le 2 mai 2026*
*Stack : Flutter + InsForge (PostgreSQL)*
