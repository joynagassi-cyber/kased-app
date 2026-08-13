# 📲 KASED — Déploiement des notifications push multi-utilisateurs (OneSignal)

> **Objectif** : quand un utilisateur crée/modifie/supprime un **membre**, une
> **cotisation** ou un **culte**, tous les **autres** utilisateurs de l'app
> reçoivent une notification push sur leur téléphone — même si l'app est
> fermée (push hors ligne).

## 🏗️ Architecture

```
App Flutter (téléphone A)                    InsForge (serveur)              OneSignal (cloud)
────────────────────────────                ──────────────────              ────────────────
Action : ajout d'un membre
   │
   ├─ 1. Sauvegarde locale (Isar) + sync InsForge (PostgreSQL)
   │
   └─ 2. Appelle la fonction "push-notify" (fire-and-forget)  ──►  3. Liste les
         { event, actorEmail, entityLabel }                         utilisateurs
         + headers apikey / Bearer token                            (table profiles)
                                                                        │
                                                             4. Exclut l'acteur
                                                                        │
                                                             5. Envoi REST OneSignal
                                                              include_aliases.external_id
                                                                        │
                                                             ┌──────────┴───────────┐
                                                             ▼                     ▼
                                                     Téléphone B (notifié)   Téléphone C (notifié)
```

- **External ID OneSignal = email de l'utilisateur** (défini par
  `OneSignal.login(email)` dans l'app, déjà câblé dans `auth_provider.dart`).
- Chaque appareil s'abonne à OneSignal une seule fois (SDK `onesignal_flutter`
  5.5.2, déjà intégré + dialogue de vérification).
- La fonction serveur détient la **clé REST OneSignal** (secret) — jamais dans l'app.

## 📁 Fichiers de cette fonctionnalité

| Fichier | Rôle |
|---|---|
| `cotis_app/functions/push-notify.js` | **Fonction serveur InsForge** (à déployer) |
| `cotis_app/lib/core/services/push_notify_service.dart` | Service Dart : appel fire-and-forget de la fonction |
| `cotis_app/lib/core/insforge/insforge_config.dart` | `functionsBaseUrl` ajouté |
| `cotis_app/lib/providers/app_data_provider.dart` | 7 points de déclenchement (membre, cotisation, culte) |
| `prompt_files/ONESIGNAL_PUSH_DEPLOY.md` | Ce document |

## ⚠️ PRÉREQUIS (1 minute) — Récupérer la clé REST OneSignal

1. Ouvrir le dashboard OneSignal → **Settings** (⚙️ en bas à gauche) → **Keys & IDs**.
2. Copier la **REST API Key** (celle commençant par `os_v1_...` ou `N2...`).
   - L'**App ID** (`cd2949d4-8ab7-4ad0-8c32-e5599e1a9bd3`) est déjà dans le code (public, pas un secret).
3. La clé REST est un **secret** : elle ne doit JAMAIS être embarquée dans l'app
   ni committée dans le dépôt — elle sera stockée dans la variable
   d'environnement de la fonction InsForge.

## 🚀 Déploiement de la fonction (console InsForge)

