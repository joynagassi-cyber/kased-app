import 'dart:async';

import 'package:intl/intl.dart';
import 'package:kased_app/core/notifications/notification_service.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';

/// Coordinateur des notifications locales et in-app.
///
/// Centralise tous les appels a [NotificationService] pour eviter de les
/// disperser dans les providers et controllers.
///
/// Les methodes sont statiques pour etre utilisees depuis les controllers
/// (qui n'ont pas acces a un provider Riverpod). Pour les notifications
/// in-app, le provider AppData cree une instance avec un callback.
class NotificationCoordinator {
  final void Function({
    required String titre,
    required String message,
    required String typeEvenement,
    String? entiteId,
  })? onInAppNotify;

  NotificationCoordinator({this.onInAppNotify});

  // ─── Static methods for controllers ────────────────────────────────────────

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

  /// Affiche une notification de creation de membre (systeme uniquement).
  static void notifierCreationMembre(Membre membre) {
    final nomComplet = '${membre.prenom} ${membre.nom}';
    _showSystem(
      title: 'Nouveau membre',
      body: '$nomComplet a rejoint l\'eglise',
      channelId: 'membres',
      channelName: 'Membres',
    );
  }

  /// Affiche une notification de creation de culte (systeme uniquement).
  static void notifierCreationCulte(Culte culte) {
    final titreCulte = culte.titre != null ? ' : ${culte.titre}' : '';
    final body = 'Nouveau culte${titreCulte.isNotEmpty ? titreCulte : ''} - ${DateFormat('dd/MM/yyyy').format(culte.dateCulte)}';
    _showSystem(
      title: 'Nouveau culte',
      body: body,
      channelId: 'cultes',
      channelName: 'Cultes',
    );
  }

  /// Affiche une notification de don enregistre (systeme uniquement).
  static void notifierDonEnregistre(double montantDon, String membreNom) {
    _showSystem(
      title: 'Don enregistre',
      body: '$membreNom a fait un don de ${montantDon.toStringAsFixed(0)} F',
      channelId: 'paiements',
      channelName: 'Paiements',
    );
  }

  /// Affiche une notification de paiement par avance (systeme uniquement).
  static void notifierPaiementAvance(double montant, String membreNom) {
    _showSystem(
      title: 'Paiement en avance',
      body: '$membreNom a paye ${montant.toStringAsFixed(0)} F en avance',
      channelId: 'paiements',
      channelName: 'Paiements',
    );
  }

  /// Affiche une notification de mise a jour de paiements (bulk).
  static void notifierPaiementsEnMasse(int success, String actionText) {
    if (success > 0) {
      _showSystem(
        title: 'Paiements mis a jour',
        body: '$success paiement(s) $actionText',
        channelId: 'paiements',
        channelName: 'Paiements',
      );
    }
  }

  /// Affiche une notification de modification de membre (systeme uniquement).
  static void notifierModificationMembre(Membre membre) {
    final nomComplet = '${membre.prenom} ${membre.nom}';
    _showSystem(
      title: 'Membre modifie',
      body: '$nomComplet a ete modifie',
      channelId: 'membres',
      channelName: 'Membres',
    );
  }

  /// Affiche une notification de suppression de membre (systeme uniquement).
  static void notifierSuppressionMembre(Membre membre) {
    final nomComplet = '${membre.prenom} ${membre.nom}';
    _showSystem(
      title: 'Membre supprime',
      body: '$nomComplet a ete supprime',
      channelId: 'membres',
      channelName: 'Membres',
    );
  }

  /// Affiche une notification de modification de culte (systeme uniquement).
  static void notifierModificationCulte(Culte culte) {
    final titreCulte = culte.titre != null ? ' : ${culte.titre}' : '';
    final body = 'Culte${titreCulte.isNotEmpty ? titreCulte : ''} modifie - ${DateFormat('dd/MM/yyyy').format(culte.dateCulte)}';
    _showSystem(
      title: 'Culte modifie',
      body: body,
      channelId: 'cultes',
      channelName: 'Cultes',
    );
  }

  /// Affiche une notification de paiement enregistre (systeme uniquement).
  static void notifierPaiementEnregistre(double montant, String membreNom, String culteTitre) {
    final body = '$membreNom a paye ${montant.toStringAsFixed(0)} F pour le culte $culteTitre';
    _showSystem(
      title: 'Paiement enregistre',
      body: body,
      channelId: 'paiements',
      channelName: 'Paiements',
    );
  }

  /// Affiche une notification d'absence marquee (systeme uniquement).
  static void notifierAbsentMarque(String membreNom, String culteTitre) {
    final body = '$membreNom a ete marque absent pour le culte $culteTitre';
    _showSystem(
      title: 'Absence marquee',
      body: body,
      channelId: 'paiements',
      channelName: 'Paiements',
    );
  }

