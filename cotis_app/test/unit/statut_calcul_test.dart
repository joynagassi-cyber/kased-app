import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/models/cotisation.dart';

void main() {
  group('CotisationLogic.determinerStatut', () {
    test('Paiement avant la date du culte → enAvance', () {
      final datePaiement = DateTime(2024, 1, 5); // vendredi
      final dateCulte    = DateTime(2024, 1, 7); // dimanche

      final statut = CotisationLogic.determinerStatut(
        datePaiement: datePaiement,
        dateCulte: dateCulte,
      );

      expect(statut, equals(StatutCotisation.enAvance));
    });

    test('Paiement le jour même du culte → paye', () {
      final date = DateTime(2024, 1, 7); // dimanche

      final statut = CotisationLogic.determinerStatut(
        datePaiement: date,
        dateCulte: date,
      );

      expect(statut, equals(StatutCotisation.paye));
    });

    test('Paiement après la date du culte → paye', () {
      final datePaiement = DateTime(2024, 1, 10); // mercredi suivant
      final dateCulte    = DateTime(2024, 1, 7);  // dimanche passé

      final statut = CotisationLogic.determinerStatut(
        datePaiement: datePaiement,
        dateCulte: dateCulte,
      );

      expect(statut, equals(StatutCotisation.paye));
    });

    test('Même jour mais heure différente → compare uniquement la date', () {
      // paiement à 23h59 le vendredi, culte le dimanche
      final datePaiement = DateTime(2024, 1, 5, 23, 59, 59);
      final dateCulte    = DateTime(2024, 1, 7, 10, 0, 0);

      final statut = CotisationLogic.determinerStatut(
        datePaiement: datePaiement,
        dateCulte: dateCulte,
      );

      expect(statut, equals(StatutCotisation.enAvance));
    });

    test('Paiement un an avant → enAvance', () {
      final datePaiement = DateTime(2023, 1, 1);
      final dateCulte    = DateTime(2024, 1, 7);

      final statut = CotisationLogic.determinerStatut(
        datePaiement: datePaiement,
        dateCulte: dateCulte,
      );

      expect(statut, equals(StatutCotisation.enAvance));
    });
  });
}
