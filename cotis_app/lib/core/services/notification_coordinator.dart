import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/core/notifications/notification_service.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/notifications_provider.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coordinateur des notifications locales.
///
/// Centralise tous les appels a [NotificationService] et [NotificationsProvider]
/// pour eviter de les disperser dans le provider ou les services.
class NotificationCoordinator {
  /// Initialisation: charge les notifications depuis prefs au demarrage.
  static Future<void> init(Ref ref) async {
    unawaited(ref.read(notificationsProvider.notifier).chargerDepuisPrefs());
  }

  /// Planifie les notifications d anniversaire pour une liste de membres.
  static void planifierAnniversairesMembres(List<Membre> membres) {
    for (final membre in membres) {
      if (membre.dateNaissance != null) {
        unawaited(NotificationService.planifierAnniversaire(membre));
      }
    }
  }

  /// Planifie ou met a jour la notification d anniversaire d un membre.
  static void planifierAnniversaireMembre(Membre membre) {
    if (membre.dateNaissance != null) {
      unawaited(NotificationService.planifierAnniversaire(membre));
    }
  }

  /// Annule la notification d anniversaire d un membre.
  static void annulerAnniversaireMembre(String membreId) {
    unawaited(NotificationService.annulerAnniversaire(membreId));
  }

  /// Affiche une notification de creation de membre.
  static void notifierCreationMembre(Membre membre) {
    final titre = '${membre.prenom} ${membre.nom} a ete ajoute a la communaute';
    unawaited(NotificationService.showNotification(
      title: 'Gloire a Dieu',
      body: titre,
    ));
    unawaited(NotificationService.showNotification(
      title: 'Nouveau membre',
      body: '${membre.prenom} ${membre.nom} vient d etre ajoute',
      channelId: 'membres',
      channelName: 'Membres',
    ));
    // Ajouter aussi dans le provider in-app
    unawaited(NotificationService.showNotification(
      title: 'Nouveau membre',
      body: '${membre.prenom} ${membre.nom} a rejoint l\'eglise',
      channelId: 'membres',
      channelName: 'Membres',
    ));
  }

  /// Affiche une notification de creation de culte.
  static void notifierCreationCulte(Culte culte) {
    final titreCulte = culte.titre != null ? ' : ${culte.titre}' : '';
    final body = 'Nouveau culte${titreCulte.isNotEmpty ? titreCulte : ''} - ${DateFormat('dd/MM/yyyy').format(culte.dateCulte)}';
    unawaited(NotificationService.showNotification(
      title: 'Gloire a Dieu',
      body: body,
    ));
    unawaited(NotificationService.showNotification(
      title: 'Nouveau culte',
      body: body,
      channelId: 'cultes',
      channelName: 'Cultes',
    ));
  }

  /// Affiche une notification de don enregistre avec le NOM du membre.
  static void notifierDonEnregistre(double montantDon, String membreId, {String? membreNom}) {
    final nomAffichage = membreNom ?? membreId;
    unawaited(NotificationService.showNotification(
      title: 'Don enregistre',
      body: '$nomAffichage a fait un don de ${montantDon.toStringAsFixed(0)} F',
      channelId: 'paiements',
      channelName: 'Paiements',
    ));
  }

  /// Affiche une notification de paiement personnalise avec le NOM du membre.
  static void notifierPaiementPersonnalise(String membreNom, double montant, String culteTitre) {
    unawaited(NotificationService.showNotification(
      title: 'Paiement enregistre',
      body: '$membreNom - ${montant.toStringAsFixed(0)} F pour $culteTitre',
      channelId: 'paiements',
      channelName: 'Paiements',
    ));
  }

  /// Affiche une notification de mise a jour de paiements (bulk).
  static void notifierPaiementsEnMasse(int success, String actionText) {
    if (success > 0) {
      unawaited(NotificationService.showNotification(
        title: 'Gloire a Dieu',
        body: '$success paiement(s) $actionText',
        channelId: 'paiements',
        channelName: 'Paiements',
      ));
    }
  }

  /// Affiche une notification de paiement par avance.
  static void notifierPaiementAvance(double montant, String membreNom) {
    unawaited(NotificationService.showNotification(
      title: 'Gloire a Dieu',
      body: '$membreNom a paye ${montant.toStringAsFixed(0)} F en avance',
      channelId: 'paiements',
      channelName: 'Paiements',
    ));
  }

  /// Récupère le nom complet d un membre a partir de l etat global.
  static String getMembreNom(AppState state, String membreId) {
    final membre = state.membres.firstWhere(
      (m) => m.id == membreId,
      orElse: () => Membre()..nom = membreId,
    );
    return membre.nomComplet;
  }
}
