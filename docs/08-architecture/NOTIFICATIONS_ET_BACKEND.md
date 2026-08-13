# Notifications OneSignal & alignement backend InsForge

## 1. Notifications push multi-utilisateurs

Chaîne complète :

```
mutation réussie (app_data_provider)
  → NotificationCoordinator      : notification LOCALE pour l'auteur
  → PushNotifyService.notifier() : POST {baseUrl}/functions/push-notify
        → fonction Deno push-notify
             → liste les emails de `profiles` (tous les comptes)
             → retire l'auteur (il a déjà sa notification locale)
             → OneSignal API : include_aliases.external_id = [emails]
```

L'`external_id` OneSignal est l'email de l'utilisateur, défini par
`OneSignal.login(email)` à la connexion. Le tag `user_email` est également
posé : il sert de ciblage de repli (`filters` par tag) si la table `profiles`
est momentanément illisible, et le dernier repli est le segment
`Total Subscriptions`. Une notification est donc toujours envoyée aux autres
appareils.

### État constaté

- La fonction `push-notify` **n'était pas déployée** (`/functions/push-notify`
  → 404, seul `google-auth-bridge` existait) : aucune notification push n'a
  jamais pu partir. Elle est maintenant déployée et active.
- Sa version précédente listait les utilisateurs via `/api/profiles`
  (endpoint inexistant) et l'ancienne politique RLS ne laissait voir que son
  propre profil : le ciblage aurait de toute façon été vide.
- OneSignal ne compte **aucun abonné** (`players: 0`) : aucun appareil ne
  s'est encore enregistré. Il faut installer un build sur au moins deux
  appareils, accepter la permission de notification et se connecter, pour
  valider la réception de bout en bout.

### Clé REST OneSignal

La clé REST **ne doit jamais** être commitée ni embarquée dans l'app. Elle est
injectée dans le code de la fonction au déploiement :

```bash
INSFORGE_ADMIN_API_KEY=... ONESIGNAL_REST_API_KEY=os_v2_app_... \
  ./scripts/deploy-insforge-functions.sh
```

Attention : une clé **d'organisation** (`os_v2_org_...`) est refusée par
`POST /notifications` (HTTP 401). Il faut la clé **App API Key**
(`os_v2_app_...`) : OneSignal Dashboard → l'app Kased → Settings → Keys & IDs.

## 2. Alignement code ↔ base de données

Anomalies trouvées et corrigées (migration
`db/migrations/20260813_shared_tenant_alignment.sql`) :

| Anomalie | Effet | Correction |
|---|---|---|
| RLS « propriétaire » (`auth.uid() = user_id`) sur `membres`, `cultes`, `cotisations` | chaque utilisateur ne voyait que ses propres lignes, alors que l'app est partagée entre les responsables d'une même église | politiques partagées pour le rôle `authenticated` |
| Vues sans `security_invoker` | les vues agrégaient les lignes de tous les utilisateurs en contournant RLS → dashboard non nul mais listes vides | `security_invoker = true` sur les 5 vues |
| `cultes.user_id` NULL sur la ligne historique | ligne invisible depuis l'app | backfill sur `created_by`/premier compte |
| Aucune ligne dans `profiles` (9 comptes) | impossible de lister les utilisateurs à notifier | trigger `auth.users → profiles` + backfill |
| `profiles_insert_policy` incompatible avec l'upsert du bridge | profil jamais créé à la connexion Google | trigger de remplissage de `user_id` + politiques insert/update/select |
| Index `idx_membres_is_actif` dupliqué, trigger `updated_at` dupliqué | double écriture à chaque UPDATE | doublons supprimés |
| `GET /api/database/records/changes` (delta sync) | table inexistante, erreur avalée silencieusement | code mort supprimé |

### Vérification effectuée sur la base réelle

Avec un compte de test créé puis supprimé (token utilisateur réel, pas la clé
admin) :

- lecture croisée : un nouveau compte voit bien les cultes créés par un autre ;
- `creer_culte_avec_cotisations` → renvoie l'UUID (chaîne JSON) attendu par
  `InsForgeService` ;
- insertion d'un membre → `user_id` rempli automatiquement et cotisation
  générée par trigger pour le culte existant ;
- `toggle_paiement` → `statut: en_avance`, `marquer_absent` → `statut: absent` ;
- `historique_membre` et les 5 vues (`v_dashboard`, `v_resume_culte`,
  `v_retards_membres`, `v_membres_a_jour`, `v_membres_en_avance`) répondent
  avec les colonnes attendues par les modèles Dart.
