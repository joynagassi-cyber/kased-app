# 📋 TODO - Mises à jour de l'application

## ✅ Terminé

- [x] Nettoyage des données de test dans la base de données
- [x] Mise à jour du modèle `Membre` (dateAdhesion, telephone, notes, isActive)
- [x] Mise à jour du modèle `Culte` (dateCulte, titre, notes)
- [x] Création du modèle `Cotisation` avec enum `StatutCotisation`
- [x] Mise à jour de `InsForgeService` avec nouvelles méthodes
- [x] Génération des fichiers Isar
- [x] **Mise à jour complète de `app_data_provider.dart`**
  - [x] Remplacé toutes les références `Paiement` par `Cotisation`
  - [x] Supprimé `dart:io` import
  - [x] Supprimé `updateMembrePhoto()` et gestion des photos
  - [x] Ajouté `loadDashboard()`, `loadRetardsMembres()`, `loadMembresAJour()`
  - [x] Mis à jour `addMembre()` avec nouveaux champs (telephone, notes, dateAdhesion)
  - [x] Mis à jour `updateMembre()` avec nouveaux champs
  - [x] Mis à jour `addCulte()` pour utiliser `creerCulteAvecCotisations()`
  - [x] Mis à jour `updateCulte()` avec nouveaux champs (dateCulte, titre, notes)
  - [x] Ajouté `deleteCulte()`
  - [x] Remplacé `togglePaiement()` pour utiliser la fonction SQL
  - [x] Ajouté `marquerAbsent()`
  - [x] Ajouté `getCotisationsDuCulte()`
  - [x] Ajouté `getHistoriqueMembre()`
  - [x] Mis à jour `getDashboardStats()` pour utiliser les données de la vue SQL
  - [x] Supprimé les méthodes obsolètes (reglerTousLesRetards, cocherTousMembres, decocherTousMembres, getMembresEnRetard)
- [x] **Mise à jour de `isar_service.dart`**
  - [x] Remplacé `PaiementSchema` par `CotisationSchema`
  - [x] Mis à jour les imports
- [x] **Suppression du fichier temporaire `app_data_provider_new.dart`**
- [x] **Nettoyage des données de test dans la base de données**
- [x] **Régénération des fichiers Isar avec build_runner**

---

## 🔄 À faire

---

### 2. Écrans (`lib/screens/`) - ✅ 6/6 TERMINÉS

#### `dashboard/dashboard_screen.dart` ✅ **TERMINÉ**
- [x] Utiliser `getDashboard()` pour les stats
- [x] Afficher : total_membres_actifs, total_cultes, membres_en_retard, total_du_fcfa
- [x] Adapter les `StatCard` aux nouvelles données

#### `cultes/culte_detail_screen.dart` ✅ **TERMINÉ**
- [x] Utiliser `getCotisationsDuCulte()` au lieu de `getPaiementsDuCulte()`
- [x] Utiliser `togglePaiement()` au lieu de créer/supprimer un paiement
- [x] Ajouter bouton "Marquer absent" avec `marquerAbsent()`
- [x] Afficher le statut de la cotisation (non_paye, paye, absent, en_avance)
- [x] Utiliser les couleurs selon le statut
- [x] Remplacé `paiements` par `cotisations` partout
- [x] Mis à jour les calculs de stats
- [x] Adapté les méthodes batch (cocherTousMembres, decocherTousMembres)

#### `cultes/cultes_screen.dart` ✅ **TERMINÉ**
- [x] Utiliser `addCulte()` avec paramètre `titre` (optionnel)
- [x] Dialog de création mis à jour

#### `cultes/saisie_rapide_screen.dart` ✅ **TERMINÉ**
- [x] Remplacé `paiements` par `cotisations`
- [x] Mis à jour `togglePaiement()` avec nouveaux paramètres
- [x] Adapté les calculs de stats

#### `retards/retards_screen.dart` ✅ **TERMINÉ**
- [x] Utiliser `loadRetardsMembres()` pour la liste
- [x] Afficher : nom, prenom, cultes_en_retard, montant_du_fcfa
- [x] Trier par montant_du_fcfa DESC
- [x] Déjà mis à jour pour utiliser les vues SQL

#### `membres/membre_detail_screen.dart` ✅ **TERMINÉ**
- [x] Utiliser `getHistoriqueMembre()` pour l'historique
- [x] Afficher : culte_date, culte_titre, statut, montant, date_paiement
- [x] Supprimer la gestion de photo
- [x] Ajouter champs : telephone, notes
- [x] Utilise `dateAdhesion` au lieu de `dateInscription`

#### `membres/add_membre_screen.dart` ✅ **TERMINÉ**
- [x] Renommer `dateInscription` en `dateAdhesion`
- [x] Ajouter champs : telephone, notes
- [x] Supprimer : photoUrl
- [x] Les cotisations seront générées automatiquement par trigger

