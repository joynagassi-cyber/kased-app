---
title: "Glossary"
description: "Glossaire des termes techniques et métier de Kased App"
---

# Glossary

Glossaire des termes techniques et métier de Kased App.

## Termes Métier

| Terme | Définition | Contexte |
|-------|------------|----------|
| **Culte** | Réunion de l'église, généralement dominicale | Modèle `Culte` |
| **Cotisation** | Contribution financière obligatoire des membres | Modèle `Cotisation` |
| **En avance** | Paiement effectué AVANT la date du culte | Statut `enAvance` |
| **Payé** | Paiement effectué le jour du culte ou en rattrapage | Statut `paye` |
| **Absent** | Membre absant ce dimanche | Statut `absent` |
| **Non payé** | Culte passé, pas encore payé | Statut `nonPaye` |
| **Montant obligatoire** | Somme due par chaque membre (défaut: 50 FCFA) | Champ `montantObligatoire` |
| **Montant en avance** | Crédits accumulés par un membre pour les futurs cultes | Champ `montantEnAvance` |
| **Total dons** | Somme des excédents de paiement (dons) | Champ `totalDons` |
| **Retard** | Membre avec des cotisations impayées | Écran `/retards` |
| **Corbeille** | Éléments soft-déleted, conservés 30 jours avant purge | Modèle `CorbeilleItem` |

## Termes Techniques

| Terme | Définition | Fichier |
|-------|------------|---------|
| **Offline-first** | Pattern où la données locale (Isar) est la source de vérité principale | `lib/core/sync/sync_manager.dart` |
| **Sync Operation** | Opération en attente de synchronisation avec le cloud | `lib/models/sync_operation.dart` |
| **Patch** | Mise à jour incrementale des données via Socket.IO | `lib/core/realtime/realtime_patch_engine.dart` |
| **Timestamp Guard** | Mécanisme pour ignorer les événements périmés | `lib/core/realtime/realtime_patch_engine.dart:67` |
| **Merge Strategy** | Algorithme de fusion local ↔ cloud | `lib/core/isar_local_cache.dart:180` |
| **Retry Exponentiel** | Backoff exponentiel pour les opérations sync échouées | `lib/core/sync/sync_manager.dart:156` |
| **Sealed Class** | Classe non-extensible pour le typage exhaustif | `lib/store/kased_action.dart` |
| **Provider** | Objet Riverpod qui gère l'état | `lib/providers/kased_app_provider.dart` |
| **Store** | Classe centrale qui contient l'état et les handlers | `lib/store/kased_store.dart` |
| **Handler** | Classe qui encapsule la logique métier d'un domaine | `lib/store/handlers/member_handler.dart` |
| **Bridge** | Fonction serveur intermédiaire (Google Auth) | `functions/google-auth-bridge.js` |
| **InsForge** | Backend-as-a-Service (PostgreSQL + PostgREST + Edge Functions) | Configuration |
| **PostgREST** | API REST automatique depuis PostgreSQL | InsForge |
| **Edge Function** | Fonction serveur exécutée sur le CDN InsForge | `functions/` |
| **Isar** | Base de données locale NoSQL pour Flutter | `pubspec.yaml` |
| **Riverpod** | Framework de gestion d'état pour Flutter | `pubspec.yaml` |
| **GoRouter** | Routage déclaratif pour Flutter | `pubspec.yaml` |
| **Socket.IO** | Bibliothèque WebSocket pour le temps réel | `pubspec.yaml` |
| **OneSignal** | Service de push notifications multi-utilisateurs | `pubspec.yaml` |
| **Sentry** | Plateforme de monitoring d'erreurs | `pubspec.yaml` |
| **Crashlytics** | Service de rapport de crashs Firebase | `pubspec.yaml` |
| **Dio** | Client HTTP pour Flutter avec intercepteurs | `pubspec.yaml` |
| **build_runner** | Outil de génération de code Dart | `pubspec.yaml` |
| **fake** | Implémentation mockée pour les tests | `test/fakes/` |

## Termes d'Architecture

