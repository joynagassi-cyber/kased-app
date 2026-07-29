# 🏆 Epic : Authentification & Sécurité

## Description
Mettre en place l'authentification Google Secure et la sécurité RLS dans PostgreSQL.

## User Stories
- [ ] SE-1 : Implémenter Google Sign-In avec auth_provider.dart
- [ ] SE-2 : Configurer l'authentification dans le Flutter Router
- [ ] SE-3 : Implémenter les politiques RLS dans PostgreSQL
- [ ] SE-4 : Tester les sécurité des accès par utilisateur

## Critères d'Acceptation
- [x] Connexion Google fonctionne
- [x] Redirection vers dashboard après login
- [x] RLS bloque l'accès aux données non autorisées
- [x] Logout fonctionne correctement

---

# 🏆 Epic : Gestion des Membres

## Description
Permet au secrétaire de gérer la base de données des membres de l'église.

## User Stories
- [ ] GM-1 : Écran de liste des membres
- [ ] GM-2 : Formulaire de création de membre
- [ ] GM-3 : Modal de modification de membre
- [ ] GM-4 : Confirmation de suppression de membre
- [ ] GM-5 : Affichage des détails d'un membre

## Critères d'Acceptation
- [x] Lister les membres paginés
- [x] Créer un membre avec toutes les champs requis
- [x] Membre sauvegardé dans Isar et PostgreSQL
- [x] Suppression en cascade des cotisations
- [x] Recherche et filtrage des membres

---

# 🏆 Epic : Gestion des Cultes et Cotisations

## Description
Gérer les cultes hebdomadaires et les cotisations associées.

## User Stories
- [ ] GC-1 : Créer un culte avec cotisations automatiques
- [ ] GC-2 : Lister les cultes
- [ ] GC-3 : Basculer le statut d'une cotisation (paye/non_paye)
- [ ] GC-4 : Marquer un membre comme absent
- [ ] GC-5 : Visualiser l'historique d'un membre

## Critères d'Acceptation
- [x] Création de culte + génération auto des cotisations
- [x] Vue par culte avec tableau des cotisations
- [x] Toggle Paiement fonctionne (avec logique en_avance/non_paye)
- [x] Marquer Absent met à jour le statut
- [x] Historique complet accessible

---

# 🏆 Epic : Tableau de Bord & Statistiques

## Description
Afficher les statistiques clés de l'église en temps réel.

## User Stories
- [ ] TD-1 : Vue dashboard avec statistiques globales
- [ ] TD-2 : Tableau des retards de paiement
- [ ] TD-3 : Graphiques de visualization (à implémenter)
- [ ] TD-4 : Membre à jour et en avance

## Critères d'Acceptation
- [x] Affichage du nombre total de membres actifs
- [x] Nombre total de cultes
- [x] Membres en retard calculé via vue SQL
- [x] Total dû en FCFA
- [x] Membre à jour et paiements anticipés

---

# 🏆 Epic : Export PDF & Notifications

## Description
Génération de rapports et notifications rappels.

## User Stories
- [ ] PN-1 : PDF des cotisations par culte
- [ ] PN-2 : Notification locale pour rappel paiement

## Critères d'Acceptation
- [ ] PDF généré avec PdfService
- [ ] Notifications configurées avec flutter_local_notifications

---

# 🏆 Epic : Stockage Local & Hors-Ligne

## Description
Mise en cache des données pour le hors-ligne.

## User Stories
- [ ] SL-1 : Initialisation de la base Isar
- [ ] SL-2 : Synchronisation Online/Offline
- [ ] SL-3 : Rafraîchissement des données à la reconnect

## Critères d'Acceptation
- [x] IsarProvider initialise la base
- [x] Les données sont sauvegardées localement
- [x] L'app charge en mode offline si possible
