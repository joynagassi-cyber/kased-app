import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/app_data_provider.dart';

final statsGraphiquesProvider = Provider<DonneesGraphiques>((ref) {
  final state = ref.watch(appDataProvider).value;
  if (state == null) return DonneesGraphiques.empty();
  return DonneesGraphiques.fromState(state);
});

class CollecteParMois {
  final String libelle;
  final double montant;

  const CollecteParMois({required this.libelle, required this.montant});
}

class ParticipationParCulte {
  final Culte culte;
  final int membresPayes;
  final int membresConcernes;

  const ParticipationParCulte({
    required this.culte,
    required this.membresPayes,
    required this.membresConcernes,
  });

  double get pourcentage => membresConcernes == 0 ? 0 : membresPayes / membresConcernes * 100;
}

class MembreAssidu {
  final Membre membre;
  final int cultesPayes;
  final int cultesConcernes;

  const MembreAssidu({
    required this.membre,
    required this.cultesPayes,
    required this.cultesConcernes,
  });

  double get pourcentage => cultesConcernes == 0 ? 0 : cultesPayes / cultesConcernes * 100;
}

class DonneesGraphiques {
  final List<CollecteParMois> collecteParMois;
  final List<ParticipationParCulte> participationParCulte;
  final List<MembreAssidu> topMembres;

  const DonneesGraphiques({
    required this.collecteParMois,
    required this.participationParCulte,
    required this.topMembres,
  });

  factory DonneesGraphiques.empty() => const DonneesGraphiques(
        collecteParMois: [],
        participationParCulte: [],
        topMembres: [],
      );

  factory DonneesGraphiques.fromState(AppState state) {
    final now = DateTime.now();
    const moisLabels = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

     final collecteParMois = List.generate(12, (index) {
       final monthDate = DateTime(now.year, now.month - (11 - index), 1);
       final label = moisLabels[monthDate.month - 1];
       final montant = state.cotisations
           .where((c) => c.estPaye)
           .where((c) => c.datePaiement != null)
           .where((c) => c.datePaiement!.year == monthDate.year && c.datePaiement!.month == monthDate.month)
           .fold(0.0, (sum, c) => sum + c.montantPaye);
       return CollecteParMois(libelle: label, montant: montant);
     });

    final cultesTries = [...state.cultes]..sort((a, b) => a.dateCulte.compareTo(b.dateCulte));
    final participationParCulte = cultesTries.map((culte) {
      final membresConcernes = state.membres.where((m) => !m.dateAdhesion.isAfter(culte.dateCulte)).length;
      final membresPayes = state.cotisations.where((c) => c.culteId == culte.id && c.estPaye).length;
      return ParticipationParCulte(
        culte: culte,
        membresPayes: membresPayes,
        membresConcernes: membresConcernes,
      );
    }).toList();

    final topMembres = state.membres.map((membre) {
      final cultesConcernes = cultesTries.where((c) => !membre.dateAdhesion.isAfter(c.dateCulte)).toList();
      final cotisationsMembre = state.cotisations.where((c) => c.membreId == membre.id && c.estPaye).toList();
      final cultesPayes = cultesConcernes.where((c) => cotisationsMembre.any((cot) => cot.culteId == c.id)).length;
      return MembreAssidu(
        membre: membre,
        cultesPayes: cultesPayes,
        cultesConcernes: cultesConcernes.length,
      );
    }).where((m) => m.cultesConcernes > 0).toList()
      ..sort((a, b) {
        final byRatio = b.pourcentage.compareTo(a.pourcentage);
        if (byRatio != 0) return byRatio;
        return b.cultesPayes.compareTo(a.cultesPayes);
      });

    return DonneesGraphiques(
      collecteParMois: collecteParMois,
      participationParCulte: participationParCulte,
      topMembres: topMembres.take(5).toList(),
    );
  }
}

