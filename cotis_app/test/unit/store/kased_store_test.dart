import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/store/app_state_helpers.dart';

void main() {
  group('KasedStore - Member actions', () {
    test('withSortedMembres trie les membres', () {
      final state = AppState(
        membres: [
          Membre()..id = 'm2'..nom = 'Zorro'..prenom = 'Avatar',
          Membre()..id = 'm1'..nom = 'Alice'..prenom = 'Bond',
        ],
        cultes: [],
        cotisations: [],
      );
      final result = withSortedMembres(state, state.membres);
      expect(result.membres[0].nomComplet, 'Bond Alice');
      expect(result.membres[1].nomComplet, 'Avatar Zorro');
    });

    test('withSortedCultesDesc trie les cultes par date décroissante', () {
      final state = AppState(
        membres: [],
        cultes: [
          Culte()..id = 'c1'..dateCulte = DateTime(2026, 1, 5),
          Culte()..id = 'c2'..dateCulte = DateTime(2026, 1, 10),
        ],
        cotisations: [],
      );
      final result = withSortedCultesDesc(state, state.cultes);
      expect(result.cultes[0].dateCulte.day, 10);
      expect(result.cultes[1].dateCulte.day, 5);
    });

    test('withCotisations met à jour les cotisations', () {
      final state = AppState(
        membres: [],
        cultes: [],
        cotisations: [],
      );
      final cotisations = [
        Cotisation()
          ..id = 'co1'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..statut = StatutCotisation.paye
          ..montantPaye = 50.0,
      ];
      final result = withCotisations(state, cotisations);
      expect(result.cotisations.length, 1);
      expect(result.cotisations[0].statut, StatutCotisation.paye);
    });
  });

  group('KasedStore - Culte actions', () {
    test('addCulteSorted ajoute et trie', () {
      final cultes = [
        Culte()..id = 'c1'..dateCulte = DateTime(2026, 1, 10),
      ];
      final newCulte = Culte()..id = 'c2'..dateCulte = DateTime(2026, 1, 5);
      final result = addCulteSorted(cultes, newCulte);
      expect(result.length, 2);
      expect(result[0].dateCulte.day, 10);
    });

    test('removeCulte supprime le culte', () {
      final cultes = [
        Culte()..id = 'c1'..dateCulte = DateTime(2026, 1, 10),
        Culte()..id = 'c2'..dateCulte = DateTime(2026, 1, 5),
      ];
      final result = removeCulte(cultes, 'c1');
      expect(result.length, 1);
      expect(result[0].id, 'c2');
    });
  });

  group('KasedStore - Cotisation actions', () {
    test('upsertCotisation remplace une cotisation existante', () {
      final cotisations = [
        Cotisation()
          ..id = 'co1'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..statut = StatutCotisation.nonPaye
          ..montantPaye = 0.0,
      ];
      final updated = cotisations[0].copyWith(
        statut: StatutCotisation.paye,
        montantPaye: 50.0,
      );
      final result = upsertCotisation(cotisations, updated);
      expect(result[0].statut, StatutCotisation.paye);
      expect(result[0].montantPaye, 50.0);
    });

    test('updateCotisationsByCulte transforme toutes les cotisations d\'un culte', () {
      final cotisations = [
        Cotisation()
          ..id = 'co1'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..statut = StatutCotisation.nonPaye,
        Cotisation()
          ..id = 'co2'
          ..membreId = 'm2'
          ..culteId = 'c1'
          ..statut = StatutCotisation.nonPaye,
        Cotisation()
          ..id = 'co3'
          ..membreId = 'm1'
          ..culteId = 'c2'
          ..statut = StatutCotisation.paye,
      ];
      final result = updateCotisationsByCulte(
        cotisations,
        'c1',
        (c) => c.copyWith(statut: StatutCotisation.paye),
      );
      expect(result[0].statut, StatutCotisation.paye);
      expect(result[1].statut, StatutCotisation.paye);
      expect(result[2].statut, StatutCotisation.paye); // pas modifié (autre culte)
    });
  });
}