1. Ouvrir le dashboard InsForge du projet (base URL : `https://pu74z8pe.us-east.insforge.app`).
2. Menu **Functions** → **Créer une fonction**.
3. Nom de la fonction : **`push-notify`** (exactement — c'est l'URL appelée par l'app).
4. Coller le contenu de `cotis_app/functions/push-notify.js`.
5. **Variables d'environnement** de la fonction :
   | Variable | Valeur | Secret ? |
   |---|---|---|
   | `ONESIGNAL_REST_API_KEY` | `<votre clé REST OneSignal>` | ✅ OUI |
   | `ONESIGNAL_APP_ID` | `cd2949d4-8ab7-4ad0-8c32-e5599e1a9bd3` | Non (optionnel, défaut déjà dans le code) |
6. **Déployer**.

> ℹ️ La fonction est écrite en JavaScript standard (style Web Fetch API,
> compatible Deno/Node) — même format que `google-auth-bridge.js`.
> Si votre plateforme de fonctions InsForge utilise un autre format
> (ex. `export default`), adapter uniquement la ligne
> `module.exports = async function (request)`.

## 🧪 Tests de validation (curl)

Après déploiement, remplacer `<ANON_KEY>`, `<TOKEN>` et `<REST_KEY>` par les vraies valeurs.

### Test 1 — La fonction répond (sans envoyer)
```bash
curl -X POST "https://pu74z8pe.function2.insforge.app/push-notify" \
  -H "Content-Type: application/json" \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"event":"membre_ajoute","actorEmail":"moi@exemple.com","entityLabel":"Test"}'
```
Réponse attendue : soit `{"sent":true,"recipients":N,...}` (si d'autres
utilisateurs existent), soit `{"sent":false,"reason":"no_recipients",...}`.

### Test 2 — Envoi réel sur 2 appareils
1. Installer l'app sur **2 téléphones** (2 comptes différents), accepter la
   permission OneSignal (dialogue « Got it »).
2. Vérifier dans OneSignal → **Audience → Subscriptions** que les 2 appareils
   apparaissent avec leur email.
3. Sur le téléphone A : créer un membre.
4. Sur le téléphone B (app fermée ou en arrière-plan) : la notification
   « Nouveau membre — [A] a ajouté [Prénom NOM] » doit apparaître.
5. L'utilisateur A ne reçoit **pas** sa propre notification.

### Test 3 — Erreurs à connaître
- `{"error":"ONESIGNAL_REST_API_KEY non configurée..."}` → la variable d'env de la fonction n'est pas définie.
- `{"error":"Échec de la récupération des utilisateurs"...}` → la table `profiles` n'est pas lisible avec le token (voir dépannage).
- Réponse OneSignal `{"errors":["..."]}` → vérifier la clé REST et l'App ID.

## 🔔 Événements déclenchés (messages automatiques, en français)

| Action dans l'app | Événement | Notification reçue par les autres |
|---|---|---|
| Ajout d'un membre | `membre_ajoute` | « [Acteur] a ajouté [Prénom NOM] » |
| Modification d'un membre | `membre_modifie` | « [Acteur] a modifié [Prénom NOM] » |
| Suppression d'un membre | `membre_supprime` | « [Acteur] a supprimé [Prénom NOM] » |
| Paiement/cotisation enregistré | `cotisation_payee` | « [Acteur] a enregistré la cotisation de [Prénom NOM] — culte du JJ/MM/AAAA » |
| Paiement modifié | `cotisation_modifiee` | « [Acteur] a modifié la cotisation de [...] » |
| Membre marqué absent | `cotisation_absente` | « [Acteur] a marqué [Prénom NOM] absent » |
| Paiements en masse (bulk) | `cotisations_bulk` | « [Acteur] a marqué N paiement(s) payé(s)/annulé(s) » |
| Création d'un culte | `culte_cree` | « [Acteur] a créé le culte du JJ/MM/AAAA » |

L'événement est aussi transmis dans le payload `data` de la notification
(`data.event`, `data.entityLabel`) pour permettre à l'app d'ouvrir l'écran
concerné au tap.

## 🛠️ Dépannage

- **Aucune notification reçue** :
  1. Vérifier que les appareils sont dans OneSignal (Audience → Subscriptions).
  2. Vérifier que les emails correspondent exactement entre l'app et les profils.
  3. Tester la fonction avec curl (Test 1) — regarder `recipients`.
  4. Vérifier les logs de la fonction InsForge (`console.log` de push-notify).
- **`profiles` illisible** : si la table `profiles` n'existe pas ou est protégée
  par RLS, la fonction ne peut pas lister les destinataires. Deux options :
  - Créer la table (le bridge Google l'utilise déjà : `INSERT INTO profiles (id, email)`),
  - ou autoriser les utilisateurs authentifiés à lire `profiles` (RLS : `USING (auth.uid() IS NOT NULL)`).
- **Push reçu sur le mauvais téléphone** : l'email de connexion doit être le
  même que celui utilisé au login OneSignal — vérifier `OneSignal.login(email)`
  dans `auth_provider.dart` (`setAuthenticated`).
- **Notifications locales (anniversaires) vs push** : les anniversaires restent
  des notifications locales planifiées sur chaque appareil — inchangées.

## ✅ Critères d'acceptation

- [ ] Fonction `push-notify` déployée sur InsForge avec `ONESIGNAL_REST_API_KEY`.
- [ ] 2 appareils avec 2 comptes différents visibles dans OneSignal.
- [ ] Création d'un membre sur l'appareil A → notification sur l'appareil B (app fermée).
- [ ] L'acteur ne reçoit pas sa propre notification.
- [ ] Chaque type d'action (membre, cotisation, culte) notifie automatiquement.
