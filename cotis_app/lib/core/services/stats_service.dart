import 'package:flutter/foundation.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Statistiques globales du tableau de bord.
class DashboardStats {
  final int totalMembres;
  final int totalCultes;
  final double totalCollecte;
  final int membresEnRetard;
  final double totalDu;
  final int membresEnAvance;
  final double montantEnAvance;
  final Culte? prochainCulte;
  final double collecteMoisPrecedent;
  final double objectifMensuel;

  DashboardStats({
    required this.totalMembres,
    required this.totalCultes,
    required this.totalCollecte,
    required this.membresEnRetard,
    required this.totalDu,
    this.membresEnAvance = 0,
    this.montantEnAvance = 0.0,
    this.prochainCulte,
    this.collecteMoisPrecedent = 0.0,
    this.objectifMensuel = 0.0,
  });
}

/// Données d un membre en retard de paiement.
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
class StatsService {
  DashboardStats getDashboardStats(AppState state) {
    final membres = state.membres;
    final cultes = state.cultes;
    final cotisations = state.cotisations;

    final totalCollecte = cotisations
        .where((c) => c.estPaye)
        .fold<double>(0, (sum, c) => sum + c.montantPaye);

    final now = DateTime.now();
    final cultesPassesIds =
        cultes.where((c) => !c.isDeleted && c.dateCulte.isBefore(now)).map((c) => c.id).toSet();

    final membresById = {for (final m in membres) m.id: m};
    final membresEnRetardIds = <String>{};
    double totalDu = 0.0;
    
    for (final cot in cotisations.where((c) =>
        cultesPassesIds.contains(c.culteId) && c.estEnRetard)) {
      final membre = membresById[cot.membreId];
      if (membre == null) {
        membresEnRetardIds.add(cot.membreId);
        totalDu += (cot.montantObligatoire - cot.montantPaye);
        continue;
      }
      
      if (membre.montantEnAvance > 0) {
        membresEnRetardIds.add(cot.membreId);
        final reste = (cot.montantObligatoire - cot.montantPaye) - membre.montantEnAvance;
        if (reste > 0) {
          totalDu += reste;
        }
      } else {
        membresEnRetardIds.add(cot.membreId);
        totalDu += (cot.montantObligatoire - cot.montantPaye);
      }
    }

    // Calcul des membres en avance
    final futureCulteIds = cultes
        .where((c) => !c.isDeleted && c.dateCulte.isAfter(now))
        .map((c) => c.id)
        .toSet();

    int membresEnAvance = 0;
    double montantEnAvance = 0.0;

    for (final cot in cotisations.where((cot) => cot.statut == StatutCotisation.enAvance)) {
      if (futureCulteIds.contains(cot.culteId)) {
        membresEnAvance++;
        montantEnAvance += cot.montantPaye;
      }
    }

    return DashboardStats(
      totalMembres: membres.where((m) => m.isActive && !m.isDeleted).length,
      totalCultes: cultes.where((c) => !c.isDeleted).length,
      totalCollecte: totalCollecte,
      membresEnRetard: membresEnRetardIds.length,
      totalDu: totalDu,
      membresEnAvance: membresEnAvance,
      montantEnAvance: montantEnAvance,
      prochainCulte: _getProchainCulte(cultes, now),
      collecteMoisPrecedent: _getCollecteMoisPrecedent(cotisations, now),
      objectifMensuel: 0.0, // Par défaut, peut être surchargé depuis AppState
    );
  }

