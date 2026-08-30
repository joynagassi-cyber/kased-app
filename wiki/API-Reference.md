---
title: "API Reference"
description: "Référence des endpoints InsForge, constantes de l'application, et configuration"
---

# API Reference

Référence complète des endpoints InsForge et constantes de l'application.

## Endpoints InsForge

### Authentification

| Méthode | Endpoint | Description | Payload |
|---------|----------|-------------|---------|
| POST | `/api/auth/sessions?client_type=mobile` | Connexion email/mot de passe | `{email, password}` |
| POST | `/api/auth/users?client_type=mobile` | Inscription | `{email, password, name}` |
| POST | `/api/auth/refresh?client_type=mobile` | Refresh token | `{refreshToken}` |
| PUT | `/api/auth/profile` | Mettre à jour le profil | `{name}` |

**Headers requis :**
```http
apikey: <anon_key>
Authorization: Bearer <anon_key>
Content-Type: application/json
```

**Réponse connexion :**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "user": {
    "id": "uuid-user",
    "email": "user@example.com",
    "name": "Jean Dupont",
    "provider": "google"
  }
}
```

### Membres

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/database/records/membres` | Liste des membres (paginé) |
| POST | `/api/database/records/membres` | Créer un membre |
| PATCH | `/api/database/records/membres?id=eq.{id}` | Mettre à jour un membre |
| DELETE | `/api/database/records/membres?id=eq.{id}` | Supprimer un membre |

**Query parameters GET :**
```
?order=nom.asc
?is_active=eq.true
?limit=200
?offset=0
```

**Réponse POST (création) :**
```json
{
  "id": "uuid-membre",
  "nom": "Dupont",
  "prenom": "Jean",
  "date_adhesion": "2026-01-01",
  "is_active": true,
  "montant_en_avance": 0.0,
  "total_dons": 0.0,
  "version": 1,
  "created_at": "2026-08-29T10:00:00.000Z",
  "updated_at": "2026-08-29T10:00:00.000Z"
}
```

### Cultes

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/database/records/cultes` | Liste des cultes (paginé) |
| POST | `/api/database/records/cultes` | Créer un culte |
| PATCH | `/api/database/records/cultes?id=eq.{id}` | Mettre à jour un culte |
| DELETE | `/api/database/records/cultes?id=eq.{id}` | Supprimer un culte |

**RPC Functions :**
| Function | Description | Payload |
|----------|-------------|---------|
| `creer_culte_avec_cotisations` | Créer un culte + cotisations initiales | `{p_date_culte, p_titre, p_montant_cotisation}` |

### Cotisations

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/database/records/cotisations` | Liste des cotisations |
| GET | `/api/database/records/cotisations?culte_id=eq.{id}` | Cotisations d'un culte |
| GET | `/api/database/records/cotisations?membre_id=eq.{id}` | Cotisations d'un membre |
| POST | `/api/database/records/cotisations` | Créer des cotisations (bulk) |
| PATCH | `/api/database/records/cotisations?id=eq.{id}` | Mettre à jour une cotisation |
| DELETE | `/api/database/records/cotisations?id=eq.{id}` | Supprimer une cotisation |
| DELETE | `/api/database/records/cotisations?culte_id=eq.{id}` | Supprimer toutes les cotisations d'un culte |

**RPC Functions :**
| Function | Description | Payload |
|----------|-------------|---------|
| `toggle_paiement` | Toggle statut payé/non-payé | `{p_membre_id, p_culte_id}` |
| `marquer_absent` | Marquer un membre comme absent | `{p_membre_id, p_culte_id}` |
| `marquer_paye_avec_avance` | Payer avec l'avance du membre | `{p_membre_id, p_culte_id}` |
| `consommer_avance_membre` | Consommer de l'avance sans cotisation | `{p_membre_id, p_montant}` |
| `consigner_paiement_en_avance` | Payer plusieurs cultes en avance | `{p_membre_id, p_culte_ids, p_montant_total}` |
| `historique_membre` | Historique complet d'un membre | `{p_membre_id}` |

### Vues Calculées

| Endpoint | Description |
|----------|-------------|
| `GET /api/database/records/v_dashboard` | Dashboard stats |
| `GET /api/database/records/v_resume_culte` | Résumé des cultes |
| `GET /api/database/records/v_retards_membres` | Membres en retard |
| `GET /api/database/records/v_membres_a_jour` | Membres à jour |
| `GET /api/database/records/v_membres_en_avance` | Membres en avance |

### Storage (Photos)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/storage/object/membres-photos/{filename}` | Upload photo de membre |
| GET | `/api/storage/object/public/membres-photos/{filename}` | Accès public à la photo |

**Headers :**
```http
apikey: <anon_key>
Authorization: Bearer <anon_key>
```

