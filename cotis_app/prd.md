# 📝 Product Requirement Document - Kased App

## 🎯 Objectif du Produit
Gérer les cotisations des membres d'une église en automatisant le suivi des paiements, cultes et membres.

## 👥 Utilisateurs
- Secrétaire de l'église (administrateur des données)

## 🔹 Fonctionnalités Principales (FR)

### FR1 - Authentification
**FR1.1 :** Authentifier les utilisateurs via Google Sign-In.
**FR1.2 :** Vérifier les autorisations via RLS (Row Level Security) dans PostgreSQL.

### FR2 - Gestion des Membres
**FR2.1 :** Créer un nouveau membre avec prénom, nom, date d'adhésion, date de naissance, téléphone.
**FR2.2 :** Lister tous les membres.
**FR2.3 :** Modifier un membre existant.
**FR2.4 :** Supprimer un membre (cascade sur cotisations).
**FR2.5 :** Marquer un membre comme inactif.

### FR3 - Gestion des Cultes
**FR3.1 :** Créer un culte avec date, titre, montant, notes.
**FR3.2 :** Créer automatiquement les cotisations pour tous les membres actifs lors de la création d'un culte.
**FR3.3 :** Lister les cultes.
**FR3.4 :** Mettre à jour un culte.
**FR3.5 :** Supprimer un culte (cascade sur cotisations).

### FR4 - Gestion des Cotisations
**FR4.1 :** Visualiser les cotisations par culte et membre.
**FR4.2 :** Basculer le statut d'une cotisation (paye/non_paye/en_avance/absent).
**FR4.3 :** Marquer explicitement un membre comme absent pour un culte.
**FR4.4 :** Historique complet des modifications pour un membre.

### FR5 - Tableau de Bord
**FR5.1 :** Afficher le nombre total de membres actifs.
**FR5.2 :** Afficher le nombre total de cultes planifiés.
**FR5.3 :** Afficher les membres en retard de paiement.
**FR5.4 :** Afficher le total dû en FCFA.
**FR5.5 :** Afficher les membres à jour.
**FR5.6 :** Afficher les paiements anticipés.

### FR6 - Rapport PDF
**FR6.1 :** Générer un rapport PDF des cotisations.

### FR7 - Notifications
**FR7.1 :** Envoyer des notifications locales pour rappels de paiement.

### FR8 - Stockage Local
**FR8.1 :** Mettre en cache les données via Isar Database.
**FR8.2 :** Fonctionner en mode hors-ligne avec synchronisation quand reconnecté.

### FR9 - Design UI
**FR9.1 :** Interface responsive (mobile + desktop).
**FR9.2 :** Animations fluides aux transitions.
**FR9.3 :** Thème cohérent avec palette de couleurs définie (#1246C8, etc.).

### FR10 - Sécurité
**FR10.1 :** Chiffrement des données sensibles.
**FR10.2 :** Authentification obligée pour toutes les routes.
**FR10.3 :** Validation des données côté serveur (PostgreSQL RLS).

## 🔸 Non-Fonctionnelles (NFR)

**NFR1 (Performance) :** Temps de réponse inférieur à 500ms pour les requêtes API.

**NFR2 (Fiabilité) :** Application stable avec taux d'erreur < 1%.

**NFR3 (Sécurité) :** Respect des best practices OAuth 2.0 et RLS.

**NFR4 (Maintenabilité) :** Code structuré avec séparation claire entre couches (UI, Services, Modèles).

**NFR5 (Tests) :** Couverture de tests unitaires > 80% sur la logique métier.

**NFR6 (Compatibilité) :** Support Android API 24+.

---

## 🏗️ Contraintes Techniques

- Backend : InsForge + PostgreSQL + PostgREST
- Frontend : Flutter 3.x, Riverpod, Isar
- Authentification : Google OAuth 2.0
- Hébergement : InsForge (BaaS)

---

## 📜 Version & Date

**Version :** 1.0  
**Date :** 3 mai 2026  
**Statut :** Référentiel basé sur ARCHITECTURE.md