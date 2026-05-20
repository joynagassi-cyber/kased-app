# ✅ TODO - AUTHENTIFICATION KASED APP

## 🎯 ÉTAPES COMPLÉTÉES

- [x] Créer la page de Signup
- [x] Améliorer la page de Login
- [x] Créer le provider d'authentification
- [x] Protéger les routes dans le router
- [x] Ajouter le bouton de déconnexion
- [x] Générer les fichiers Riverpod
- [x] Créer la documentation

---

## 🚀 PROCHAINES ÉTAPES (PAR PRIORITÉ)

### 1. Configuration Backend InsForge (CRITIQUE)

#### 1.1 Créer l'endpoint d'authentification
- [ ] Créer `/auth/google/login` dans le backend InsForge
- [ ] Implémenter la vérification du token Google
- [ ] Créer ou récupérer l'utilisateur dans la base de données
- [ ] Générer et retourner un JWT

**Code backend exemple (Node.js/Express) :**
```javascript
app.post('/auth/google/login', async (req, res) => {
  try {
    const { idToken } = req.body;
    
    // Vérifier le token avec Google
    const ticket = await client.verifyIdToken({
      idToken,
      audience: CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    const { email, name, sub: googleId } = payload;
    
    // Créer ou récupérer l'utilisateur
    let user = await db.users.findOne({ email });
    if (!user) {
      user = await db.users.create({ email, name, googleId });
    }
    
    // Générer un JWT
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.json({ token, email, name });
  } catch (error) {
    res.status(401).json({ error: 'Authentication failed' });
  }
});
```

#### 1.2 Mettre à jour l'URL du backend
- [ ] Ouvrir `lib/services/auth_service.dart`
- [ ] Changer `baseUrl` de `http://10.0.2.2:3000` à `https://pu74z8pe.us-east.insforge.app`
- [ ] Tester la connexion au backend

#### 1.3 Ajouter la vérification du JWT
- [ ] Créer un middleware pour vérifier le JWT
- [ ] Protéger les endpoints de l'API
- [ ] Tester avec Postman ou curl

---

### 2. Tests de l'authentification (IMPORTANT)

#### 2.1 Tests manuels
- [ ] Lancer l'app : `flutter run`
- [ ] Vérifier que l'app démarre sur `/login`
- [ ] Tester le signup avec un compte Google
- [ ] Vérifier la redirection vers `/dashboard`
- [ ] Vérifier que l'email s'affiche dans l'AppBar
- [ ] Tester la navigation entre les pages
- [ ] Tester le bouton de déconnexion
- [ ] Vérifier la redirection vers `/login` après déconnexion
- [ ] Essayer d'accéder à `/dashboard` sans être connecté
- [ ] Vérifier la redirection automatique vers `/login`

#### 2.2 Tests de persistance
- [ ] Se connecter
- [ ] Fermer l'app
- [ ] Rouvrir l'app
- [ ] Vérifier que l'utilisateur est toujours connecté

#### 2.3 Tests d'erreurs
- [ ] Tester avec une connexion internet coupée
- [ ] Tester avec un backend inaccessible
- [ ] Vérifier que les messages d'erreur sont clairs

---

### 3. Améliorations UI/UX (OPTIONNEL)

#### 3.1 Écran de chargement
- [ ] Créer un splash screen pendant la vérification de l'authentification
- [ ] Ajouter un indicateur de chargement pendant la connexion

#### 3.2 Gestion des erreurs
- [ ] Améliorer les messages d'erreur
- [ ] Ajouter un écran d'erreur dédié
- [ ] Ajouter un retry automatique

#### 3.3 Animations
- [ ] Ajouter des transitions entre les pages
- [ ] Ajouter des animations de chargement

---

### 4. Build et déploiement (CRITIQUE)

#### 4.1 Build APK
- [ ] Nettoyer le projet : `flutter clean`
- [ ] Installer les dépendances : `flutter pub get`
- [ ] Builder l'APK : `flutter build apk --release`
- [ ] Vérifier la taille de l'APK

#### 4.2 Tests sur appareil réel
- [ ] Installer l'APK sur un appareil Android
- [ ] Tester toutes les fonctionnalités
- [ ] Vérifier les performances
- [ ] Vérifier la consommation de batterie

#### 4.3 Préparation pour Google Play (si nécessaire)
- [ ] Créer un keystore pour signer l'APK
- [ ] Configurer le signing dans `android/app/build.gradle`
- [ ] Builder un App Bundle : `flutter build appbundle --release`
- [ ] Préparer les assets (icône, screenshots, description)

---

### 5. Documentation et formation (IMPORTANT)

#### 5.1 Documentation utilisateur
- [ ] Créer un guide utilisateur pour le secrétaire
- [ ] Documenter les 3 actions principales :
  - Créer un culte
  - Ajouter un membre
  - Marquer les paiements

#### 5.2 Formation du secrétaire
- [ ] Organiser une session de formation
- [ ] Montrer comment se connecter
- [ ] Montrer comment utiliser l'application
- [ ] Répondre aux questions

---

### 6. Sécurité et optimisation (OPTIONNEL)

#### 6.1 Sécurité
- [ ] Ajouter un refresh token pour renouveler le JWT
- [ ] Implémenter la révocation de token
- [ ] Ajouter une limite de tentatives de connexion
- [ ] Ajouter une vérification de l'email (si nécessaire)

#### 6.2 Optimisation
- [ ] Optimiser les images et assets
- [ ] Réduire la taille de l'APK
- [ ] Améliorer les performances de chargement
- [ ] Ajouter un cache pour les données

---

### 7. Monitoring et analytics (OPTIONNEL)

#### 7.1 Monitoring
- [ ] Ajouter Firebase Crashlytics pour les crashs
- [ ] Ajouter Firebase Analytics pour les événements
- [ ] Configurer les alertes

#### 7.2 Analytics
- [ ] Tracker les connexions
- [ ] Tracker les actions principales
- [ ] Analyser l'utilisation de l'app

---

## 📝 NOTES

### Priorités
1. **CRITIQUE** : Configuration backend et tests
2. **IMPORTANT** : Build APK et formation
3. **OPTIONNEL** : Améliorations UI/UX et optimisations

### Temps estimé
- Configuration backend : 2-3 heures
- Tests : 1-2 heures
- Build et déploiement : 1 heure
- Formation : 30 minutes
- **Total : 4-6 heures**

### Dépendances
- Backend InsForge doit être accessible
- Compte Google Cloud Console configuré
- Appareil Android pour les tests

---

## 🎯 OBJECTIF FINAL

Avoir une application Kased **prête pour la production** avec :
- ✅ Authentification Google fonctionnelle
- ✅ Protection des routes
- ✅ Gestion de session
- ✅ APK signé et testé
- ✅ Secrétaire formé

**Date cible :** [À définir]
