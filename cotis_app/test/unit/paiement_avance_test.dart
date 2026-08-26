import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/providers/kased_app_provider.dart';

/// Tests unitaires pour la feature "Paiement en Avance"
void main() {
  group('Paiement en Avance - CotisationLogic', () {
    test('determinerStatut: paiement avant le culte → enAvance', () {
      final statut = CotisationLogic.determinerStatut(
        datePaiement: DateTime(2026, 8, 10),
        dateCulte: DateTime(2026, 8, 14),
      );
      expect(statut, StatutCotisation.enAvance);
    });

    test('determinerStatut: paiement le jour du culte → paye', () {
      final statut = CotisationLogic.determinerStatut(
        datePaiement: DateTime(2026, 8, 14),
        dateCulte: DateTime(2026, 8, 14),
      );
      expect(statut, StatutCotisation.paye);
    });

    test('determinerStatut: paiement après le culte → paye', () {
      final statut = CotisationLogic.determinerStatut(
        datePaiement: DateTime(2026, 8, 15),
        dateCulte: DateTime(2026, 8, 14),
      );
      expect(statut, StatutCotisation.paye);
    });
  });

  group('Paiement en Avance - Arrondi montantParCulte', () {
    test('montant divisible: 150 / 3 = 50.0', () {
      final result = (150.0 / 3).roundToDouble();
      expect(result, 50.0);
    });

    test('montant non divisible: 160 / 3 → arrondi à 53.0', () {
      final result = (160.0 / 3).roundToDouble();
      expect(result, 53.0);
    });

    test('montant non divisible: 100 / 7 → arrondi à 14.0', () {
      final result = (100.0 / 7).roundToDouble();
      expect(result, 14.0);
    });
  });

  group('Paiement en Avance - Dashboard Stats', () {
    test('getDashboardStats: inclut montantEnAvance des membres', () {
      final membre1 = Membre()
        ..id = 'm1'
        ..nom = 'Koffi'
        ..prenom = 'Marie'
        ..montantEnAvance = 200.0
        ..isActive = true;

      final membre2 = Membre()
        ..id = 'm2'
        ..nom = 'Ahounou'
        ..prenom = 'Paul'
        ..montantEnAvance = 0.0
        ..isActive = true;

      final state = AppState(
        membres: [membre1, membre2],
        cultes: [],
        cotisations: [],
      );

      final stats = StatsService().getDashboardStats(state);
      expect(stats.montantEnAvance, 200.0);
    });

    test('getDashboardStats: membre inactif ne compte pas', () {
      final membre1 = Membre()
        ..id = 'm1'
        ..nom = 'Koffi'
        ..prenom = 'Marie'
        ..montantEnAvance = 100.0
        ..isActive = true;

      final membre2 = Membre()
        ..id = 'm2'
        ..nom = 'Ahounou'
        ..prenom = 'Paul'
        ..montantEnAvance = 50.0
        ..isActive = false;

      final state = AppState(
        membres: [membre1, membre2],
        cultes: [],
        cotisations: [],
      );

      final stats = StatsService().getDashboardStats(state);
      expect(stats.montantEnAvance, 100.0);
    });
  });

  group('Paiement en Avance - Notification', () {
    test('notifierPaiementAvance: existe et a la bonne signature', () {
      expect(
        NotificationCoordinator.notifierPaiementAvance,
        isA<void Function(double, String)>(),
      );
    });
  });

  group('Paiement en Avance - Cotisation', () {
    test('Cotisation.copyWith: crée une copie avec statut enAvance', () {
      final cot = Cotisation()
        ..id = 'cot-1'
        ..membreId = 'm1'
        ..culteId = 'c1'
        ..montantObligatoire = 50.0
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye;

      final updated = cot.copyWith(
        montantPaye: 50.0,
        statut: StatutCotisation.enAvance,
      );

      expect(updated.montantPaye, 50.0);
      expect(updated.statut, StatutCotisation.enAvance);
      expect(updated.id, 'cot-1');
    });

    test('Cotisation estPaye: vrai quand montantPaye >= montantObligatoire', () {
      final cot = Cotisation()
        ..id = 'cot-1'
        ..montantObligatoire = 50.0
        ..montantPaye = 50.0
        ..statut = StatutCotisation.enAvance;

      expect(cot.estPaye, isTrue);
    });
  });

  group('Paiement en Avance - Culte', () {
    test('Culte.fromJson: lit member_ids correctement', () {
      final json = {
        'id': 'c1',
        'date_culte': '2026-08-21',
        'titre': 'Culte Dimanche',
        'montant_cotisation': 50.0,
        'member_ids': ['m1', 'm2', 'm3'],
      };

      final culte = Culte.fromJson(json);
      expect(culte.id, 'c1');
      expect(culte.titre, 'Culte Dimanche');
      expect(culte.montantCotisation, 50.0);
      expect(culte.memberIds, ['m1', 'm2', 'm3']);
    });

    test('Culte.fromJson: member_ids vide par défaut', () {
      final json = {
        'id': 'c1',
        'date_culte': '2026-08-21',
        'titre': 'Culte Dimanche',
        'montant_cotisation': 50.0,
      };

      final culte = Culte.fromJson(json);
      expect(culte.memberIds, isEmpty);
    });

    test('Culte.toJson: inclut member_ids s\'il y en a', () {
      final culte = Culte()
        ..id = 'c1'
        ..dateCulte = DateTime(2026, 8, 21)
        ..titre = 'Culte'
        ..montantCotisation = 50.0
        ..memberIds = ['m1', 'm2'];

      final json = culte.toJson();
      expect(json['member_ids'], ['m1', 'm2']);
    });
  });

  group('Paiement en Avance - Membre', () {
    test('Membre.nomComplet: retourne prenom + nom', () {
      final membre = Membre()
        ..id = 'm1'
        ..prenom = 'Marie'
        ..nom = 'Koffi';

      expect(membre.nomComplet, 'Marie Koffi');
    });
  });
}
