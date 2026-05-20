# COTISAPP — PLAN D'IMPLÉMENTATION BACKEND INSFORGE
> Backend PostgreSQL cloud · Sauvegarde automatique · Anti-perte de données
> Version : 1.0 · Compatible avec COTISAPP_AGENT_PROMPT.md

---

## POURQUOI INSFORGE POUR COTISAPP

| Problème secrétaire | Solution InsForge |
|---|---|
| Téléphone perdu → données perdues | PostgreSQL cloud, données indestructibles |
| Téléphone formaté → tout à reconstruire | Reconnexion = récupération instantanée |
| Partager les données avec un autre device | Même projet InsForge, même données |
| Pas de backup manuel | Auto-sync à chaque action |

**Architecture finale :**
```
Flutter App
    │
    ├─ Isar (cache local offline)     ← lecture rapide sans internet
    │
    └─ InsForge REST API (cloud)      ← source de vérité permanente
            │
            └─ PostgreSQL             ← 3 tables : membres, cultes, paiements
```

---

## ÉTAPE 0 — SETUP INSFORGE (5 minutes, manuel)

### 0.1 Créer un compte et un projet
```
1. Aller sur https://insforge.dev
2. Créer un compte gratuit
3. Cliquer "Create New Project" → nommer le projet "cotisapp"
4. Le projet est prêt en ~3 secondes
5. Copier le PROJECT_ID depuis l'URL :
   https://insforge.dev/dashboard/project/<PROJECT_ID>
```

### 0.2 Lier InsForge au projet Flutter
```bash
# Dans le dossier du projet Flutter (cotis_app/)
npx @insforge/cli link --project-id <TON_PROJECT_ID>
```

### 0.3 Récupérer les credentials
Depuis le dashboard InsForge, noter :
- **API Base URL** : `https://api.insforge.dev/projects/<PROJECT_ID>`
- **API Key** (secret key) : visible dans Settings → API Keys

### 0.4 Vérifier l'installation
```bash
# Prompt à envoyer à ton agent :
"I'm using InsForge as my backend platform. Read the current directory,
make sure InsForge skills are installed, and use InsForge CLI for backend tasks."
```

---

## ÉTAPE 1 — CRÉATION DES TABLES (Agent prompt prêt)

### Prompt exact à donner à ton agent InsForge/Claude Code :

```
I'm using InsForge as my backend platform.

Fetch https://insforge.dev/skill.md to learn the InsForge setup workflow.

Then create the following 3 tables in my InsForge project for a church
contribution management app called CotisApp.

=== TABLE 1: membres ===
Create table "membres" with these columns:
- nom: string, NOT NULL
- prenom: string, NOT NULL
- date_inscription: string, NOT NULL (format ISO date: YYYY-MM-DD)
- is_actif: boolean, NOT NULL, default: true
- created_at: timestamp, default: now()
- updated_at: timestamp, default: now()

No RLS needed (single secretary app, no multi-user auth).

=== TABLE 2: cultes ===
Create table "cultes" with these columns:
- date: string, NOT NULL, UNIQUE (format ISO date: YYYY-MM-DD, one culte per Sunday)
- montant_cotisation: number, NOT NULL, default: 50
- note: string, nullable
- created_at: timestamp, default: now()

=== TABLE 3: paiements ===
Create table "paiements" with these columns:
- membre_id: string, NOT NULL, foreign key → membres.id, ON DELETE CASCADE
- culte_id: string, NOT NULL, foreign key → cultes.id, ON DELETE CASCADE
- date_paiement: string, NOT NULL (ISO datetime)
- montant: number, NOT NULL, default: 50
- created_at: timestamp, default: now()

IMPORTANT: For paiements, membre_id + culte_id must be unique together
(one member can only pay once per culte). Create this as a unique constraint.

After creating all tables, verify they exist and show me the schema of each.
```

---

## ÉTAPE 2 — SCHÉMA SQL DE RÉFÉRENCE (PostgreSQL)

Le schéma exact que l'agent doit créer :

