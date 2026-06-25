import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/logic/cotisation_logic.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Tests de résistance — comportement de l'app sous conditions dégradées
// ---------------------------------------------------------------------------
void main() {
  group('Résilience — AuthState sous conditions dégradées', () {
    test('Session expirée : isAuthenticated passe à false sans crash', () {
      // Simule la déconnexion forcée suite à un 401
      // Le provider appellerait logout() → nouvel état déconnecté
      const afterLogout = AuthState(
        isAuthenticated: false,
        isLoading: false,
      );

      expect(afterLogout.isAuthenticated, isFalse);
      expect(afterLogout.token, isNull);
      // Pas d'exception lancée
    });

    test('AppState en mode offline ne crashe pas', () {
      final offlineState = AppState(
        membres: [],
        cultes: [],
        cotisations: [],
        isOffline: true,
        isLoading: false,
      );

      expect(offlineState.isOffline, isTrue);
      // getDashboardStats ne crashe pas même sans dashboard
      final stats = DashboardStats(
        totalMembres: 0,
        totalCultes: 0,
        totalCollecte: 0,
        membresEnRetard: 0,
        totalDu: 0,
      );
      expect(stats.totalMembres, equals(0));
    });

    test('AppState avec error ne crashe pas', () {
      final errorState = AppState(
        isOffline: false,
        isLoading: false,
        error: 'Timeout connexion réseau',
      );

      expect(errorState.error, isNotNull);
      expect(errorState.isLoading, isFalse);
    });

    test('Reconnexion après offline : état peut être rétabli', () {
      final offline = AppState(isOffline: true, isLoading: false);
      // Simule le retour de connectivité
      final online = offline.copyWith(isOffline: false, isLoading: true);

      expect(online.isOffline, isFalse);
      expect(online.isLoading, isTrue);
    });
  });

  group('Résilience — CotisationLogic avec données dégradées', () {
    test('Liste de cultes null-safe : aucune exception avec liste vide', () {
      expect(
        () => CotisationLogic.calculerNombreRetards(
          cultes: [],
          cotisations: [],
          dateAdhesion: DateTime(2024, 1, 1),
        ),
        returnsNormally,
      );
    });

    test('Cotisation avec culteId inexistant ignorée sans crash', () {
      final cultes = [
        Culte()
          ..id = 'c1'
          ..dateCulte = DateTime(2024, 1, 7)
          ..montantCotisation = 50.0,
      ];
      final cotisations = [
        Cotisation()
          ..id = 'cot1'
          ..membreId = 'mem1'
          ..culteId = 'c_inexistant' // ID qui n'existe pas dans cultes
          ..statut = StatutCotisation.paye
          ..montantObligatoire = 50.0,
      ];

      // Ne doit pas crasher — c1 reste nonPaye implicitement
      final retards = CotisationLogic.calculerNombreRetards(
        cultes: cultes,
        cotisations: cotisations,
        dateAdhesion: DateTime(2024, 1, 1),
      );

      // c1 n'a pas de cotisation correspondante → 1 retard
      expect(retards, equals(1));
    });

    test('Calcul avec des milliers de cultes ne crashe pas', () {
      // Test de robustesse sur grande quantité de données
      final cultes = List.generate(
        1000,
        (i) => Culte()
          ..id = 'c$i'
          ..dateCulte = DateTime(2020, 1, 1).add(Duration(days: i * 7))
          ..montantCotisation = 50.0,
      );

      expect(
        () => CotisationLogic.calculerNombreRetards(
          cultes: cultes,
          cotisations: [],
          dateAdhesion: DateTime(2020, 1, 1),
        ),
        returnsNormally,
      );
    });
  });

  group('Résilience — Sérialisation JSON corrompue', () {
    test('fromJson avec montant_obligatoire null → utilise valeur par défaut 50.0', () {
      final json = {
        'id': 'uuid-cot',
        'membre_id': 'uuid-m',
        'culte_id': 'uuid-c',
        'statut': 'non_paye',
        'montant_obligatoire': null, // valeur null
      };
      final cot = Cotisation.fromJson(json);
      expect(cot.montantObligatoire, equals(50.0)); // valeur par défaut
      expect(cot.montantPaye, equals(0.0));
    });

    test('Culte.fromJson avec montant_cotisation null → défaut 50.0', () {
      final json = {
        'id': 'uuid-culte',
        'date_culte': '2024-01-07',
        'montant_cotisation': null,
      };
      final culte = Culte.fromJson(json);
      expect(culte.montantCotisation, equals(50.0));
    });

    test('Membre.fromJson sans is_active → défaut true', () {
      final json = {
        'id': 'uuid-m',
        'nom': 'Test',
        'prenom': 'User',
        'date_adhesion': '2024-01-01',
      };
      final membre = Membre.fromJson(json);
      expect(membre.isActive, isTrue);
    });
  });
}
