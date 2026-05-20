# KASED-APP — LISTE DES FONCTIONNALITÉS ADDITIONNELLES
> Chaque feature inclut un prompt d'exécution complet pour l'agent de coding

---

## RÈGLES GÉNÉRALES AGENT (valables pour TOUTES les features)

```
- Lire COTISAPP_AGENT_PROMPT.md et COTISAPP_INSFORGE_PLAN.md avant de coder
- Stack : Flutter 3 + Riverpod + InsForge (PostgreSQL) + GoRouter
- Lire le fichier concerné avant de le modifier
- Zéro refactoring spontané hors scope de la feature
- Code complet, aucun placeholder "// TODO"
- Écrire [INCERTAIN: <raison>] si tu n'es pas sûr d'une API
- Checklist binaire ✅/❌ à la fin de chaque feature
```

---

## FEATURE 01 — PAIEMENT GROUPÉ (RATTRAPAGE)

**Description** : Un membre absent plusieurs dimanches peut régler tous ses retards en une seule fois. L'app calcule le montant total dû, affiche les cultes manqués, et les coche tous en un tap.

**Écran cible** : Fiche membre (depuis MembresScreen → tap sur un membre)

**Comportement attendu** :
- Bouton "Régler les retards" visible uniquement si `nombreRetards > 0`
- Dialog de confirmation : "Jean DUPONT doit 150 FCFA pour 3 dimanches manqués. Confirmer le paiement ?"
- Sur confirmation : crée 3 `Paiement` en une seule transaction InsForge
- Animation de succès (checkmarks qui apparaissent un par un)
- Le badge retard disparaît immédiatement de la liste membres

**Tables InsForge concernées** : `paiements` (INSERT multiple)

---

### PROMPT AGENT — FEATURE 01

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

LIS D'ABORD : COTISAPP_AGENT_PROMPT.md (architecture complète)

OBJECTIF : Implémenter le paiement groupé (rattrapage de retards).

=== PHASE A — MembreDetailScreen ===

Créer le fichier : lib/screens/membres/membre_detail_screen.dart

Ce screen reçoit un Membre en paramètre (passé via GoRouter extra).
Il affiche :
1. Avatar initiales (grand, 80dp) + nom complet + date inscription
2. Section "Historique" : liste des cultes avec statut payé/non payé
3. Section "Retards" (visible si nombreRetards > 0) :
   - Compteur "X dimanches manqués"
   - Montant total dû en FCFA
   - Bouton CTA rouge "Régler les X retards — XXX FCFA"

=== PHASE B — Logique de paiement groupé ===

Dans lib/providers/app_data_provider.dart, ajouter la méthode :

Future<void> reglerTousLesRetards(String membreId) async {
  // 1. Calculer les cultes non payés pour ce membre
  // 2. Pour chaque culte manqué, appeler _api.createPaiement(...)
  // 3. Utiliser Future.wait([...]) pour paralléliser les requêtes InsForge
  // 4. Mettre à jour l'état local immédiatement après
}

=== PHASE C — Dialog de confirmation ===

showDialog avec :
- Titre : "Régler les retards de [Nom]"
- Corps : liste des dimanches manqués + montant total
- Bouton Annuler (gris)
- Bouton Confirmer (rouge → vert après succès)
- Indicateur de chargement pendant les requêtes InsForge
- Animation checkmarks sur succès (AnimatedList ou staggered)

=== PHASE D — GoRouter ===

Ajouter la route '/membres/:id' dans app_router.dart
avec extra: membre (objet Membre sérialisé).

