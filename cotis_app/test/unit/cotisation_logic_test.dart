import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';

Culte _culte(String id, DateTime date) => Culte()
  ..id = id
  ..dateCulte = date
  ..montantCotisation = 50.0;

Cotisation _cotisation(String culteId, StatutCotisation statut, {DateTime? datePaiement}) {
  return Cotisation()
    ..id = 'c_$culteId'
    ..membreId = 'membre_1'
    ..culteId = culteId
    ..statut = statut
    ..montantObligatoire = 50.0
    ..datePaiement = datePaiement;
}

void main() {
  final dateAdhesion = DateTime(2024, 1, 1);

  group('CotisationLogic.calculerNombreRetards', () {
    test('Membre sans aucun paiement — tous les cultes comptent comme retard', () {
      final cultes = [
        _culte('c1', DateTime(2024, 1, 7)),
        _culte('c2', DateTime(2024, 1, 14)),
        _culte('c3', DateTime(2024, 1, 21)),
      ];

      final retards = CotisationLogic.calculerNombreRetards(
        cultes: cultes,
        cotisations: [],
        dateAdhesion: dateAdhesion,
      );

      expect(retards, equals(3));
    });

    test('Membre avec tous les dimanches payés — aucun retard', () {
      final cultes = [
        _culte('c1', DateTime(2024, 1, 7)),
        _culte('c2', DateTime(2024, 1, 14)),
      ];
      final cotisations = [
        _cotisation('c1', StatutCotisation.paye),
        _cotisation('c2', StatutCotisation.paye),
      ];

      final retards = CotisationLogic.calculerNombreRetards(
        cultes: cultes,
        cotisations: cotisations,
        dateAdhesion: dateAdhesion,
      );

      expect(retards, equals(0));
    });

    test('enAvance compte comme payé — pas de retard', () {
      final cultes = [
        _culte('c1', DateTime(2024, 1, 7)),
        _culte('c2', DateTime(2024, 1, 14)),
        _culte('c3', DateTime(2024, 1, 21)),
      ];
      final cotisations = [
        _cotisation('c1', StatutCotisation.enAvance),
        _cotisation('c2', StatutCotisation.paye),
        _cotisation('c3', StatutCotisation.nonPaye), // 1 retard
      ];

      final retards = CotisationLogic.calculerNombreRetards(
        cultes: cultes,
        cotisations: cotisations,
        dateAdhesion: dateAdhesion,
      );

      expect(retards, equals(1));
    });

    test('absent ne compte pas comme retard', () {
      final cultes = [
        _culte('c1', DateTime(2024, 1, 7)),
        _culte('c2', DateTime(2024, 1, 14)),
      ];
      final cotisations = [
        _cotisation('c1', StatutCotisation.absent), // absent = pas de retard
        _cotisation('c2', StatutCotisation.nonPaye), // 1 retard
      ];

      final retards = CotisationLogic.calculerNombreRetards(
        cultes: cultes,
        cotisations: cotisations,
        dateAdhesion: dateAdhesion,
      );

      expect(retards, equals(1));
    });

    test('Cultes AVANT adhésion ignorés', () {
      final cultes = [
        _culte('c_avant', DateTime(2023, 12, 31)), // Avant adhésion
        _culte('c1', DateTime(2024, 1, 7)),        // Après adhésion
      ];

      final retards = CotisationLogic.calculerNombreRetards(
        cultes: cultes,
        cotisations: [],
        dateAdhesion: dateAdhesion,
      );

      // Seul c1 compte
      expect(retards, equals(1));
    });

    test('Liste de cultes vide — zéro retard', () {
      final retards = CotisationLogic.calculerNombreRetards(
        cultes: [],
        cotisations: [],
        dateAdhesion: dateAdhesion,
      );

      expect(retards, equals(0));
    });
  });

  group('CotisationLogic.calculerMontantDu', () {
    test('3 retards × 50 FCFA = 150 FCFA', () {
      expect(CotisationLogic.calculerMontantDu(3), equals(150.0));
    });

    test('0 retard = 0 FCFA', () {
      expect(CotisationLogic.calculerMontantDu(0), equals(0.0));
    });

    test('Montant personnalisé', () {
      expect(CotisationLogic.calculerMontantDu(2, montantParCulte: 100.0), equals(200.0));
    });
  });
}