  /// Affiche une notification de modification de cotisation (systeme uniquement).
  static void notifierModificationCotisation(String membreNom, String action) {
    _showSystem(
      title: 'Cotisation modifiee',
      body: '$membreNom : $action',
      channelId: 'paiements',
      channelName: 'Paiements',
    );
  }

  // ─── Instance methods (system + in-app) ────────────────────────────────────

  /// Version instance: systeme + notification in-app via callback.
  void notifierCreationMembreFull(Membre membre) {
    notifierCreationMembre(membre);
    final nomComplet = '${membre.prenom} ${membre.nom}';
    _showInApp(
      titre: 'Nouveau membre',
      message: '$nomComplet a rejoint l\'eglise',
      typeEvenement: 'membre_ajoute',
      entiteId: membre.id,
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierCreationCulteFull(Culte culte) {
    notifierCreationCulte(culte);
    final titreCulte = culte.titre != null ? ' : ${culte.titre}' : '';
    final body = 'Nouveau culte${titreCulte.isNotEmpty ? titreCulte : ''} - ${DateFormat('dd/MM/yyyy').format(culte.dateCulte)}';
    _showInApp(
      titre: 'Nouveau culte',
      message: body,
      typeEvenement: 'culte_cree',
      entiteId: culte.id,
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierDonEnregistreFull(double montantDon, String membreNom) {
    notifierDonEnregistre(montantDon, membreNom);
    _showInApp(
      titre: 'Don enregistre',
      message: '$membreNom a fait un don de ${montantDon.toStringAsFixed(0)} F',
      typeEvenement: 'don_enregistre',
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierPaiementAvanceFull(double montant, String membreNom) {
    notifierPaiementAvance(montant, membreNom);
    _showInApp(
      titre: 'Paiement en avance',
      message: '$membreNom a paye ${montant.toStringAsFixed(0)} F en avance',
      typeEvenement: 'paiement_en_avance',
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierPaiementsEnMasseFull(int success, String actionText) {
    notifierPaiementsEnMasse(success, actionText);
    if (success > 0) {
      _showInApp(
        titre: 'Paiements mis a jour',
        message: '$success paiement(s) $actionText',
        typeEvenement: 'paiements_bulk',
      );
    }
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierModificationMembreFull(Membre membre) {
    notifierModificationMembre(membre);
    final nomComplet = '${membre.prenom} ${membre.nom}';
    _showInApp(
      titre: 'Membre modifie',
      message: '$nomComplet a ete modifie',
      typeEvenement: 'membre_modifie',
      entiteId: membre.id,
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierSuppressionMembreFull(Membre membre) {
    notifierSuppressionMembre(membre);
    final nomComplet = '${membre.prenom} ${membre.nom}';
    _showInApp(
      titre: 'Membre supprime',
      message: '$nomComplet a ete supprime',
      typeEvenement: 'membre_supprime',
      entiteId: membre.id,
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierModificationCulteFull(Culte culte) {
    notifierModificationCulte(culte);
    final titreCulte = culte.titre != null ? ' : ${culte.titre}' : '';
    final body = 'Culte${titreCulte.isNotEmpty ? titreCulte : ''} modifie - ${DateFormat('dd/MM/yyyy').format(culte.dateCulte)}';
    _showInApp(
      titre: 'Culte modifie',
      message: body,
      typeEvenement: 'culte_modifie',
      entiteId: culte.id,
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierPaiementEnregistreFull(double montant, String membreNom, String culteTitre) {
    notifierPaiementEnregistre(montant, membreNom, culteTitre);
    final body = '$membreNom a paye ${montant.toStringAsFixed(0)} F pour le culte $culteTitre';
    _showInApp(
      titre: 'Paiement enregistre',
      message: body,
      typeEvenement: 'cotisation_payee',
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierAbsentMarqueFull(String membreNom, String culteTitre) {
    notifierAbsentMarque(membreNom, culteTitre);
    final body = '$membreNom a ete marque absent pour le culte $culteTitre';
    _showInApp(
      titre: 'Absence marquee',
      message: body,
      typeEvenement: 'cotisation_absente',
    );
  }

  /// Version instance: systeme + notification in-app via callback.
  void notifierModificationCotisationFull(String membreNom, String action) {
    notifierModificationCotisation(membreNom, action);
    _showInApp(
      titre: 'Cotisation modifiee',
      message: '$membreNom : $action',
      typeEvenement: 'cotisation_modifiee',
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static void _showSystem({
    required String title,
    required String body,
    String channelId = 'default',
    String channelName = 'Général',
  }) {
    unawaited(NotificationService.showNotification(
      title: title,
      body: body,
      channelId: channelId,
      channelName: channelName,
    ));
  }

  void _showInApp({
    required String titre,
    required String message,
    required String typeEvenement,
    String? entiteId,
  }) {
    onInAppNotify?.call(
      titre: titre,
      message: message,
      typeEvenement: typeEvenement,
      entiteId: entiteId,
    );
  }
}
