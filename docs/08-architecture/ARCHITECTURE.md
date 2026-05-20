# 🏗️ ARCHITECTURE - KASED APP

## 📊 Diagramme de la base de données

```
┌─────────────────────────────────────────────────────────────────┐
│                    BASE DE DONNÉES POSTGRESQL                    │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│     MEMBRES      │         │      CULTES      │         │   COTISATIONS    │
├──────────────────┤         ├──────────────────┤         ├──────────────────┤
│ • id (UUID)      │         │ • id (UUID)      │         │ • id (UUID)      │
│ • nom            │         │ • date_culte     │         │ • membre_id  ────┼──┐
│ • prenom         │         │ • titre          │         │ • culte_id   ────┼─┐│
│ • date_adhesion  │         │ • montant_cot.   │         │ • statut (enum)  │ ││
│ • date_naissance │         │ • notes          │         │ • montant        │ ││
│ • telephone      │         │ • created_by     │         │ • date_paiement  │ ││
│ • notes          │         │ • created_at     │         │ • notes          │ ││
│ • is_active      │         │ • updated_at     │         │ • created_at     │ ││
│ • created_at     │         └──────────────────┘         │ • updated_at     │ ││
│ • updated_at     │                  │                   └──────────────────┘ ││
└──────────────────┘                  │                            │           ││
         │                            │                            │           ││
         └────────────────────────────┼────────────────────────────┘           ││
                                      └────────────────────────────────────────┘│
                                                                                 │
                                      ┌──────────────────────────────────────────┘
                                      │
                                      ▼

┌─────────────────────────────────────────────────────────────────┐
│                      TYPE ENUM STATUT                            │
├─────────────────────────────────────────────────────────────────┤
│  • non_paye   (Culte passé, pas encore payé)                    │
│  • paye       (Payé le jour même ou en rattrapage)              │
│  • absent     (Membre absent ce dimanche)                       │
│  • en_avance  (Payé AVANT la date du culte)                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        VUES CALCULÉES                            │
├─────────────────────────────────────────────────────────────────┤
│  📊 v_dashboard          → Stats globales                        │
│  📋 v_resume_culte       → Résumé par culte                      │
│  ⚠️  v_retards_membres    → Membres en retard                    │
│  ✅ v_membres_a_jour     → Membres à jour                        │
│  ⚡ v_membres_en_avance  → Paiements anticipés                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      FONCTIONS SQL                               │
├─────────────────────────────────────────────────────────────────┤
│  🔧 creer_culte_avec_cotisations()  → Création automatique       │
│  🔄 toggle_paiement()               → Marquer/démarquer paiement │
│  ❌ marquer_absent()                → Marquer absence            │
│  📜 historique_membre()             → Historique complet         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         TRIGGERS                                 │
├─────────────────────────────────────────────────────────────────┤
│  ⚙️  trg_nouveau_membre_cotisations  → Génère cotisations        │
│  ⚙️  trg_nouveau_culte_cotisations   → Génère cotisations        │
│  ⚙️  trg_*_updated_at                → Met à jour updated_at     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flux de données

### 1. Création d'un nouveau membre

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │ createMembre()
       ▼
┌─────────────┐
│  InsForge   │
│   Service   │
└──────┬──────┘
       │ POST /api/database/records/membres
       ▼
┌─────────────┐
│  PostgreSQL │
│   INSERT    │
└──────┬──────┘
       │ TRIGGER: trg_nouveau_membre_cotisations
       ▼
┌─────────────┐
│  Génération │
│ automatique │
│ cotisations │
└──────┬──────┘
       │ Pour tous les cultes passés
       ▼
┌─────────────┐
│ Cotisations │
│   créées    │
│ (non_paye)  │
└─────────────┘
```

### 2. Création d'un nouveau culte

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │ creerCulteAvecCotisations()
       ▼
┌─────────────┐
│  InsForge   │
│   Service   │
└──────┬──────┘
       │ POST /api/database/advance/rpc/creer_culte_avec_cotisations
       ▼
┌─────────────┐
│  Fonction   │
│     SQL     │
└──────┬──────┘
       │ 1. INSERT culte
       │ 2. INSERT cotisations pour tous membres actifs
       ▼
┌─────────────┐
│   Culte +   │
│ Cotisations │
│   créés     │
└─────────────┘
```

### 3. Toggle paiement

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │ togglePaiement(membreId, culteId)
       ▼
┌─────────────┐
│  InsForge   │
│   Service   │
└──────┬──────┘
       │ POST /api/database/advance/rpc/toggle_paiement
       ▼
┌─────────────┐
│  Fonction   │
│     SQL     │
└──────┬──────┘
       │ UPDATE cotisation
       │ • Si paye/en_avance → non_paye
       │ • Si non_paye → paye (ou en_avance si futur)
       ▼
┌─────────────┐
│  Cotisation │
│   mise à    │
│    jour     │
└─────────────┘
```

### 4. Chargement du dashboard

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │ getDashboard()
       ▼
┌─────────────┐
│  InsForge   │
│   Service   │
└──────┬──────┘
       │ GET /api/database/records/v_dashboard
       ▼
┌─────────────┐
│     Vue     │
│     SQL     │
└──────┬──────┘
       │ Calcule en temps réel :
       │ • total_membres_actifs
       │ • total_cultes
       │ • membres_en_retard
       │ • total_du_fcfa
       ▼