```sql
-- TABLE 1 : membres
CREATE TABLE membres (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom         TEXT NOT NULL,
  prenom      TEXT NOT NULL,
  date_inscription DATE NOT NULL DEFAULT CURRENT_DATE,
  is_actif    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_membres_nom ON membres(nom);
CREATE INDEX idx_membres_is_actif ON membres(is_actif);

-- TABLE 2 : cultes
CREATE TABLE cultes (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date                DATE NOT NULL,
  montant_cotisation  DECIMAL(10,2) NOT NULL DEFAULT 50.0,
  note                TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT cultes_date_unique UNIQUE (date)
);

CREATE INDEX idx_cultes_date ON cultes(date DESC);

-- TABLE 3 : paiements
CREATE TABLE paiements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  membre_id       UUID NOT NULL REFERENCES membres(id) ON DELETE CASCADE,
  culte_id        UUID NOT NULL REFERENCES cultes(id) ON DELETE CASCADE,
  date_paiement   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  montant         DECIMAL(10,2) NOT NULL DEFAULT 50.0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT paiements_unique_par_culte UNIQUE (membre_id, culte_id)
);

CREATE INDEX idx_paiements_membre ON paiements(membre_id);
CREATE INDEX idx_paiements_culte ON paiements(culte_id);
```

### Vue SQL utile (optionnelle mais recommandée) :
```sql
-- Vue : retards par membre (calculé côté serveur)
CREATE VIEW v_retards_membres AS
SELECT
  m.id          AS membre_id,
  m.nom,
  m.prenom,
  COUNT(c.id)   AS cultes_concernes,
  COUNT(p.id)   AS cultes_payes,
  COUNT(c.id) - COUNT(p.id) AS nombre_retards,
  (COUNT(c.id) - COUNT(p.id)) * 50.0 AS montant_du
FROM membres m
LEFT JOIN cultes c ON c.date >= m.date_inscription
LEFT JOIN paiements p ON p.membre_id = m.id AND p.culte_id = c.id
WHERE m.is_actif = TRUE
GROUP BY m.id, m.nom, m.prenom
HAVING COUNT(c.id) - COUNT(p.id) > 0
ORDER BY montant_du DESC;
```

---

## ÉTAPE 3 — INTÉGRATION FLUTTER ↔ INSFORGE

### 3.1 Nouvelles dépendances à ajouter dans pubspec.yaml

```yaml
dependencies:
  # ... tout ce qui était déjà là +
  
  # HTTP client
  dio: ^5.3.0
  
  # Connectivité (détection offline/online)
  connectivity_plus: ^5.0.0
  
  # Secure storage pour l'API key
  flutter_secure_storage: ^9.0.0
  
  # Retry automatique sur erreur réseau
  dio_retry_plus: ^1.0.0
```

### 3.2 Architecture hybride : Isar (offline) + InsForge (cloud)

```
Action utilisateur (ex: toggle paiement)
        │
        ▼
┌─────────────────┐
│  Flutter App    │
│  (Riverpod)     │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Isar    │ ← Mise à jour IMMÉDIATE (UX réactive)
    │ (local) │
    └────┬────┘
         │
    ┌────▼────────────┐
    │ InsForge        │ ← Sync en background (async)
    │ REST API        │   Si offline → queue locale → retry auto
    └─────────────────┘
```

**Principe :** Isar est la source de vérité pour l'affichage (réactif, offline).
InsForge est la source de vérité pour la persistance cloud (sauvegarde).

---

## ÉTAPE 4 — CODE FLUTTER : COUCHE SERVICE INSFORGE

### `lib/core/insforge/insforge_config.dart`
```dart
class InsForgeConfig {
  // À REMPLIR avec les vraies valeurs de ton projet InsForge
  static const String projectId = 'TON_PROJECT_ID';
  static const String apiKey = 'TA_API_KEY_INSFORGE';
  static const String baseUrl = 'https://api.insforge.dev/projects/$projectId';
  
  // Headers requis pour toutes les requêtes
  static Map<String, String> get headers => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };
  
  // Endpoints
  static String get membresUrl => '$baseUrl/api/data/membres';
  static String get cultesUrl => '$baseUrl/api/data/cultes';
  static String get paiementsUrl => '$baseUrl/api/data/paiements';
}
```