=== CHECKLIST ===
- [ ] MembreDetailScreen créé et navigable depuis MembresScreen
- [ ] Liste des cultes manqués calculée correctement
- [ ] Dialog de confirmation affiché avec bon montant
- [ ] Future.wait parallélise les INSERT InsForge
- [ ] État local mis à jour (badge retard disparaît)
- [ ] Gestion d'erreur si une requête échoue (rollback UI)
- [ ] flutter analyze sans erreur
```

---

## FEATURE 02 — PAIEMENT GROUPÉ MULTI-MEMBRES (CULTE EN LOT)

**Description** : Dans CulteDetailScreen, bouton "Tout cocher" pour marquer TOUS les membres présents comme payés en une seule action. Avec confirmation.

**Écran cible** : CulteDetailScreen (header)

**Comportement attendu** :
- Bouton "Tout cocher" visible si au moins 1 membre n'est pas coché
- Dialog : "Marquer les 6 membres restants comme payés ?"
- Insert en parallèle des 6 paiements
- Compteur temps réel se met à jour progressivement
- Bouton "Tout décocher" pour annuler (visible si tous cochés)

---

### PROMPT AGENT — FEATURE 02

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

LIS D'ABORD : lib/screens/cultes/culte_detail_screen.dart

OBJECTIF : Ajouter les actions "Tout cocher" / "Tout décocher" dans CulteDetailScreen.

=== PHASE A — UI Header ===

Dans l'AppBar ou dans un SliverPersistentHeader sous le compteur,
ajouter une Row avec :
- Si membresNonPayés > 0 : bouton OutlinedButton.icon(Icons.check_box, "Tout cocher (X)")
- Si tousPayés : bouton OutlinedButton.icon(Icons.check_box_outline_blank, "Tout décocher")

=== PHASE B — Méthode dans AppDataNotifier ===

Ajouter dans lib/providers/app_data_provider.dart :

Future<void> cocherTousMembres(String culteId, List<Membre> membres, double montant) async {
  final dejaPayes = state.value!.paiements
      .where((p) => p.culteId == culteId)
      .map((p) => p.membreId)
      .toSet();

  final membresSansPayement = membres
      .where((m) => !dejaPayes.contains(m.id))
      .toList();

  // Créer tous les paiements en parallèle
  await Future.wait(membresSansPayement.map((m) => _api.createPaiement({
    'membre_id': m.id,
    'culte_id': culteId,
    'date_paiement': DateTime.now().toIso8601String(),
    'montant': montant,
  })));

  // Recharger les paiements du culte
  final paiementsJson = await _api.getPaiementsDuCulte(culteId);
  // Mettre à jour l'état...
}

Future<void> decocherTousMembres(String culteId) async {
  // DELETE tous les paiements du culte
  // Mettre à jour l'état local
}

=== PHASE C — Dialog de confirmation ===

showDialog avant chaque action avec :
- Nombre de membres concernés
- Montant total qui sera enregistré
- Boutons Annuler / Confirmer

=== CHECKLIST ===
- [ ] Bouton "Tout cocher" visible seulement si membresNonPayés > 0
- [ ] Bouton "Tout décocher" visible seulement si tousPayés
- [ ] Dialog de confirmation affiché
- [ ] Future.wait parallélise tous les INSERT
- [ ] Compteur temps réel se met à jour après l'opération
- [ ] Gestion d'erreur réseau (snackbar d'erreur)
- [ ] flutter analyze sans erreur
```

---

## FEATURE 03 — STATISTIQUES GRAPHIQUES (FL_CHART)

**Description** : Écran analytique avec graphiques de collecte mensuelle, taux de participation, et classement des membres les plus assidus.

**Écran cible** : Nouvel écran `/stats` accessible depuis le Dashboard

**Graphiques à créer** :
1. Barres : collecte FCFA par mois (12 derniers mois)
2. Ligne : taux de participation % par dimanche
3. Podium : top 3 membres les plus assidus (0 retard)

---

### PROMPT AGENT — FEATURE 03

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

LIS D'ABORD : COTISAPP_AGENT_PROMPT.md (palette couleurs et thème)

OBJECTIF : Créer un écran de statistiques avec fl_chart.

=== PHASE A — Dépendance ===

Ajouter dans pubspec.yaml :
  fl_chart: ^0.68.0