## Constantes de l'Application

**Fichier :** `lib/core/constants.dart`

```dart
class KasedConstants {
  KasedConstants._();

  // Cotisations
  static const double cotisationMontantParDefaut = 50.0;

  // Corbeille / soft delete
  static const int joursAvantPurgeCorbeille = 30;

  // Verrouillage des cultes
  static const int joursVerrouillageCulte = 30;

  // Sync
  static const Duration syncThrottle = Duration(minutes: 5);
  static const int syncMaxRetries = 5;

  // Pagination InsForge
  static const int defaultPageSize = 200;

  // Auth
  static const Duration googleTimeout = Duration(seconds: 120);
}
```

## Configuration InsForge

**Fichier :** `lib/core/insforge/insforge_config.dart`

```dart
class InsForgeConfig {
  // URL du backend
  static const String _defaultBaseUrl = 'https://pu74z8pe.us-east.insforge.app';
  static String get baseUrl => ...;

  // Clé API anon
  static const String _defaultAnonKey = 'anon_75c09927...';
  static String get anonKey => ...;

  // Android Client ID Google
  static const String _defaultGoogleServerClientId = 
      '535496831713-eqn2k8iasrmbfuk7r91nn43bnoenkma7.apps.googleusercontent.com';
  static String get googleServerClientId => ...;

  // URL du bridge Google Auth
  static String get googleAuthBridgeUrl => 
      '$functionsBaseUrl/google-auth-bridge-v8';

  // Bucket photos
  static const String membersPhotosBucket = 'membres-photos';

  // Headers communs
  static Map<String, String> buildHeaders(String? token) => {
    'Authorization': 'Bearer ${token ?? effectiveAnonKey}',
    'apikey': token ?? effectiveAnonKey,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };
}
```

## Types de Statut Cotisation

```dart
enum StatutCotisation {
  nonPaye,   // Culte passé, pas encore payé
  paye,      // Payé (le jour même ou en rattrapage)
  absent,    // Membre absent ce dimanche
  enAvance,  // Payé AVANT la date du culte
}
```

## Types d'Opérations Sync

| Type | EntityType | Description |
|------|------------|-------------|
| `CREATE` | `membre`, `culte`, `cotisation` | Création d'une nouvelle entité |
| `UPDATE` | `membre`, `culte`, `cotisation` | Modification d'une entité existante |
| `DELETE` | `membre`, `culte` | Suppression logique d'une entité |
| `RESTORE` | `membre`, `culte` | Restauration d'une entité supprimée |

## Schéma de Réponse Dashboard

```json
{
  "total_membres": 45,
  "total_cultes": 12,
  "total_collecte": 2250000,
  "membres_en_retard": 8,
  "total_du": 400000,
  "membres_en_avance": 5,
  "montant_en_avance": 250000,
  "prochain_culte": {
    "id": "uuid-culte",
    "date_culte": "2026-09-05",
    "titre": "Culte dominical",
    "montant_cotisation": 50.0
  },
  "collecte_mois_precedent": 2100000
}
```

## Schéma de Réponse Retards

```json
[
  {
    "membre_id": "uuid-membre",
    "nom": "Dupont",
    "prenom": "Jean",
    "cultes_en_retard": 3,
    "montant_du_fcfa": 150000,
    "dernier_paiement": "2026-06-15T10:00:00.000Z",
    "montant_en_avance": 50000
  }
]
```

## Types d'Événements Push

| Event | Channel | Description |
|-------|---------|-------------|
| `membre_ajoute` | membres | Nouveau membre créé |
| `membre_modifie` | membres | Membre modifié |
| `membre_supprime` | membres | Membre supprimé |
| `culte_cree` | cultes | Nouveau culte créé |
| `culte_modifie` | cultes | Culte modifié |
| `culte_supprime` | cultes | Culte supprimé |
| `cotisation_payee` | paiements | Paiement enregistré |
| `cotisation_absente` | paiements | Absence marquée |
| `cotisation_en_avance` | paiements | Paiement en avance |
| `paiements_bulk` | paiements | Paiements en masse |
| `paiement_en_avance` | paiements | Paiement en avance |

## Headers Communs

Toutes les requêtes InsForge utilisent ces headers :

```http
Content-Type: application/json
apikey: <anon_key>
Authorization: Bearer <anon_key>
Prefer: return=representation
```

**Pour les requêtes authentifiées :**
```http
Authorization: Bearer <access_token>
apikey: <access_token>
```

## Voir Aussi

- [Architecture](Architecture) — Comment les API sont appelées
- [Authentication](Authentication) — Gestion des tokens
- [Offline-First Sync](Offline-First-Sync) — Sync des opérations
- [Data Models](Data-Models) — Schéma des entités