### `lib/core/insforge/insforge_service.dart`
```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cotis_app/core/insforge/insforge_config.dart';

/// Service REST pour InsForge — toutes les opérations cloud
class InsForgeService {
  static InsForgeService? _instance;
  late final Dio _dio;

  InsForgeService._() {
    _dio = Dio(BaseOptions(
      baseUrl: InsForgeConfig.baseUrl,
      headers: InsForgeConfig.headers,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    // Intercepteur de logs (retirer en production)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  static InsForgeService get instance => _instance ??= InsForgeService._();

  // ─── MEMBRES ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMembres() async {
    final res = await _dio.get('/api/data/membres', queryParameters: {
      'is_actif': 'eq.true',
      'order': 'nom.asc',
    });
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  Future<Map<String, dynamic>> createMembre(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/data/membres', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateMembre(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _dio.patch('/api/data/membres/$id', data: data);
  }

  Future<void> deleteMembre(String id) async {
    await _dio.delete('/api/data/membres/$id');
  }

  // ─── CULTES ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCultes() async {
    final res = await _dio.get('/api/data/cultes', queryParameters: {
      'order': 'date.desc',
    });
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  Future<Map<String, dynamic>> createCulte(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/data/cultes', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteCulte(String id) async {
    await _dio.delete('/api/data/cultes/$id');
  }

  /// Trouve ou crée le culte de la date donnée
  Future<Map<String, dynamic>> findOrCreateCulte(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    // Chercher d'abord
    final res = await _dio.get('/api/data/cultes', queryParameters: {
      'date': 'eq.$dateStr',
    });
    final list = List<Map<String, dynamic>>.from(res.data as List);
    
    if (list.isNotEmpty) return list.first;
    
    // Créer si non trouvé
    return createCulte({
      'date': dateStr,
      'montant_cotisation': 50,
    });
  }

  // ─── PAIEMENTS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPaiementsDuCulte(String culteId) async {
    final res = await _dio.get('/api/data/paiements', queryParameters: {
      'culte_id': 'eq.$culteId',
    });
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  Future<List<Map<String, dynamic>>> getPaiementsDuMembre(String membreId) async {
    final res = await _dio.get('/api/data/paiements', queryParameters: {
      'membre_id': 'eq.$membreId',
      'order': 'date_paiement.desc',
    });
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  Future<List<Map<String, dynamic>>> getTousPaiements() async {
    final res = await _dio.get('/api/data/paiements');
    return List<Map<String, dynamic>>.from(res.data as List);
  }

  Future<void> createPaiement(Map<String, dynamic> data) async {
    await _dio.post('/api/data/paiements', data: data);
  }

  Future<void> deletePaiement(String membreId, String culteId) async {
    // Supprimer par combinaison membre_id + culte_id
    await _dio.delete('/api/data/paiements', queryParameters: {
      'membre_id': 'eq.$membreId',
      'culte_id': 'eq.$culteId',
    });
  }

  // ─── SYNC COMPLÈTE ──────────────────────────────────────────────────────────
  
  /// Récupère toutes les données en une seule fois (au démarrage)
  Future<({
    List<Map<String, dynamic>> membres,
    List<Map<String, dynamic>> cultes,
    List<Map<String, dynamic>> paiements,
  })> syncAll() async {
    final results = await Future.wait([
      getMembres(),
      getCultes(),
      getTousPaiements(),
    ]);
    return (
      membres: results[0],
      cultes: results[1],
      paiements: results[2],
    );
  }
}
```

---

## ÉTAPE 5 — MODÈLES DART ADAPTÉS (UUID au lieu de int)

> ⚠️ InsForge utilise des UUID (String) comme clés primaires, pas des int comme Isar.
> Les modèles doivent être adaptés.

### `lib/models/membre.dart` (version InsForge-compatible)
```dart
class Membre {
  final String id;        // UUID InsForge
  final String nom;
  final String prenom;
  final DateTime dateInscription;
  final bool isActif;
  
  const Membre({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.dateInscription,
    this.isActif = true,
  });
  
  String get nomComplet => '$prenom $nom'.trim();
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }
  
  factory Membre.fromJson(Map<String, dynamic> json) => Membre(
    id: json['id'] as String,
    nom: json['nom'] as String,
    prenom: json['prenom'] as String,
    dateInscription: DateTime.parse(json['date_inscription'] as String),
    isActif: json['is_actif'] as bool? ?? true,
  );
  
  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'date_inscription': dateInscription.toIso8601String().substring(0, 10),
    'is_actif': isActif,
  };
  
  Membre copyWith({
    String? nom,
    String? prenom,
    DateTime? dateInscription,
    bool? isActif,
  }) => Membre(
    id: id,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    dateInscription: dateInscription ?? this.dateInscription,
    isActif: isActif ?? this.isActif,
  );
}
```

