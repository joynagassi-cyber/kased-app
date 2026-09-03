# Scénarios de déconnexion → onboarding

## Mécanisme de redirection
```dart
// app_router.dart
redirect: (context, state) {
  final auth = ref.read(authProvider);  // ref.read → lecture ponctuelle

  // 1. Si isLoading → forcer /loading (sauf si déjà sur /loading)
  if (auth.isLoading) return loc == '/loading' ? null : '/loading';

  // 2. Si on arrive de /loading
  if (loc == '/loading') {
    if (!auth.isAuthenticated) {
      return AppPrefs.hasSeenOnboarding ? '/login' : '/onboarding';
    }
    return '/dashboard';
  }

  // 3. Si on est sur une route publique
  final isPublic = loc == '/login' || loc == '/signup' || loc == '/onboarding';
  if (!auth.isAuthenticated && !isPublic) return '/onboarding';  // ← PROBLÈME ICI
  if (auth.isAuthenticated && isPublic) return '/dashboard';
  return null;
}
```

---

## Scénario 1 : Changement d'écran avec keepAlive=false
**Status** : ✅ CORRIGÉ (keepAlive=false appliqué)

**Mécanisme** :
- `authProvider` avait `keepAlive: true` → provider détruit à la navigation
- Avec `keepAlive: false` + `AutoDisposeNotifierProvider` → le provider se recrée
- Au recréation, `build()` → `unawaited(_checkPersistedAuth())` → `state = isLoading: true`
- Le router évalue `auth.isLoading == true` → redirect vers `/loading`
- Puis `_checkPersistedAuth()` termine → state mis à jour → redirect vers `/dashboard`

**Impact** : L'utilisateur voit l'écran de chargement brièvement lors de la navigation. Ce n'est pas bloquant mais c'est une expérience utilisateur dégradée.

---

## Scénario 2 : `_checkPersistedAuth` appelé deux fois
**Status** : ⚠️ RISQUE (non corrigé)

**Mécanisme** :
- `build()` du provider appelle `unawaited(_checkPersistedAuth())`
- `didChangeAppLifecycleState(resumed)` appelle `checkPersistedAuth()` qui appelle `_checkPersistedAuth()`
- Deux appels asynchrones peuvent se chevaucher
- Le second peut écraser le premier si le premier n'a pas terminé

**Fix** : Supprimer l'appel dans `didChangeAppLifecycleState` ou utiliser un flag pour éviter le double appel.

---

## Scénario 3 : Secure storage corrompu
**Status** : 🔴 NON CORRIGÉ — Cause racine probable

**Mécanisme** :
- `_checkPersistedAuth()` lit depuis `flutter_secure_storage`
- Si le storage lève une exception (AndroidKeyStore corrompu, hardware change, etc.)
- Le `catch` générique → `state = AuthState(isAuthenticated: false, isLoading: false)`
- Redirect vers `/onboarding`

**Pourquoi c'est critique** :
- L'erreur est silencieuse (juste un `debugPrint`)
- L'utilisateur est déconnecté sans raison apparente
- Impossible de récupérer la session

**Fix** :
```dart
catch (e, stack) {
  debugPrint('[AUTH] Erreur storage: $e');
  // NE PAS déconnecter si on a une erreur de storage
  // Garder l'état actuel ou revenir à isLoading
  state = const AuthState(isLoading: false);
}
```

---

## Scénario 4 : Token refresh échoue
**Status** : ⚠️ RISQUE (comportement actuel)

**Mécanisme** :
- `refreshSession()` est appelé quand le token expire
- Si le refresh échoue pour une raison autre que le réseau (ex: refreshToken invalidé côté serveur)
- `logout()` est appelé → déconnexion → redirect vers `/onboarding`

**Pourquoi c'est problématique** :
- L'utilisateur est déconnecté alors qu'il utilisait l'app normalement
- Le refresh token peut devenir invalide si le serveur le révoque (ex: changement de mot de passe)
- L'utilisateur ne comprend pas pourquoi il est déconnecté

