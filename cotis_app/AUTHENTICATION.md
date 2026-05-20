# 🔐 SYSTÈME D'AUTHENTIFICATION - KASED APP

## Vue d'ensemble

L'application Kased utilise **Google Sign-In** pour l'authentification des utilisateurs. Le système est configuré avec :
- ✅ Page de **Signup** (inscription)
- ✅ Page de **Login** (connexion)
- ✅ Protection des routes
- ✅ Gestion du token JWT
- ✅ Bouton de déconnexion

---

## Architecture

### 1. Service d'authentification (`auth_service.dart`)
- Gère la connexion avec Google Sign-In
- Communique avec le backend pour vérifier le token
- Stocke l'état de connexion

### 2. Provider d'authentification (`auth_provider.dart`)
- Gère l'état global d'authentification
- Stocke le token JWT de manière sécurisée avec `flutter_secure_storage`
- Expose les méthodes `signIn()` et `signOut()`

### 3. Router protégé (`app_router.dart`)
- Route initiale : `/login`
- Redirection automatique :
  - Non authentifié → `/login`
  - Authentifié sur `/login` ou `/signup` → `/dashboard`
- Toutes les routes principales sont protégées

---

## Flux d'authentification

### Inscription (Signup)
1. L'utilisateur clique sur "S'inscrire avec Google"
2. Google Sign-In s'ouvre (écran natif)
3. L'utilisateur sélectionne son compte Google
4. Le token ID est envoyé au backend
5. Le backend crée un compte et retourne un JWT
6. Le JWT est stocké localement
7. Redirection vers `/dashboard`

### Connexion (Login)
1. L'utilisateur clique sur "Se connecter avec Google"
2. Google Sign-In s'ouvre
3. L'utilisateur sélectionne son compte
4. Le token ID est envoyé au backend
5. Le backend vérifie et retourne un JWT
6. Le JWT est stocké localement
7. Redirection vers `/dashboard`

### Déconnexion
1. L'utilisateur clique sur l'icône de déconnexion
2. Confirmation via dialogue
3. Suppression du token local
4. Déconnexion de Google Sign-In
5. Redirection vers `/login`

---

## Configuration requise

### Backend (InsForge)
Le backend doit exposer un endpoint `/auth/google/login` qui :
- Accepte un `idToken` Google
- Vérifie le token avec l'API Google
- Crée ou récupère l'utilisateur
- Retourne un JWT avec les informations utilisateur

**Exemple de réponse attendue :**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "email": "user@example.com",
  "name": "John Doe"
}
```

### Configuration Google OAuth
- **Client ID** : `535496831713-4ol3svlekn919034dp509bbi6i9j0ndo.apps.googleusercontent.com`
- **Fichiers de configuration** :
  - `android/app/google-services.json` (Firebase)
  - `android/app/client_secret_*.json` (OAuth)

---

## Utilisation dans le code

### Vérifier l'état d'authentification
```dart
final authState = ref.watch(authProvider);

if (authState.value?.isAuthenticated ?? false) {
  // Utilisateur connecté
  final email = authState.value?.userEmail;
  final name = authState.value?.userName;
}
```

### Se connecter
```dart
await ref.read(authProvider.notifier).signIn();
```

### Se déconnecter
```dart
await ref.read(authProvider.notifier).signOut();
```

---

## Sécurité

### Stockage sécurisé
- Le token JWT est stocké avec `flutter_secure_storage`
- Les données sont chiffrées sur l'appareil
- Suppression automatique à la déconnexion

### Protection des routes
- Toutes les routes principales nécessitent une authentification
- Redirection automatique vers `/login` si non authentifié
- Vérification de l'état à chaque navigation

### Token JWT
- Stocké localement après connexion
- Envoyé dans les headers des requêtes API
- Vérifié côté backend pour chaque requête

---

## Pages d'authentification

### Page de Signup (`signup_screen.dart`)
- Design moderne avec icône de l'église
- Bouton "S'inscrire avec Google"
- Lien vers la page de login
- Note de sécurité

### Page de Login (`login_screen.dart`)
- Design cohérent avec la page de signup
- Bouton "Se connecter avec Google"
- Lien vers la page de signup
- Note de sécurité

---

## Tests

### Tester l'authentification
1. Lancer l'app : `flutter run`
2. Vérifier que l'app démarre sur `/login`
3. Cliquer sur "S'inscrire avec Google"
4. Sélectionner un compte Google
5. Vérifier la redirection vers `/dashboard`
6. Cliquer sur l'icône de déconnexion
7. Vérifier la redirection vers `/login`

### Tester la protection des routes
1. Se déconnecter
2. Essayer d'accéder à `/dashboard` directement
3. Vérifier la redirection vers `/login`

---

## Dépannage

### Erreur "Erreur de connexion"
- Vérifier que le backend est accessible
- Vérifier que l'endpoint `/auth/google/login` existe
- Vérifier les logs du backend

### Erreur "PlatformException"
- Vérifier que `google-services.json` est présent
- Vérifier que le Client ID est correct
- Vérifier que l'app est enregistrée dans Google Cloud Console

### Redirection infinie
- Vérifier que le token est bien stocké
- Vérifier la logique de redirection dans `app_router.dart`
- Vérifier que `isAuthenticated` est correctement mis à jour

---

## Prochaines étapes

### Améliorations possibles
- [ ] Ajouter un écran de chargement pendant l'authentification
- [ ] Ajouter la gestion des erreurs réseau
- [ ] Ajouter un refresh token automatique
- [ ] Ajouter la possibilité de se connecter avec email/mot de passe
- [ ] Ajouter la réinitialisation du mot de passe
- [ ] Ajouter la vérification de l'email

---

## Support

Pour toute question ou problème, consultez :
- Documentation Google Sign-In : https://pub.dev/packages/google_sign_in
- Documentation Riverpod : https://riverpod.dev
- Documentation GoRouter : https://pub.dev/packages/go_router