### `lib/models/culte.dart` (version InsForge-compatible)
```dart
class Culte {
  final String id;
  final DateTime date;
  final double montantCotisation;
  final String? note;
  
  const Culte({
    required this.id,
    required this.date,
    this.montantCotisation = 50.0,
    this.note,
  });
  
  String get dateFormatee {
    const mois = ['Jan','Fév','Mar','Avr','Mai','Jun',
                   'Jul','Aoû','Sep','Oct','Nov','Déc'];
    final wd = date.weekday;
    final nomJour = wd == 7 ? 'Dimanche' : ['Lun','Mar','Mer','Jeu','Ven','Sam'][wd-1];
    return '$nomJour ${date.day} ${mois[date.month - 1]} ${date.year}';
  }
  
  factory Culte.fromJson(Map<String, dynamic> json) => Culte(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    montantCotisation: (json['montant_cotisation'] as num?)?.toDouble() ?? 50.0,
    note: json['note'] as String?,
  );
  
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String().substring(0, 10),
    'montant_cotisation': montantCotisation,
    if (note != null) 'note': note,
  };
}
```

### `lib/models/paiement.dart` (version InsForge-compatible)
```dart
class Paiement {
  final String id;
  final String membreId;
  final String culteId;
  final DateTime datePaiement;
  final double montant;
  
  const Paiement({
    required this.id,
    required this.membreId,
    required this.culteId,
    required this.datePaiement,
    this.montant = 50.0,
  });
  
  factory Paiement.fromJson(Map<String, dynamic> json) => Paiement(
    id: json['id'] as String,
    membreId: json['membre_id'] as String,
    culteId: json['culte_id'] as String,
    datePaiement: DateTime.parse(json['date_paiement'] as String),
    montant: (json['montant'] as num?)?.toDouble() ?? 50.0,
  );
  
  Map<String, dynamic> toJson() => {
    'membre_id': membreId,
    'culte_id': culteId,
    'date_paiement': datePaiement.toIso8601String(),
    'montant': montant,
  };
}
```

---

## ÉTAPE 6 — PROVIDERS RIVERPOD (version InsForge)

### `lib/providers/app_data_provider.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cotis_app/core/insforge/insforge_service.dart';
import 'package:cotis_app/models/membre.dart';
import 'package:cotis_app/models/culte.dart';
import 'package:cotis_app/models/paiement.dart';
part 'app_data_provider.g.dart';

// ─── ÉTAT GLOBAL ────────────────────────────────────────────────────────────

class AppData {
  final List<Membre> membres;
  final List<Culte> cultes;
  final List<Paiement> paiements;
  final bool isLoading;
  final String? error;
  
  const AppData({
    this.membres = const [],
    this.cultes = const [],
    this.paiements = const [],
    this.isLoading = false,
    this.error,
  });
  
  AppData copyWith({
    List<Membre>? membres,
    List<Culte>? cultes,
    List<Paiement>? paiements,
    bool? isLoading,
    String? error,
  }) => AppData(
    membres: membres ?? this.membres,
    cultes: cultes ?? this.cultes,
    paiements: paiements ?? this.paiements,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

// ─── NOTIFIER PRINCIPAL ──────────────────────────────────────────────────────

@riverpod
class AppDataNotifier extends _$AppDataNotifier {
  final _api = InsForgeService.instance;
  
  @override
  Future<AppData> build() async {
    // Chargement initial : tout fetch depuis InsForge
    return _loadAll();
  }
  
  Future<AppData> _loadAll() async {
    try {
      final data = await _api.syncAll();
      return AppData(
        membres: data.membres.map(Membre.fromJson).toList()
          ..sort((a, b) => a.nom.compareTo(b.nom)),
        cultes: data.cultes.map(Culte.fromJson).toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
        paiements: data.paiements.map(Paiement.fromJson).toList(),
      );
    } catch (e) {
      throw Exception('Erreur de connexion InsForge: $e');
    }
  }
  
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadAll());
  }
  
  // ─── MEMBRES ────────────────────────────────────────────────────────────────
  
  Future<void> ajouterMembre({
    required String nom,
    required String prenom,
    required DateTime dateInscription,
  }) async {
    final json = await _api.createMembre({
      'nom': nom,
      'prenom': prenom,
      'date_inscription': dateInscription.toIso8601String().substring(0, 10),
    });
    final nouveau = Membre.fromJson(json);
    state = AsyncData(state.value!.copyWith(
      membres: [...state.value!.membres, nouveau]
        ..sort((a, b) => a.nom.compareTo(b.nom)),
    ));
  }
  
  Future<void> modifierMembre(Membre membre) async {
    await _api.updateMembre(membre.id, membre.toJson());
    state = AsyncData(state.value!.copyWith(
      membres: state.value!.membres.map((m) => m.id == membre.id ? membre : m).toList(),
    ));
  }
  