**Fix** :
- Ajouter un log détaillé quand `logout()` est appelé
- Préférer un "silent refresh" qui ne déconnecte pas mais maintient la session
- Option : demander à l'utilisateur de se reconnecter plutôt que de déconnecter silencieusement

---

## Scénario 5 : Navigation vers écran public (login/signup) puis retour
**Status** : ✅ CORRIGÉ (keepAlive=false)

**Mécanisme** :
- User va sur `/login` → `authProvider` destroyé (keepAlive=false)
- User se connecte → `authProvider` recréé → `_checkPersistedAuth()` → `isAuthenticated: true`
- User retourne sur `/dashboard` → redirect fonctionne

**Risque** :
- Si `hasSeenOnboarding` n'est pas persisté (SharedPreferences corrompu) → redirect vers `/onboarding` au lieu de `/login`

---

## Scénario 6 : `logout()` est appelé accidentellement
**Status** : 🔴 NON CORRIGÉ — Cause racine probable

**Mécanisme** :
- `logout()` supprime tout le secure storage + set state à `isLoading: true`
- `_AuthNotifier` notifie le router → redirect vers `/loading`
- `_checkPersistedAuth()` trouve aucun token → `isAuthenticated: false` → redirect vers `/onboarding`

**Quand peut-il être appelé accidentellement ?**
1. `refreshSession()` échoue → `logout()` est appelé
2. `_checkPersistedAuth()` lève une exception → `logout()` n'est pas appelé (mais state set à false)
3. `didChangeAppLifecycleState` → `checkPersistedAuth()` → `_checkPersistedAuth()` lève → `logout()` ? NON, le catch ne call pas logout

**Le scénario le plus probable** :
- `refreshSession()` est appelé (timer toutes les 2 min)
- Le refresh échoue (network error, server error)
- `logout()` est appelé
- Redirect vers `/onboarding`

**Fix** : Ne pas appeler `logout()` dans `refreshSession()` en cas d'erreur. Préférer garder la session locale.

---

## Scénario 7 : `insforge_service` se recrée avec token null
**Status** : ⚠️ RISQUE

**Mécanisme** :
- `insForgeServiceProvider` watch `authProvider`
- Quand `authProvider` change (ex: login), `insForgeServiceProvider` se recrée
- Au premier build, `auth.token` est null (build avant `_checkPersistedAuth()`)
- `InsForgeService` est créé avec `token: null`
- Les requêtes futures échouent avec 401
- `onUnauthorized` est appelé → `refreshSession()` → échec → `logout()`

**Fix** : S'assurer que `insForgeService` attend que `authProvider` soit chargé avant de créer le service.

---

## Résumé des causes probables

| Cause | Probabilité | Correctible par |
|-------|------------|-----------------|
| Token refresh échoue → logout() | 🔴 Haute | Supprimer logout() dans refreshSession() |
| Secure storage corrompu → exception | 🔴 Haute | Catch plus fin, ne pas déconnecter |
| keepAlive=false → rebuild authProvider | 🟡 Moyenne | keepAlive=true ou logique redirect améliorée |
| insforge_service token null | 🟡 Moyenne | Attendre authProvider avant de créer service |
| Double checkPersistedAuth | 🟢 Faible | Supprimer appel dans didChangeAppLifecycleState |

---

## Recommandations prioritaires

1. **🔴 CRITIQUE** : Ne pas appeler `logout()` dans `refreshSession()` en cas d'erreur. Conserver la session locale.
2. **🔴 CRITIQUE** : Le catch dans `_checkPersistedAuth()` ne doit pas déconnecter l'utilisateur. Logger l'erreur et maintenir l'état actuel.
3. **🟡 IMPORTANT** : Remettre `keepAlive: true` pour `authProvider`. Le `keepAlive: false` cause des rebuilds inutiles.
4. **🟡 IMPORTANT** : Supprimer `checkPersistedAuth()` de `didChangeAppLifecycleState`. Le timer de 2 min suffit.
5. **🟢amelioration** : Ajouter un log détaillé dans `logout()` pour tracer quand et pourquoi il est appelé.