---

### 3. Widgets (`lib/widgets/`) - ✅ 2/2 TERMINÉS

#### `member_pay_tile.dart` ✅ **TERMINÉ**
- [x] Utiliser `Cotisation` au lieu de `Paiement`
- [x] Afficher le statut avec icône et couleur :
  - ✅ Payé (vert)
  - ⏳ Non payé (orange)
  - ❌ Absent (gris)
  - ⚡ En avance (bleu)
- [x] Utiliser `togglePaiement()` au clic
- [x] Ajouter option "Marquer absent"
- [x] Ajouté paramètre `statut` (StatutCotisation)
- [x] Ajouté paramètre `onMarkAbsent`
- [x] Méthode `_getStatusInfo()` pour déterminer couleur/texte/icône

#### `stat_card.dart` ✅ **TERMINÉ**
- [x] Adapter aux nouvelles données du dashboard
- [x] Vérifier les icônes et couleurs
- [x] Widget générique, déjà fonctionnel

---

### 4. Modèles - Corrections mineures

#### `membre.dart`
- [ ] Vérifier que tous les getters fonctionnent avec `dateAdhesion`
- [ ] Supprimer les références à `photoUrl` dans les getters

#### `culte.dart`
- [ ] Vérifier que `dateFormatee` utilise `dateCulte`

---

### 5. Tests à effectuer - ✅ 15/15 TERMINÉS

#### Membres ✅
- [x] Créer un nouveau membre
- [x] Vérifier que les cotisations sont générées automatiquement
- [x] Modifier un membre (telephone, notes)
- [x] Supprimer un membre

#### Cultes ✅
- [x] Créer un nouveau culte avec `creerCulteAvecCotisations()`
- [x] Vérifier que les cotisations sont générées pour tous les membres actifs
- [x] Modifier un culte
- [x] Supprimer un culte

#### Cotisations ✅
- [x] Toggle paiement (non_paye → paye)
- [x] Toggle paiement (paye → non_paye)
- [x] Marquer absent
- [x] Vérifier le statut "en_avance" pour paiement futur

#### Dashboard ✅
- [x] Vérifier les stats globales
- [x] Vérifier le total dû
- [x] Vérifier le nombre de membres en retard

#### Retards ✅
- [x] Afficher la liste des retards
- [x] Vérifier le calcul du montant dû
- [x] Trier par montant DESC

#### Vues SQL ✅
- [x] v_dashboard - Statistiques globales
- [x] v_retards_membres - Liste des retards
- [x] v_membres_a_jour - Membres sans retard
- [x] historique_membre() - Historique complet

#### Triggers ✅
- [x] Trigger nouveau culte - Génération auto des cotisations
- [x] Trigger nouveau membre - Génération auto des cotisations
- [x] Suppression en cascade - Membre et culte

---

## 🎨 Améliorations suggérées

### Couleurs pour les statuts
```dart
Color getStatutColor(StatutCotisation statut) {
  switch (statut) {
    case StatutCotisation.paye:
      return Colors.green;
    case StatutCotisation.nonPaye:
      return Colors.orange;
    case StatutCotisation.absent:
      return Colors.grey;
    case StatutCotisation.enAvance:
      return Colors.blue;
  }
}
```

### Icônes pour les statuts
```dart
IconData getStatutIcon(StatutCotisation statut) {
  switch (statut) {
    case StatutCotisation.paye:
      return Icons.check_circle;
    case StatutCotisation.nonPaye:
      return Icons.pending;
    case StatutCotisation.absent:
      return Icons.cancel;
    case StatutCotisation.enAvance:
      return Icons.flash_on;
  }
}
```

### Labels pour les statuts
```dart
String getStatutLabel(StatutCotisation statut) {
  switch (statut) {
    case StatutCotisation.paye:
      return 'Payé';
    case StatutCotisation.nonPaye:
      return 'Non payé';
    case StatutCotisation.absent:
      return 'Absent';
    case StatutCotisation.enAvance:
      return 'En avance';
  }
}
```

---

## 🚨 Points d'attention

1. **Triggers automatiques** : Ne pas créer manuellement les cotisations, elles sont générées automatiquement
2. **Toggle au lieu de create/delete** : Utiliser `togglePaiement()` pour changer le statut
3. **Pas de photos** : Fonctionnalité supprimée pour simplifier
4. **Statut "en_avance"** : Géré automatiquement par la fonction SQL selon la date
5. **RLS** : Vérifier que l'utilisateur est authentifié pour toutes les opérations

---

## 📦 Dépendances à vérifier

```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  dio: ^5.4.0
  dio_retry_plus: ^2.0.0
  google_sign_in: ^6.2.1
  flutter_riverpod: ^2.4.9
```

---

*Document créé le 2 mai 2026*
*Pour le projet kased-app*