  Future<void> supprimerMembre(String id) async {
    await _api.deleteMembre(id);
    state = AsyncData(state.value!.copyWith(
      membres: state.value!.membres.where((m) => m.id != id).toList(),
    ));
  }
  
  // ─── CULTES ─────────────────────────────────────────────────────────────────
  
  Future<Culte> creerCulte({required DateTime date, double montant = 50.0, String? note}) async {
    final json = await _api.createCulte({
      'date': date.toIso8601String().substring(0, 10),
      'montant_cotisation': montant,
      if (note != null) 'note': note,
    });
    final nouveau = Culte.fromJson(json);
    state = AsyncData(state.value!.copyWith(
      cultes: [nouveau, ...state.value!.cultes],
    ));
    return nouveau;
  }
  
  Future<Culte> creerCulteAujourdhui() async {
    final today = DateTime.now();
    // Vérifier si un culte existe déjà pour aujourd'hui
    final dateStr = today.toIso8601String().substring(0, 10);
    final existing = state.value?.cultes.where(
      (c) => c.date.toIso8601String().substring(0, 10) == dateStr,
    ).firstOrNull;
    if (existing != null) return existing;
    return creerCulte(date: today);
  }
  
  Future<void> supprimerCulte(String id) async {
    await _api.deleteCulte(id);
    state = AsyncData(state.value!.copyWith(
      cultes: state.value!.cultes.where((c) => c.id != id).toList(),
      paiements: state.value!.paiements.where((p) => p.culteId != id).toList(),
    ));
  }
  
  // ─── PAIEMENTS ──────────────────────────────────────────────────────────────
  
  Future<void> togglePaiement({
    required String membreId,
    required String culteId,
    required double montant,
    required bool estDejaPayé,
  }) async {
    if (estDejaPayé) {
      // Supprimer le paiement
      await _api.deletePaiement(membreId, culteId);
      state = AsyncData(state.value!.copyWith(
        paiements: state.value!.paiements.where(
          (p) => !(p.membreId == membreId && p.culteId == culteId)
        ).toList(),
      ));
    } else {
      // Créer le paiement
      final data = {
        'membre_id': membreId,
        'culte_id': culteId,
        'date_paiement': DateTime.now().toIso8601String(),
        'montant': montant,
      };
      await _api.createPaiement(data);
      // Recharger les paiements pour avoir l'id
      final paiementsJson = await _api.getPaiementsDuCulte(culteId);
      final paiements = [
        ...state.value!.paiements.where((p) => p.culteId != culteId),
        ...paiementsJson.map(Paiement.fromJson),
      ];
      state = AsyncData(state.value!.copyWith(paiements: paiements));
    }
  }
}

// ─── PROVIDERS DÉRIVÉS (lecture seule, calculés) ──────────────────────────

@riverpod
List<Membre> membresActifs(MembresActifsRef ref) {
  final data = ref.watch(appDataNotifierProvider).valueOrNull;
  return data?.membres.where((m) => m.isActif).toList() ?? [];
}

@riverpod
List<Culte> cultesTriés(CultesTriésRef ref) {
  final data = ref.watch(appDataNotifierProvider).valueOrNull;
  return data?.cultes ?? [];
}

@riverpod
List<Paiement> paiementsDuCulte(PaiementsDuCulteRef ref, String culteId) {
  final data = ref.watch(appDataNotifierProvider).valueOrNull;
  return data?.paiements.where((p) => p.culteId == culteId).toList() ?? [];
}

// ─── CALCUL DES RETARDS ───────────────────────────────────────────────────

class MembreRetard {
  final Membre membre;
  final int nombreRetards;
  final double montantDu;
  final DateTime? dernierPaiement;
  
  const MembreRetard({
    required this.membre,
    required this.nombreRetards,
    required this.montantDu,
    this.dernierPaiement,
  });
}