  List<Map<String, dynamic>> getRetardsMembresLocally(AppState state) {
    final membres = state.membres;
    final cultes = state.cultes;
    final cotisations = state.cotisations;

    final now = DateTime.now();
    final cultesPassesIds =
        cultes.where((c) => !c.isDeleted && c.dateCulte.isBefore(now)).map((c) => c.id).toSet();

    final result = <Map<String, dynamic>>[];

    for (final membre in membres.where((m) => m.isActive && !m.isDeleted)) {
      final retardsCotisations = cotisations
          .where((c) =>
              c.membreId == membre.id &&
              cultesPassesIds.contains(c.culteId) &&
              c.estEnRetard)
          .toList();

      final montantEnAvance = membre.montantEnAvance;
      
      if (montantEnAvance > 0 && retardsCotisations.isNotEmpty) {
        double avanceRestante = montantEnAvance;
        final cotisationsNonCouvertes = <Cotisation>[];
        
        for (final cot in retardsCotisations) {
          if (avanceRestante >= cot.montantObligatoire) {
            avanceRestante -= cot.montantObligatoire;
          } else if (avanceRestante > 0) {
            avanceRestante = 0;
          } else {
            cotisationsNonCouvertes.add(cot);
          }
        }
        
        if (cotisationsNonCouvertes.isEmpty) continue;
        
        final payedCotisations = cotisations
            .where((c) =>
                c.membreId == membre.id && c.estPaye && c.datePaiement != null)
            .toList()
          ..sort((a, b) => b.datePaiement!.compareTo(a.datePaiement!));

        final dernierPaiement = payedCotisations.isNotEmpty
            ? payedCotisations.first.datePaiement
            : null;

        final montantDu = cotisationsNonCouvertes.fold<double>(
            0, (sum, c) => sum + (c.montantObligatoire - c.montantPaye));

        result.add({
          'membre_id': membre.id,
          'nom': membre.nom,
          'prenom': membre.prenom,
          'cultes_en_retard': cotisationsNonCouvertes.length,
          'montant_du_fcfa': montantDu,
          'dernier_paiement': dernierPaiement?.toIso8601String(),
          'montant_en_avance': membre.montantEnAvance,
        });
      } else {
        if (retardsCotisations.isEmpty) continue;

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
          'montant_en_avance': membre.montantEnAvance,
        });
      }
    }

    result.sort((a, b) => (b['montant_du_fcfa'] as double)
        .compareTo(a['montant_du_fcfa'] as double));
    return result;
  }

  Future<Map<String, dynamic>> fetchDashboard(InsForgeService api) async {
    try {
      return await api.getDashboard();
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> loadRetardsMembres(
      InsForgeService api) async {
    try {
      return await api.getRetardsMembres();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadMembresAJour(
      InsForgeService api) async {
    try {
      return await api.getMembresAJour();
    } catch (e) {
      return [];
    }
  }

  /// Retourne le prochain culte futur (non supprimé).
  Culte? _getProchainCulte(List<Culte> cultes, DateTime now) {
    final futurs = cultes
        .where((c) => !c.isDeleted && c.dateCulte.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateCulte.compareTo(b.dateCulte));
    return futurs.isEmpty ? null : futurs.first;
  }

  /// Retourne la collecte du mois précédent (pour calcul de tendance).
  double _getCollecteMoisPrecedent(List<Cotisation> cotisations, DateTime now) {
    final moisActuel = now.month;
    final anneeActuelle = now.year;
    final moisPrecedent = moisActuel == 1 ? 12 : moisActuel - 1;
    final anneePrecedente = moisActuel == 1 ? anneeActuelle - 1 : anneeActuelle;

    final debutMoisPrec = DateTime(anneePrecedente, moisPrecedent, 1);
    final finMoisPrec = DateTime(anneePrecedente, moisPrecedent + 1, 0);

    return cotisations
        .where((c) =>
            c.estPaye &&
            c.datePaiement != null &&
            c.datePaiement!.isAfter(debutMoisPrec) &&
            c.datePaiement!.isBefore(finMoisPrec.add(const Duration(days: 1))))
        .fold<double>(0, (sum, c) => sum + c.montantPaye);
  }

  /// Retourne les N membres en retard les plus endettés.
  List<Map<String, dynamic>> getTopRetards(AppState state, int n) {
    final retards = getRetardsMembresLocally(state);
    return retards.take(n).toList();
  }

  /// Charge l'objectif mensuel depuis SharedPreferences.
  static Future<double> loadObjectifMensuel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('kased_objectif_mensuel');
      if (raw == null) return 0.0;
      return double.tryParse(raw) ?? 0.0;
    } catch (e) {
      debugPrint('[Stats] Erreur chargement objectif: $e');
      return 0.0;
    }
  }

  /// Sauvegarde l'objectif mensuel dans SharedPreferences.
  static Future<void> saveObjectifMensuel(double montant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kased_objectif_mensuel', montant.toString());
    } catch (e) {
      debugPrint('[Stats] Erreur sauvegarde objectif: $e');
    }
  }
}