Puis : flutter pub get

=== PHASE B — Provider de stats ===

Créer lib/providers/stats_graphiques_provider.dart avec :

class DonneesGraphiques {
  final List<CollecteParMois> collecteParMois;     // 12 derniers mois
  final List<ParticipationParCulte> participationParCulte; // tous les cultes
  final List<MembreAssidu> topMembres;              // top 5 assidus
}

Calculer depuis les données InsForge existantes (aucun appel API supplémentaire).

=== PHASE C — StatsScreen ===

Créer lib/screens/stats/stats_screen.dart avec :

1. GRAPHE BARRES (fl_chart BarChart) :
   - X : mois abrégés (Jan, Fév, ...)
   - Y : montant FCFA collecté
   - Couleur : AppColors.primary (#1A56B0)
   - Tooltip : "XXX FCFA · N paiements"

2. GRAPHE LIGNE (fl_chart LineChart) :
   - X : numéro du culte
   - Y : pourcentage de participation (0-100%)
   - Ligne lissée (isCurved: true)
   - Couleur : AppColors.success (#10B981)
   - Zone sous la courbe (belowBarData) transparente

3. PODIUM MEMBRES ASSIDUS :
   - Liste des membres sans aucun retard
   - Badge doré/argent/bronze pour les 3 premiers
   - Calcul : (cultes_payés / cultes_concernés) × 100%

=== PHASE D — Navigation ===

Ajouter dans app_router.dart :
GoRoute(path: '/stats', builder: ...StatsScreen)

Ajouter dans AppShell BottomNavigationBar :
NavigationDestination(icon: Icons.bar_chart_outlined, label: 'Stats')

=== CHECKLIST ===
- [ ] fl_chart installé sans conflit
- [ ] DonneesGraphiques calculé sans appel API supplémentaire
- [ ] BarChart collecte mensuelle visible et correct
- [ ] LineChart participation avec courbe lissée
- [ ] Podium membres assidus calculé correctement
- [ ] Navigation vers /stats depuis BottomNav
- [ ] Responsive (pas de débordement horizontal)
- [ ] flutter analyze sans erreur
```

---

## FEATURE 04 — EXPORT PDF REGISTRE OFFICIEL

**Description** : Génère un PDF reproduisant exactement le registre papier du secrétaire. Colonnes = dimanches, lignes = membres. Cases cochées = ✓, cases vides = ☐.

**Format** : A4 paysage, tableau complet, exportable via share_plus

---

### PROMPT AGENT — FEATURE 04

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

OBJECTIF : Générer un PDF registre mensuel au format tableau.

=== DÉPENDANCES (déjà dans pubspec.yaml) ===
  pdf: ^3.10.0
  share_plus: ^7.2.0

=== PHASE A — Service PDF ===

Créer lib/core/pdf/registre_pdf_service.dart

La méthode principale :
Future<Uint8List> genererRegistre({
  required List<Membre> membres,
  required List<Culte> cultes,
  required List<Paiement> paiements,
  required int mois,    // 1-12
  required int annee,
}) async {
  // Filtrer cultes du mois demandé
  // Construire matrice membres × cultes
  // Générer le PDF avec package:pdf
}

Structure du PDF (A4 paysage) :
- En-tête : "KASED · Registre de cotisations — Mois/Année"
- Tableau :
  * Colonne 0 : Nom du membre
  * Colonnes 1..N : Date de chaque dimanche du mois (ex: "06 Avr")
  * Colonne N+1 : Total payé ce mois
  * Colonne N+2 : Retards cumulés
- Cellule payée : "✓" en vert centré
- Cellule non payée : "☐" en rouge centré
- Ligne totaux en bas : total collecté par dimanche
- Pied de page : date de génération + "Kased-App"

=== PHASE B — UI déclencheur ===

Dans StatsScreen ou RetardsScreen, ajouter un FloatingActionButton
avec Icons.picture_as_pdf.

Afficher un MonthPicker dialog (mois/année) avant la génération.

Après génération : Share.shareXFiles([XFile(path)]) avec share_plus.

=== CHECKLIST ===
- [ ] PDF généré sans crash
- [ ] Tableau avec toutes les colonnes correctes
- [ ] Cellules ✓/☐ avec bonnes couleurs
- [ ] Filtrage correct par mois/année
- [ ] MonthPicker fonctionnel
- [ ] Share sheet s'ouvre sur Android
- [ ] Gestion du cas "aucun culte ce mois"
- [ ] flutter analyze sans erreur
```

---

## FEATURE 05 — PHOTO DE PROFIL DES MEMBRES

**Description** : Chaque membre peut avoir une photo prise depuis la caméra ou importée depuis la galerie. Stockée dans InsForge Storage (S3).

**Écran cible** : AddMembreScreen + MembreDetailScreen

---

### PROMPT AGENT — FEATURE 05

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

OBJECTIF : Ajouter photos de profil membres via InsForge Storage.

=== PHASE A — Dépendances ===

Ajouter dans pubspec.yaml :
  image_picker: ^1.0.0

flutter pub get
Ajouter permissions dans android/app/src/main/AndroidManifest.xml :
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

=== PHASE B — InsForge Storage Service ===

Ajouter dans lib/core/insforge/insforge_service.dart :

Future<String> uploadPhoto(File imageFile, String membreId) async {
  // 1. Lire le fichier en bytes
  // 2. POST multipart vers InsForge Storage endpoint
  //    URL : {baseUrl}/api/storage/membres-photos/{membreId}.jpg
  // 3. Retourner l'URL publique de la photo
  [INCERTAIN: vérifier l'endpoint exact de l'API Storage InsForge]
}

=== PHASE C — Modèle Membre ===

Ajouter le champ dans la table InsForge "membres" :
  photo_url: string, nullable

Ajouter dans la classe Dart Membre :
  final String? photoUrl;

=== PHASE D — UI ===

Dans AddMembreScreen, ajouter un GestureDetector sur l'avatar initiales :
- Tap → showModalBottomSheet avec 2 options :
  * "Prendre une photo" → ImagePicker.pickImage(source: ImageSource.camera)
  * "Galerie" → ImagePicker.pickImage(source: ImageSource.gallery)
- Après sélection → upload vers InsForge Storage
- Afficher CircularProgressIndicator pendant l'upload
- Avatar affiche la photo (CircleAvatar avec backgroundImage: NetworkImage(url))

Dans MembresScreen ListTile, si photoUrl != null :
  leading: CircleAvatar(backgroundImage: NetworkImage(membre.photoUrl!))
Sinon : afficher initiales (comportement actuel).

=== CHECKLIST ===
- [ ] Permissions AndroidManifest correctes
- [ ] ImagePicker fonctionne (caméra + galerie)
- [ ] Upload InsForge Storage sans crash
- [ ] photo_url sauvegardé dans la table membres InsForge
- [ ] Photo affichée dans la liste membres
- [ ] Photo affichée dans MembreDetailScreen
- [ ] Fallback initiales si pas de photo
- [ ] flutter analyze sans erreur
```

---

## FEATURE 06 — ANNIVERSAIRES DES MEMBRES

**Description** : Champ date de naissance optionnel. Notification locale le matin du jour J. Le secrétaire voit un badge "🎂 Aujourd'hui" sur la fiche du membre.

---

### PROMPT AGENT — FEATURE 06

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

OBJECTIF : Ajouter les anniversaires et notifications locales.

=== PHASE A — Dépendance ===

Ajouter dans pubspec.yaml :
  flutter_local_notifications: ^16.0.0

flutter pub get
Permissions Android (AndroidManifest.xml) :
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

=== PHASE B — Table InsForge ===

Ajouter colonne à la table "membres" :
  date_naissance: string, nullable (format YYYY-MM-DD)

Mettre à jour la classe Dart Membre pour inclure :
  final DateTime? dateNaissance;
  
Ajouter dans fromJson et toJson.

=== PHASE C — Service Notifications ===

Créer lib/core/notifications/notification_service.dart :

class NotificationService {
  static Future<void> init() async { ... }

  // Planifie une notification annuelle récurrente
  static Future<void> planifierAnniversaire(Membre membre) async {
    if (membre.dateNaissance == null) return;
    final now = DateTime.now();
    var prochainAnniv = DateTime(now.year, membre.dateNaissance!.month, membre.dateNaissance!.day, 8, 0);
    if (prochainAnniv.isBefore(now)) {
      prochainAnniv = prochainAnniv.copyWith(year: now.year + 1);
    }
    // Planifier avec flutter_local_notifications
    // Titre : "Anniversaire de {Nom} !"
    // Corps : "{Prénom} fête ses X ans aujourd'hui."
  }

  static Future<void> annulerAnniversaire(int membreId) async { ... }
}

=== PHASE D — UI ===

Dans AddMembreScreen : ajouter DatePicker optionnel "Date de naissance (optionnel)".

Dans MembresScreen : si aujourd'hui == anniversaire du membre,
afficher une icône 🎂 ou un badge ambre "Anniversaire" à côté du nom.

Dans MembreDetailScreen : afficher l'âge calculé si date de naissance présente.

Appeler NotificationService.planifierAnniversaire(membre) à chaque
création ou modification de membre.

=== CHECKLIST ===
- [ ] Colonne date_naissance ajoutée dans InsForge
- [ ] DatePicker optionnel dans AddMembreScreen
- [ ] Notification planifiée au moment de la création/modif membre
- [ ] Badge anniversaire visible dans MembresScreen si c'est aujourd'hui
- [ ] Âge calculé et affiché dans MembreDetailScreen
- [ ] Notification reçue sur device Android
- [ ] flutter analyze sans erreur
```

---

## FEATURE 07 — MODE SAISIE RAPIDE (AFTER-CULTE)

**Description** : Mode spécial optimisé pour la période chaotique juste après le culte. Les membres défilent en ordre alphabétique, le secrétaire tape simplement sur le nom pour le cocher. Interface épurée, gros caractères, zéro distraction.

---

### PROMPT AGENT — FEATURE 07

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

OBJECTIF : Créer un mode "saisie rapide" post-culte dans CulteDetailScreen.

=== PHASE A — Bouton déclencheur ===

Dans CulteDetailScreen AppBar, ajouter une action :
  IconButton(icon: Icon(Icons.flash_on), onPressed: () => _entrerModeSaisieRapide())

=== PHASE B — SaisieRapideScreen ===

Créer lib/screens/cultes/saisie_rapide_screen.dart

Ce screen est un Dialog ou un FullscreenDialog (Navigator.push).

UI :
- Fond blanc intégral, aucun élément superflu
- Grand compteur centré en haut : "12 / 20 payés · 600 FCFA"
- Un seul membre affiché à la fois (le premier non payé alphabétiquement)
- Nom en très grande police (36sp, bold)
- Prénom au-dessus en gris (20sp)
- Deux boutons pleine largeur en bas :
  * Vert "✓ Payé" (hauteur 80dp, tap ou swipe droite)
  * Gris "→ Passer" (hauteur 56dp, passer au suivant sans payer)
- Barre de progression en haut montrant l'avancement
- Animation de transition entre membres (slide left)

Logique :
- Les membres déjà payés sont ignorés
- "Payé" → crée le paiement InsForge + passe au suivant
- "Passer" → met le membre en fin de liste (on y reviendra)
- Quand liste épuisée → écran de succès avec récapitulatif

=== PHASE C — Animation ===

Utiliser PageView ou AnimatedSwitcher avec SlideTransition
pour l'animation entre membres.

=== CHECKLIST ===
- [ ] Mode accessible depuis CulteDetailScreen
- [ ] Un seul membre affiché (premier non payé)
- [ ] Bouton "Payé" crée le paiement InsForge immédiatement
- [ ] Bouton "Passer" met le membre en fin de queue
- [ ] Animation slide entre membres fluide
- [ ] Barre de progression correcte
- [ ] Écran de succès affiché quand tout le monde est traité
- [ ] flutter analyze sans erreur
```

---

## FEATURE 08 — MONTANT VARIABLE PAR CULTE

**Description** : Certains dimanches (fêtes, projets spéciaux), le montant peut différer (75F, 100F...). Editable à la création d'un culte ou dans ses détails.

---

### PROMPT AGENT — FEATURE 08

```
Tu travailles sur KASED-APP (Flutter + Riverpod + InsForge).

OBJECTIF : Rendre le montant de cotisation éditable par culte.

=== PHASE A — UI création culte ===

Dans le dialog/form de création de culte (CultesScreen FAB),
ajouter un champ :
  TextFormField(
    label: "Montant de cotisation (FCFA)",
    initialValue: "50",
    keyboardType: TextInputType.number,
    validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Montant invalide' : null,
  )

=== PHASE B — CulteDetailScreen ===

Dans le header de CulteDetailScreen, afficher le montant du culte.
Si montant != 50, afficher un badge ambre "Montant spécial".

Permettre l'édition via un IconButton(Icons.edit) qui ouvre
un simple AlertDialog avec TextFormField pour modifier le montant.

Sur validation : appeler _api.updateCulte(culteId, {'montant_cotisation': newMontant})
et mettre à jour les paiements locaux.

=== PHASE C — Table InsForge ===

Ajouter dans InsForgeService :
Future<void> updateCulte(String id, Map<String, dynamic> data) async {
  await _dio.patch('/api/data/cultes/$id', data: data);
}

=== PHASE D — Calcul retards ===

S'assurer que le calcul des retards dans membresEnRetardProvider
utilise le montant_cotisation de CHAQUE culte (pas un montant fixe de 50).

montant_du = cultesConcernes
  .where((c) => !paiementsMembre.any((p) => p.culteId == c.id))
  .fold(0.0, (sum, c) => sum + c.montantCotisation);

=== CHECKLIST ===
- [ ] Champ montant dans la création de culte
- [ ] Badge "Montant spécial" visible si montant != 50
- [ ] Édition du montant depuis CulteDetailScreen
- [ ] PATCH InsForge fonctionne
- [ ] Calcul des retards utilise le bon montant par culte
- [ ] Le PDF export affiche le bon montant par colonne
- [ ] flutter analyze sans erreur
```

---

## RÉCAPITULATIF FEATURES

| # | Feature | Impact | Effort | Priorité |
|---|---------|--------|--------|---------|
| 01 | Paiement groupé (rattrapage membre) | ⭐⭐⭐ | S | 🔴 P1 |
| 02 | Tout cocher / tout décocher (culte) | ⭐⭐⭐ | S | 🔴 P1 |
| 03 | Statistiques graphiques (fl_chart) | ⭐⭐⭐ | M | 🟠 P2 |
| 04 | Export PDF registre officiel | ⭐⭐⭐ | M | 🟠 P2 |
| 05 | Photo de profil membres | ⭐⭐ | M | 🟡 P3 |
| 06 | Anniversaires + notifications | ⭐⭐ | S | 🟡 P3 |
| 07 | Mode saisie rapide post-culte | ⭐⭐⭐ | M | 🔴 P1 |
| 08 | Montant variable par culte | ⭐⭐ | S | 🟡 P3 |

**Ordre d'implémentation recommandé :** 07 → 01 → 02 → 04 → 03 → 08 → 06 → 05

---

*KASED-APP Features v1.0 · 8 fonctionnalités · Prompts agents inclus*