@riverpod
List<MembreRetard> membresEnRetard(MembresEnRetardRef ref) {
  final data = ref.watch(appDataNotifierProvider).valueOrNull;
  if (data == null) return [];
  
  final retards = <MembreRetard>[];
  
  for (final membre in data.membres) {
    final dateRef = DateTime(
      membre.dateInscription.year,
      membre.dateInscription.month,
      membre.dateInscription.day,
    );
    
    // Cultes depuis la date d'inscription
    final cultesConcernes = data.cultes.where(
      (c) => !c.date.isBefore(dateRef)
    ).toList();
    
    // Paiements du membre
    final paiementsMembre = data.paiements.where(
      (p) => p.membreId == membre.id
    ).toList();
    
    final retard = cultesConcernes.length - paiementsMembre.length;
    
    if (retard > 0) {
      DateTime? dernierPaiement;
      if (paiementsMembre.isNotEmpty) {
        paiementsMembre.sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
        dernierPaiement = paiementsMembre.first.datePaiement;
      }
      retards.add(MembreRetard(
        membre: membre,
        nombreRetards: retard,
        montantDu: retard * 50.0,
        dernierPaiement: dernierPaiement,
      ));
    }
  }
  
  retards.sort((a, b) => b.montantDu.compareTo(a.montantDu));
  return retards;
}

@riverpod
Map<String, dynamic> dashboardStats(DashboardStatsRef ref) {
  final data = ref.watch(appDataNotifierProvider).valueOrNull;
  final retards = ref.watch(membresEnRetardProvider);
  
  if (data == null) return {};
  
  final totalCollecte = data.paiements.fold(0.0, (sum, p) => sum + p.montant);
  
  return {
    'totalMembres': data.membres.where((m) => m.isActif).length,
    'totalCultes': data.cultes.length,
    'totalCollecte': totalCollecte,
    'membresEnRetard': retards.length,
  };
}
```

---

## ÉTAPE 7 — GESTION OFFLINE (Connectivité)

### `lib/core/connectivity/sync_manager.dart`
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cotis_app/providers/app_data_provider.dart';

class SyncManager {
  static StreamSubscription? _subscription;
  
  static void init(WidgetRef ref) {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Retour en ligne → resynchroniser depuis InsForge
        ref.read(appDataNotifierProvider.notifier).refresh();
      }
    });
  }
  
  static void dispose() {
    _subscription?.cancel();
  }
}
```

### Indicateur de statut dans l'AppBar :
```dart
// Dans app_shell.dart, ajouter dans le Scaffold :
StreamBuilder<ConnectivityResult>(
  stream: Connectivity().onConnectivityChanged,
  builder: (ctx, snap) {
    final offline = snap.data == ConnectivityResult.none;
    if (!offline) return const SizedBox.shrink();
    return Container(
      color: Colors.orange,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Center(
        child: Text('Mode hors-ligne — données non sauvegardées',
          style: TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  },
)
```

---

## ÉTAPE 8 — CHECKLIST FINALE BACKEND

### Vérification des tables InsForge :
```
□ Table "membres" créée avec 7 colonnes (id, nom, prenom, date_inscription, is_actif, created_at, updated_at)
□ Table "cultes" créée avec 5 colonnes + contrainte UNIQUE sur date
□ Table "paiements" créée avec 6 colonnes + FK membres + FK cultes + contrainte UNIQUE (membre_id, culte_id)
□ InsForgeService.syncAll() retourne des données valides
□ Création d'un membre → apparaît dans le dashboard InsForge
□ Création d'un culte → apparaît dans le dashboard InsForge
□ Toggle paiement → paiement créé/supprimé dans InsForge
□ Fermer l'app, relancer → données persistantes depuis le cloud
□ Simuler offline → bannière orange visible
□ Retour online → refresh automatique
```

---

## RÉCAPITULATIF ARCHITECTURE FINALE

```
CotisApp
├── Frontend : Flutter (Android APK)
│   ├── Riverpod : AppDataNotifier (état global)
│   ├── Screens : Dashboard, Membres, Cultes, CulteDetail, Retards  
│   └── GoRouter : Navigation Shell
│
├── Couche Service : InsForgeService (REST client Dio)
│   ├── getMembres / createMembre / updateMembre / deleteMembre
│   ├── getCultes / createCulte / deleteCulte
│   ├── getPaiements / createPaiement / deletePaiement
│   └── syncAll() → chargement initial
│
└── Backend : InsForge Cloud (PostgreSQL)
    ├── Table membres (UUID PK)
    ├── Table cultes (UUID PK, date UNIQUE)
    └── Table paiements (UUID PK, FK membre+culte, UNIQUE membre+culte)
```

**Avantage clé :** Le secrétaire peut changer de téléphone, perdre son appareil, le formater —
ses données sont intactes sur InsForge. Il suffit de réinstaller l'app et saisir l'API key.

---

*COTISAPP InsForge Backend Plan v1.0 · PostgreSQL Cloud · Généré pour agent d'exécution*