┌─────────────┐
│    Stats    │
│  affichées  │
└─────────────┘
```

---

## 🏛️ Architecture de l'application Flutter

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          SCREENS                                 │
├─────────────────────────────────────────────────────────────────┤
│  📊 Dashboard          → Stats globales                          │
│  👥 Membres            → Liste + CRUD                            │
│  📅 Cultes             → Liste + CRUD + Cotisations              │
│  ⚠️  Retards            → Liste des retards                       │
│  📈 Stats              → Graphiques                              │
│  🔐 Login              → Google Sign-In                          │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         PROVIDERS                                │
├─────────────────────────────────────────────────────────────────┤
│  🔄 AppDataProvider    → State management                        │
│  💾 IsarProvider       → Local storage                           │
│  📊 StatsProvider      → Graphiques                              │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SERVICES                                 │
├─────────────────────────────────────────────────────────────────┤
│  🌐 InsForgeService    → API calls                               │
│  🔐 AuthService        → Google Auth                             │
│  📄 PdfService         → Génération PDF                          │
│  🔔 NotificationService → Notifications                          │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                          MODELS                                  │
├─────────────────────────────────────────────────────────────────┤
│  👤 Membre             → Modèle membre                           │
│  📅 Culte              → Modèle culte                            │
│  💰 Cotisation         → Modèle cotisation                       │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LOCAL STORAGE                               │
├─────────────────────────────────────────────────────────────────┤
│  💾 Isar Database      → Cache local                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Sécurité et authentification

```
┌─────────────┐
│   Utilisateur│
│ (Secrétaire) │
└──────┬──────┘
       │ Google Sign-In
       ▼
┌─────────────┐
│   Google    │
│    OAuth    │
└──────┬──────┘
       │ ID Token
       ▼
┌─────────────┐
│  AuthService│
└──────┬──────┘
       │ Authenticated
       ▼
┌─────────────┐
│  InsForge   │
│   (RLS)     │
└──────┬──────┘
       │ Vérifie auth.uid()
       ▼
┌─────────────┐
│  PostgreSQL │
│   Policies  │
└──────┬──────┘
       │ Autorise/Refuse
       ▼
┌─────────────┐
│   Données   │
│  accessibles│
└─────────────┘
```

---

## 📦 Stack technologique

### Backend
- **Base de données** : PostgreSQL 15+
- **BaaS** : InsForge
- **API** : PostgREST (auto-généré)
- **Auth** : Google OAuth 2.0

### Frontend
- **Framework** : Flutter 3.x
- **Language** : Dart 3.x
- **State Management** : Riverpod
- **Local Storage** : Isar
- **HTTP Client** : Dio
- **PDF** : pdf package
- **Notifications** : flutter_local_notifications

### DevOps
- **Version Control** : Git
- **CI/CD** : (à définir)
- **Hosting** : InsForge

---

## 🔄 Cycle de vie des données

```
1. CRÉATION
   ┌─────────────┐
   │   Flutter   │ → createMembre() / creerCulteAvecCotisations()
   └─────────────┘
          ↓
   ┌─────────────┐
   │  InsForge   │ → POST /api/database/...
   └─────────────┘
          ↓
   ┌─────────────┐
   │ PostgreSQL  │ → INSERT + TRIGGER
   └─────────────┘
          ↓
   ┌─────────────┐
   │    Isar     │ → Cache local
   └─────────────┘

2. LECTURE
   ┌─────────────┐
   │   Flutter   │ → getDashboard() / getRetardsMembres()
   └─────────────┘
          ↓
   ┌─────────────┐
   │  InsForge   │ → GET /api/database/records/v_...
   └─────────────┘
          ↓
   ┌─────────────┐
   │     Vue     │ → Calcul en temps réel
   │     SQL     │
   └─────────────┘
          ↓
   ┌─────────────┐
   │    Isar     │ → Cache local
   └─────────────┘

3. MISE À JOUR
   ┌─────────────┐
   │   Flutter   │ → togglePaiement() / marquerAbsent()
   └─────────────┘
          ↓
   ┌─────────────┐
   │  InsForge   │ → POST /api/database/advance/rpc/...
   └─────────────┘
          ↓
   ┌─────────────┐
   │  Fonction   │ → UPDATE + Logique métier
   │     SQL     │
   └─────────────┘
          ↓
   ┌─────────────┐
   │    Isar     │ → Mise à jour cache
   └─────────────┘

4. SUPPRESSION
   ┌─────────────┐
   │   Flutter   │ → deleteMembre() / deleteCulte()
   └─────────────┘
          ↓
   ┌─────────────┐
   │  InsForge   │ → DELETE /api/database/...
   └─────────────┘
          ↓
   ┌─────────────┐
   │ PostgreSQL  │ → DELETE CASCADE (cotisations supprimées auto)
   └─────────────┘
          ↓
   ┌─────────────┐
   │    Isar     │ → Suppression cache
   └─────────────┘
```

---

## 🎯 Points clés de l'architecture

### ✅ Avantages

1. **Séparation des responsabilités**
   - Logique métier dans la DB (fonctions SQL)
   - UI dans Flutter
   - Cache local avec Isar

2. **Performance**
   - Vues pré-calculées
   - Index optimisés
   - Cache local

3. **Automatisation**
   - Triggers pour génération auto
   - Fonctions SQL pour logique complexe
   - RLS pour sécurité

4. **Maintenabilité**
   - Code organisé en couches
   - Documentation complète
   - Tests automatisés (à venir)

### ⚠️ Points d'attention

1. **Synchronisation**
   - Gérer les conflits online/offline
   - Stratégie de cache à définir

2. **Sécurité**
   - Vérifier l'authentification
   - Valider les données côté serveur

3. **Performance**
   - Pagination pour grandes listes
   - Lazy loading des images

---

*Architecture mise à jour le 2 mai 2026*
*Pour le projet kased-app*
