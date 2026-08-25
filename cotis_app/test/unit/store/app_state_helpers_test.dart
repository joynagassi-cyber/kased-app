import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:kased_app/store/app_state_helpers.dart';

void main() {
  group('AppState Helpers', () {
    final membres = [
      Membre()..id = 'm2'..nom = 'Dupont'..prenom = 'Jean',
      Membre()..id = 'm1'..nom = 'Martin'..prenom = 'Alice',
      Membre()..id = 'm3'..nom = 'Dupont'..prenom = 'Bob',
    ];

    group('sortMembres', () {
      test('trie par nom puis prénom', () {
        final sorted = sortMembres(membres);
        // Trie par nom d'abord: Dupont < Martin
        expect(sorted[0].nomComplet, 'Bob Dupont');
        expect(sorted[1].nomComplet, 'Jean Dupont');
        expect(sorted[2].nomComplet, 'Alice Martin');
      });

      test('ne modifie pas la liste originale', () {
        sortMembres(membres);
        expect(membres[0].nomComplet, 'Jean Dupont');
      });
    });

    group('removeMembre', () {
      test('supprime le membre par id', () {
        final result = removeMembre(membres, 'm2');
        expect(result.length, 2);
        expect(result.every((m) => m.id != 'm2'), true);
      });

      test('ne supprime rien si id inexistant', () {
        final result = removeMembre(membres, 'nonexistent');
        expect(result.length, 3);
      });
    });

    group('addMembreSorted', () {
      test('ajoute et trie', () {
        final newMembre = Membre()..id = 'm4'..nom = 'Aardvark'..prenom = 'Zoe';
        final result = addMembreSorted(membres, newMembre);
        expect(result.length, 4);
        expect(result[0].nomComplet, 'Zoe Aardvark');
      });
    });

    group('updateMembreInList', () {
      test('met à jour et trie', () {
        final updated = Membre()
          ..id = 'm1'
          ..nom = 'Zzz'
          ..prenom = 'Updated';
        final result = updateMembreInList(membres, 'm1', updated);
        // "Zzz" > "Dupont", donc "Updated Zzz" sera en dernier
        expect(result.last.nomComplet, 'Updated Zzz');
      });
    });

    group('Culte sorting', () {
      final cultes = [
        Culte()..id = 'c1'..dateCulte = DateTime(2026, 1, 10),
        Culte()..id = 'c2'..dateCulte = DateTime(2026, 1, 5),
        Culte()..id = 'c3'..dateCulte = DateTime(2026, 1, 15),
      ];

      test('sortCultesDesc trie par date décroissante', () {
        final sorted = sortCultesDesc(cultes);
        expect(sorted[0].dateCulte.day, 15);
        expect(sorted[1].dateCulte.day, 10);
        expect(sorted[2].dateCulte.day, 5);
      });

      test('addCulteSorted ajoute et trie', () {
        final newCulte = Culte()..id = 'c4'..dateCulte = DateTime(2026, 2, 1);
        final result = addCulteSorted(cultes, newCulte);
        expect(result.length, 4);
        expect(result[0].dateCulte.month, 2);
      });
    });

    group('Cotisation helpers', () {
      final cotisations = [
        Cotisation()
          ..id = 'co1'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..statut = StatutCotisation.paye
          ..montantPaye = 50.0,
        Cotisation()
          ..id = 'co2'
          ..membreId = 'm1'
          ..culteId = 'c2'
          ..statut = StatutCotisation.nonPaye
          ..montantPaye = 0.0,
      ];

      test('upsertCotisation remplace si existe', () {
        final updated = cotisations[0].copyWith(montantPaye: 100.0);
        final result = upsertCotisation(cotisations, updated);
        expect(result[0].montantPaye, 100.0);
        expect(result.length, 2);
      });

      test('upsertCotisation ajoute si inexistant', () {
        final newCot = Cotisation()
          ..id = 'co3'
          ..membreId = 'm2'
          ..culteId = 'c1'
          ..statut = StatutCotisation.paye
          ..montantPaye = 50.0;
        final result = upsertCotisation(cotisations, newCot);
        expect(result.length, 3);
      });
    });

    group('Filters', () {
      final membres = [
        Membre()..id = 'm1'..nom = 'Actif'..prenom = 'User'..isActive = true,
        Membre()..id = 'm2'..nom = 'Inactif'..prenom = 'User'..isActive = false,
        Membre()..id = 'm3'..nom = 'Deleted'..prenom = 'User'..isDeleted = true,
      ];

      test('filterActiveMembres exclut inactifs et supprimés', () {
        final result = filterActiveMembres(membres);
        expect(result.length, 1);
        expect(result[0].id, 'm1');
      });

      final cultes = [
        Culte()..id = 'c1'..dateCulte = DateTime.now().add(const Duration(days: 7)),
        Culte()..id = 'c2'..dateCulte = DateTime.now().subtract(const Duration(days: 7)),
        Culte()..id = 'c3'..dateCulte = DateTime.now().add(const Duration(days: 14)),
      ];

      test('filterFutureCultes retourne les cultes futurs', () {
        final result = filterFutureCultes(cultes);
        expect(result.length, 2);
        expect(result.every((c) => c.dateCulte.isAfter(DateTime.now())), true);
      });

      test('filterPastCultes retourne les cultes passés', () {
        final result = filterPastCultes(cultes);
        expect(result.length, 1);
        expect(result[0].id, 'c2');
      });
    });

    group('AppState withFullData', () {
      test('met à jour et trie membres et cultes', () {
        final cultes = [
          Culte()..id = 'c1'..dateCulte = DateTime(2026, 1, 10),
          Culte()..id = 'c2'..dateCulte = DateTime(2026, 1, 5),
        ];
        final state = AppState(
          membres: membres,
          cultes: cultes,
          cotisations: [],
        );
        final result = withFullData(
          state,
          membres: membres.reversed.toList(),
          cultes: cultes.reversed.toList(),
          cotisations: [],
        );
        expect(result.membres.first.nomComplet, 'Bob Dupont');
        expect(result.cultes.first.dateCulte.day, 10);
      });
    });
  });
}
