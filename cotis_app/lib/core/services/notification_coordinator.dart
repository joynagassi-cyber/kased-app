import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/core/notifications/notification_service.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';

/// Coordinateur des notifications locales.
///
/// Centralise tous les appels à [NotificationService] pour éviter
/// de les disperser dans le provider ou les services.
class NotificationCoordinator {
  /// Planifie les notifications d'anniversaire pour une liste de membres.
  static void planifierAnniversairesMembres(List<Membre> membres) {
    for (final membre in membres) {
      if (membre.dateNaissance != null) {
        unawaited(NotificationService.planifierAnniversaire(membre));
      }
    }
  }

  /// Planifie ou met à jour la notification d'anniversaire d'un membre.
  static void planifierAnniversaireMembre(Membre membre) {
    if (membre.dateNaissance != null) {
      unawaited(NotificationService.planifierAnniversaire(membre));
    }
  }

  /// Annule la notification d'anniversaire d'un membre.
  static void annulerAnniversaireMembre(String membreId) {
    unawaited(NotificationService.annulerAnniversaire(membreId));
  }

  /// Affiche une notification de création de membre.
  static void notifierCreationMembre(Membre membre) {
    unawaited(NotificationService.showNotification(
      title: 'Nouveau membre ajouté',
      body: '${membre.prenom} ${membre.nom} a été ajouté',
    ));
  }

  /// Affiche une notification de création de culte.
  static void notifierCreationCulte(Culte culte) {
    final titreCulte = culte.titre != null ? ' : ${culte.titre}' : '';
    unawaited(NotificationService.showNotification(
      title: 'Nouveau culte${titreCulte.isNotEmpty ? titreCulte : ''}',
      body: 'Culte du ${DateFormat('dd/MM/yyyy').format(culte.dateCulte)} ajouté',
    ));
  }

  /// Affiche une notification de don enregistré.
  static void notifierDonEnregistre(double montantDon, String membreId) {
    unawaited(NotificationService.showNotification(
      title: 'Don enregistré',
      body:
          'Un don de ${montantDon.toStringAsFixed(0)}F a été enregistré pour le membre $membreId.',
    ));
  }

  /// Affiche une notification de mise à jour de paiements (bulk).
  static void notifierPaiementsEnMasse(int success, String actionText) {
    if (success > 0) {
      unawaited(NotificationService.showNotification(
        title: 'Paiements mis à jour',
        body: '$success paiement(s) $actionText',
      ));
    }
  }
}