| Terme | Définition | Analogie |
|-------|------------|----------|
| **Mono-repo** | Un seul repository contient le code Flutter et les fonctions serveur | — |
| **BaaS** | Backend-as-a-Service : backend hébergé et géré par un provider | InsForge |
| **ORM** | Object-Relational Mapping : Isar mappe les classes Dart vers Isar | ActiveRecord |
| **CQRS** | Command Query Responsibility Segregation : séparation lecture/écriture | Store pattern |
| **Event-driven** | Architecture basée sur les événements (Socket.IO) | Pub/Sub |
| **Idempotent** | Opération qui peut être exécutée plusieurs fois sans effet de bord | UUID comme clé |
| **Atomic** | Opération qui s'exécute en entier ou pas du tout | `writeTxn()` Isar |
| **Immutable** | Données qui ne peuvent pas être modifiées après création | `AppState.copyWith()` |
| **Lazy** | Chargement différé des données | `keepAlive: true` Riverpod |
| **Throttle** | Limiter la fréquence d'exécution | Sync toutes les 5 min |
| **Debounce** | Attendre que les événements cessent avant d'exécuter | Reload 30s après dernier événement |
| **Singleton** | Une seule instance d'une classe | `RealtimeService._instance` |
| **Factory** | Pattern de création d'objets | `AuthService()` |
| **Adapter** | Classe qui adapte une interface à une autre | `KasedApp` provider |

## Types de Données

| Type | Description | Usage |
|------|-------------|-------|
| **UUID** | Identifiant unique de 128 bits | Clé métier des entités |
| **DateTime** | Date et heure | Timestamps, dates de culte |
| **double** | Nombre flottant 64 bits | Montants financiers |
| **bool** | Booléen | Flags (isActive, isDeleted) |
| **String** | Chaîne de caractères | Noms, emails, IDs |
| **List\<T\>** | Liste typée | Collections (memberIds) |
| **Map\<K,V\>** | Dictionnaire | Données JSON |

## Erreurs Courantes

| Erreur | Code | Cause | Solution |
|--------|------|-------|----------|
| **403 Security validation failed** | 403 | Audience mismatch entre token Google et EXPECTED_CLIENT_ID | Vérifier `GOOGLE_SERVER_CLIENT_ID` |
| **ApiException: 10** | sign_in_failed | SHA-1 du keystore non enregistré dans Google Cloud Console | Ajouter le SHA-1 dans les credentials OAuth |
| **ACCOUNT_EXISTS_WITH_PASSWORD** | 409 | L'email est déjà utilisé avec un compte email | Demander la connexion email/mot de passe |
| **GOOGLE_BRIDGE_MISSING** | 404 | La fonction `google-auth-bridge` n'existe pas sur InsForge | Déployer la fonction v7 |
| **No token provided** | 401 | Clé API anon manquante ou invalide | Vérifier `INSFORGE_ANON_KEY` |
| **DEVELOPER_ERROR** | 10 | Configuration Google Sign-In incorrecte | Vérifier les secrets CI |
| **GOOGLE_SIGNIN_TIMEOUT** | — | La popup Google ne répond pas après 120s | Vérifier la connexion réseau |
| **GOOGLE_AUTH_CREDENTIALS_TIMEOUT** | — | Récupération des credentials après 30s | Vérifier la connexion réseau |

## Abréviations

| Abréviation | Signification |
|-------------|---------------|
| **BaaS** | Backend-as-a-Service |
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **SDK** | Software Development Kit |
| **JWT** | JSON Web Token |
| **OAuth** | Open Authorization |
| **API** | Application Programming Interface |
| **RPC** | Remote Procedure Call |
| **POST** | POST (HTTP) |
| **GET** | GET (HTTP) |
| **PATCH** | PATCH (HTTP) |
| **DELETE** | DELETE (HTTP) |
| **UUID** | Universally Unique Identifier |
| **DNS** | Domain Name System |
| **TLS** | Transport Layer Security |
| **AES** | Advanced Encryption Standard |
| **SHA** | Secure Hash Algorithm |
| **APK** | Android Package Kit |
| **AAB** | Android App Bundle |

## Voir Aussi

- [Architecture](Architecture) — Vue d'ensemble
- [Data Models](Data-Models) — Schéma des entités
- [API Reference](API-Reference) — Endpoints et constantes
