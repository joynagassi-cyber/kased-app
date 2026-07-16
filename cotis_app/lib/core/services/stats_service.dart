import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/app_data_provider.dart';

/// Statistiques globales du tableau de bord.
class DashboardStats {
  final int totalMembres;
  final int totalCultes;
  final double totalCollecte;
  final int membresEnRetard;
  final double totalDu;

  DashboardStats({
    required this.totalMembres,
    required this.totalCultes,
    required this.totalCollecte,
    required this.membresEnRetard,
    required this.totalDu,
  });
}

/// Données d'un membre en retard de paiement.
class MembreRetard {
  final Membre membre;
  final int nombreRetards;
  final double montantDu;
  final List<Culte> cultesManquants;
  final DateTime? dernierPaiement;

  MembreRetard({
    required this.membre,
    required this.nombreRetards,
    required this.montantDu,
    this.cultesManquants = const [],
    this.dernierPaiement,
  });
}

/// Service de calcul et chargement des statistiques.
///
/// Fonctions pures de calcul sur [AppState] + appels API.
/// Ne gère pas d'état — délègue au provider.
class StatsService {
  /// Calcule les statistiques localement à partir des données [AppState].
  /// Fonctionne en offline et est toujours à jour après un togglePaiement.
  DashboardStats getDashboardStats(AppState state) {
    final membres = state.membres;
    final cultes = state.cultes;
    final cotisations = state.cotisations;

    // Collecte cumulée de tous les cultes (montant effectivement payé)
    final totalCollecte = cotisations
        .where((c) => c.estPaye)
        .fold<double>(0, (sum, c) => sum + c.montantPaye);

    // Membres en retard = ont au moins une cotisation non payée sur un culte passé
    final now = DateTime.now();
    final cultesPassesIds =
        cultes.where((c) => c.dateCulte.isBefore(now)).map((c) => c.id).toSet();

    final membresEnRetardIds = cotisations
        .where((c) =>
            cultesPassesIds.contains(c.culteId) && c.estEnRetard)
        .map((c) => c.membreId)
        .toSet();

    // Total dû = somme du montant restant à payer (obligatoire - payé) sur cultes passés
    final totalDu = cotisations
        .where((c) =>
            cultesPassesIds.contains(c.culteId) && c.estEnRetard)
        .fold<double>(
            0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));

    return DashboardStats(
      totalMembres: membres.where((m) => m.isActive).length,
      totalCultes: cultes.length,
      totalCollecte: totalCollecte,
      membresEnRetard: membresEnRetardIds.length,
      totalDu: totalDu,
    );
  }

  /// Calcule les membres en retard localement depuis [AppState].
  /// Fonctionne parfaitement en offline et en online.
  List<Map<String, dynamic>> getRetardsMembresLocally(AppState state) {
    final membres = state.membres;
    final cultes = state.cultes;
    final cotisations = state.cotisations;

    final now = DateTime.now();
    final cultesPassesIds =
        cultes.where((c) => c.dateCulte.isBefore(now)).map((c) => c.id).toSet();

    final result = <Map<String, dynamic>>[];

    for (final membre in membres.where((m) => m.isActive)) {
      // Cotisations non payées sur cultes passés
      final retardsCotisations = cotisations
          .where((c) =>
              c.membreId == membre.id &&
              cultesPassesIds.contains(c.culteId) &&
              c.estEnRetard)
          .toList();

      if (retardsCotisations.isEmpty) continue;

      // Dernier paiement effectué
      final payedCotisations = cotisations
          .where((c) =>
              c.membreId == membre.id && c.estPaye && c.datePaiement != null)
          .toList()
        ..sort((a, b) => b.datePaiement!.compareTo(a.datePaiement!));

      final dernierPaiement = payedCotisations.isNotEmpty
          ? payedCotisations.first.datePaiement
          : null;

      final montantDu = retardsCotisations.fold<double>(
          0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));

      result.add({
        'membre_id': membre.id,
        'nom': membre.nom,
        'prenom': membre.prenom,
        'cultes_en_retard': retardsCotisations.length,
        'montant_du_fcfa': montantDu,
        'dernier_paiement': dernierPaiement?.toIso8601String(),
      });
    }

    // Trier par montant dû décroissant
    result.sort((a, b) => (b['montant_du_fcfa'] as double)
        .compareTo(a['montant_du_fcfa'] as double));
    return result;
  }

  /// Récupère les données dashboard depuis l'API et les retourne.
  Future<Map<String, dynamic>> fetchDashboard(InsForgeService api) async {
    try {
      return await api.getDashboard();
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
      return {};
    }
  }

  /// Charge la liste des membres en retard depuis l'API.
  Future<List<Map<String, dynamic>>> loadRetardsMembres(
      InsForgeService api) async {
    try {
      return await api.getRetardsMembres();
    } catch (e) {
      return [];
    }
  }

  /// Charge la liste des membres à jour depuis l'API.
  Future<List<Map<String, dynamic>>> loadMembresAJour(
      InsForgeService api) async {
    try {
      return await api.getMembresAJour();
    } catch (e) {
      return [];
    }
  }
}
