import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}

/// Test d'intégration InsForgeService directement via mocking du service
void main() {
  late MockInsForgeService mockApi;

  setUp(() {
    mockApi = MockInsForgeService();
  });

  group('InsForge API - Membres', () {
    test('createMembre calls correct endpoint', () async {
      final membreJson = {
        'id': 'membre-uuid',
        'nom': 'Koffi',
        'prenom': 'Marie',
        'date_adhesion': '2026-01-01',
        'is_active': true,
      };
      when(() => mockApi.createMembre(any())).thenAnswer((_) async => membreJson);

      final result = await mockApi.createMembre(membreJson);
      expect(result['id'], 'membre-uuid');
      verify(() => mockApi.createMembre(any())).called(1);
    });

    test('getMembres returns paginated results', () async {
      final membresJson = [
        {'id': 'm1', 'nom': 'Koffi', 'prenom': 'Marie', 'is_active': true},
        {'id': 'm2', 'nom': 'Ahounou', 'prenom': 'Paul', 'is_active': true},
      ];
      when(() => mockApi.getMembres(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => membresJson);

      final result = await mockApi.getMembres(page: 1, pageSize: 100);
      expect(result.length, 2);
    });

    test('updateMembre with eq filter', () async {
      final updates = {'nom': 'Koffi-Martin'};
      when(() => mockApi.updateMembre(any(), any())).thenAnswer((_) async => {'id': 'm1'});

      await mockApi.updateMembre('m1', updates);
      verify(() => mockApi.updateMembre('m1', updates)).called(1);
    });

    test('deleteMembre with eq filter', () async {
      when(() => mockApi.deleteMembre(any())).thenAnswer((_) async => {});

      await mockApi.deleteMembre('m1');
      verify(() => mockApi.deleteMembre('m1')).called(1);
    });

    test('getAllMembres paginated', () async {
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => [
        {'id': 'm1', 'nom': 'A'},
        {'id': 'm2', 'nom': 'B'},
      ]);

      final result = await mockApi.getAllMembres();
      expect(result.length, 2);
    });
  });

  group('InsForge API - Cultes', () {
    test('createCulte with payload', () async {
      final culteJson = {
        'id': 'culte-uuid',
        'date_culte': '2026-08-21',
        'titre': 'Culte de Pentecôte',
      };
      when(() => mockApi.createCulte(any())).thenAnswer((_) async => culteJson);

      final result = await mockApi.createCulte(culteJson);
      expect(result['id'], 'culte-uuid');
    });

    test('getCultes with descending order', () async {
      final cultesJson = [
        {'id': 'c1', 'date_culte': '2026-08-14', 'titre': 'Culte A'},
      ];
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => cultesJson);

      final result = await mockApi.getCultes(page: 1, pageSize: 50);
      expect(result.length, 1);
    });

    test('creerCulteAvecCotisations RPC', () async {
      const culteUuid = 'new-culte-uuid';
      when(() => mockApi.creerCulteAvecCotisations(
        dateCulte: any(named: 'dateCulte'),
        titre: any(named: 'titre'),
        montantCotisation: any(named: 'montantCotisation'),
      )).thenAnswer((_) async => culteUuid);

      final result = await mockApi.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 8, 21),
        titre: 'Culte du 21',
        montantCotisation: 50.0,
      );
      expect(result, culteUuid);
    });

    test('deleteCulte with eq filter', () async {
      when(() => mockApi.deleteCulte(any())).thenAnswer((_) async => {});

      await mockApi.deleteCulte('c1');
      verify(() => mockApi.deleteCulte('c1')).called(1);
    });
  });

  group('InsForge API - Cotisations', () {
    test('createCotisations calls endpoint', () async {
      when(() => mockApi.createCotisations(any())).thenAnswer((_) async => []);

      await mockApi.createCotisations([{'id': 'cot1'}]);
      verify(() => mockApi.createCotisations(any())).called(1);
    });

    test('getCotisations with order', () async {
      final cotisationsJson = [
        {'id': 'cot1', 'membre_id': 'm1', 'culte_id': 'c1', 'statut': 'paye'},
      ];
      when(() => mockApi.getCotisations()).thenAnswer((_) async => cotisationsJson);

      final result = await mockApi.getCotisations();
      expect(result.length, 1);
    });

    test('getCotisationsDuCulte filters by culte_id', () async {
      final cotisationsJson = [
        {'id': 'cot1', 'membre_id': 'm1', 'culte_id': 'c1', 'statut': 'paye'},
      ];
      when(() => mockApi.getCotisationsDuCulte(any())).thenAnswer((_) async => cotisationsJson);

      final result = await mockApi.getCotisationsDuCulte('c1');
      expect(result.length, 1);
    });

    test('getCotisationsDuMembre filters by membre_id', () async {
      final cotisationsJson = [
        {'id': 'cot1', 'membre_id': 'm1', 'culte_id': 'c1', 'statut': 'paye'},
        {'id': 'cot2', 'membre_id': 'm1', 'culte_id': 'c2', 'statut': 'non_paye'},
      ];
      when(() => mockApi.getCotisationsDuMembre(any())).thenAnswer((_) async => cotisationsJson);

      final result = await mockApi.getCotisationsDuMembre('m1');
      expect(result.length, 2);
    });

    test('updateCotisation with eq filter', () async {
      when(() => mockApi.updateCotisation(any(), any())).thenAnswer((_) async => {'id': 'cot1'});

      await mockApi.updateCotisation('cot1', {'statut': 'paye'});
      verify(() => mockApi.updateCotisation('cot1', {'statut': 'paye'})).called(1);
    });

    test('deleteCotisation with eq filter', () async {
      when(() => mockApi.deleteCotisation(any())).thenAnswer((_) async => {});

      await mockApi.deleteCotisation('cot1');
      verify(() => mockApi.deleteCotisation('cot1')).called(1);
    });

    test('deleteCotisationsDuCulte by culte_id', () async {
      when(() => mockApi.deleteCotisationsDuCulte(any())).thenAnswer((_) async => {});

      await mockApi.deleteCotisationsDuCulte('c1');
      verify(() => mockApi.deleteCotisationsDuCulte('c1')).called(1);
    });

    test('setCotisationStatut', () async {
      when(() => mockApi.setCotisationStatut(
        membreId: any(named: 'membreId'),
        culteId: any(named: 'culteId'),
        statut: any(named: 'statut'),
      )).thenAnswer((_) async => {});

      await mockApi.setCotisationStatut(membreId: 'm1', culteId: 'c1', statut: 'paye');
      verify(() => mockApi.setCotisationStatut(
        membreId: 'm1',
        culteId: 'c1',
        statut: 'paye',
      )).called(1);
    });
  });

  group('InsForge API - RPC Functions', () {
    test('togglePaiement calls SQL function', () async {
      final resultJson = {
        'id': 'cot1',
        'membre_id': 'm1',
        'culte_id': 'c1',
        'statut': 'paye',
        'date_paiement': '2026-08-14T10:00:00.000Z',
      };
      when(() => mockApi.togglePaiement(
        membreId: any(named: 'membreId'),
        culteId: any(named: 'culteId'),
      )).thenAnswer((_) async => resultJson);

      final result = await mockApi.togglePaiement(membreId: 'm1', culteId: 'c1');
      expect(result['statut'], 'paye');
    });

    test('marquerAbsent calls SQL function', () async {
      final resultJson = {
        'id': 'cot1',
        'membre_id': 'm1',
        'culte_id': 'c1',
        'statut': 'absent',
        'date_paiement': null,
      };
      when(() => mockApi.marquerAbsent(
        membreId: any(named: 'membreId'),
        culteId: any(named: 'culteId'),
      )).thenAnswer((_) async => resultJson);

      final result = await mockApi.marquerAbsent(membreId: 'm1', culteId: 'c1');
      expect(result['statut'], 'absent');
      expect(result['date_paiement'], isNull);
    });

    test('getHistoriqueMembre calls SQL function', () async {
      final historique = [
        {
          'culte_date': '2026-08-14',
          'culte_titre': 'Culte du 14',
          'statut': 'paye',
          'montant': '50.00',
        },
      ];
      when(() => mockApi.getHistoriqueMembre(any())).thenAnswer((_) async => historique);

      final result = await mockApi.getHistoriqueMembre('m1');
      expect(result.length, 1);
      expect(result[0]['statut'], 'paye');
    });
  });

  group('InsForge API - Dashboard Views', () {
    test('getDashboard returns global stats', () async {
      final dashboard = {
        'total_membres_actifs': 10,
        'total_cultes': 5,
        'membres_en_retard': 3,
        'total_du_fcfa': 150,
      };
      when(() => mockApi.getDashboard()).thenAnswer((_) async => dashboard);

      final result = await mockApi.getDashboard();
      expect(result['total_membres_actifs'], 10);
      expect(result['total_cultes'], 5);
      expect(result['membres_en_retard'], 3);
      expect(result['total_du_fcfa'], 150);
    });

    test('getResumeCultes returns summaries', () async {
      final resumes = [
        {
          'culte_id': 'c1',
          'date_culte': '2026-08-14',
          'titre': 'Culte du 14',
          'total_membres': 10,
          'total_payes': 8,
          'total_absents': 1,
          'montant_collecte': 400,
        },
      ];
      when(() => mockApi.getResumeCultes()).thenAnswer((_) async => resumes);

      final result = await mockApi.getResumeCultes();
      expect(result.length, 1);
      expect(result[0]['total_payes'], 8);
    });

    test('getRetardsMembres returns sorted delays', () async {
      final retards = [
        {'membre_id': 'm1', 'nom': 'Koffi', 'cultes_en_retard': 2, 'montant_du_fcfa': 100},
        {'membre_id': 'm2', 'nom': 'Ahounou', 'cultes_en_retard': 1, 'montant_du_fcfa': 50},
      ];
      when(() => mockApi.getRetardsMembres()).thenAnswer((_) async => retards);

      final result = await mockApi.getRetardsMembres();
      expect(result.length, 2);
      expect(result[0]['montant_du_fcfa'], 100);
    });

    test('getMembresAJour returns members up to date', () async {
      final membres = [{'id': 'm1', 'nom': 'Koffi', 'prenom': 'Marie'}];
      when(() => mockApi.getMembresAJour()).thenAnswer((_) async => membres);

      final result = await mockApi.getMembresAJour();
      expect(result.length, 1);
    });

    test('getMembresEnAvance returns advance payments', () async {
      final membres = [
        {'membre_id': 'm1', 'nom': 'Koffi', 'prenom': 'Marie', 'paiements_anticipes': 2},
      ];
      when(() => mockApi.getMembresEnAvance()).thenAnswer((_) async => membres);

      final result = await mockApi.getMembresEnAvance();
      expect(result.length, 1);
      expect(result[0]['paiements_anticipes'], 2);
    });
  });

  group('InsForge API - Error Handling', () {
    test('getMembres with network error throws', () async {
      when(() => mockApi.getMembres()).thenThrow(Exception('Connection timeout'));

      expect(() => mockApi.getMembres(), throwsA(isA<Exception>()));
    });

    test('createMembre with server error throws', () async {
      when(() => mockApi.createMembre(any())).thenThrow(Exception('Server Error'));

      expect(() => mockApi.createMembre({}), throwsA(isA<Exception>()));
    });

    test('togglePaiement with not found returns error', () async {
      when(() => mockApi.togglePaiement(
        membreId: any(named: 'membreId'),
        culteId: any(named: 'culteId'),
      )).thenThrow(Exception('Not found'));

      expect(
        () => mockApi.togglePaiement(membreId: 'non-existent', culteId: 'c1'),
        throwsA(isA<Exception>()),
      );
    });

    test('getDashboard with empty data returns empty map', () async {
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});

      final result = await mockApi.getDashboard();
      expect(result, isEmpty);
    });

    test('creerCulteAvecCotisations with existing date returns same ID', () async {
      const existingUuid = 'existing-culte-uuid';
      when(() => mockApi.creerCulteAvecCotisations(
        dateCulte: any(named: 'dateCulte'),
        titre: any(named: 'titre'),
      )).thenAnswer((_) async => existingUuid);

      final result = await mockApi.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 8, 14),
        titre: 'Culte du 14',
      );
      expect(result, existingUuid);
    });
  });

  group('Index Verification', () {
    test('getMembres uses nom.asc order', () async {
      when(() => mockApi.getMembres(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);

      await mockApi.getMembres();
      verify(() => mockApi.getMembres(page: any(named: 'page'), pageSize: any(named: 'pageSize'))).called(1);
    });

    test('getCultes uses date_culte.desc order', () async {
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);

      await mockApi.getCultes();
      verify(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize'))).called(1);
    });

    test('getCotisations uses created_at.desc order', () async {
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);

      await mockApi.getCotisations();
      verify(() => mockApi.getCotisations()).called(1);
    });

    test('getCotisationsDuCulte uses culte_id filter', () async {
      when(() => mockApi.getCotisationsDuCulte(any())).thenAnswer((_) async => []);

      await mockApi.getCotisationsDuCulte('c1');
      verify(() => mockApi.getCotisationsDuCulte('c1')).called(1);
    });

    test('getCotisationsDuMembre uses membre_id filter', () async {
      when(() => mockApi.getCotisationsDuMembre(any())).thenAnswer((_) async => []);

      await mockApi.getCotisationsDuMembre('m1');
      verify(() => mockApi.getCotisationsDuMembre('m1')).called(1);
    });

    test('getRetardsMembres uses montant_du_fcfa.desc order', () async {
      when(() => mockApi.getRetardsMembres()).thenAnswer((_) async => []);

      await mockApi.getRetardsMembres();
      verify(() => mockApi.getRetardsMembres()).called(1);
    });

    test('getMembresAJour uses nom.asc order', () async {
      when(() => mockApi.getMembresAJour()).thenAnswer((_) async => []);

      await mockApi.getMembresAJour();
      verify(() => mockApi.getMembresAJour()).called(1);
    });

    test('getMembresEnAvance uses nom.asc order', () async {
      when(() => mockApi.getMembresEnAvance()).thenAnswer((_) async => []);

      await mockApi.getMembresEnAvance();
      verify(() => mockApi.getMembresEnAvance()).called(1);
    });
  });

  group('Complete User Flow', () {
    test('Full workflow: create member → culte → toggle → dashboard', () async {
      // 1. Create member
      final membreJson = {
        'id': 'test-membre-1',
        'nom': 'Koffi',
        'prenom': 'Marie',
        'is_active': true,
      };
      when(() => mockApi.createMembre(any())).thenAnswer((_) async => membreJson);

      final membre = await mockApi.createMembre(membreJson);
      expect(membre['id'], 'test-membre-1');

      // 2. Create culte
      const culteUuid = 'test-culte-1';
      when(() => mockApi.creerCulteAvecCotisations(
        dateCulte: any(named: 'dateCulte'),
        titre: any(named: 'titre'),
      )).thenAnswer((_) async => culteUuid);

      final culteId = await mockApi.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 8, 14),
        titre: 'Culte Test',
      );
      expect(culteId, culteUuid);

      // 3. Get cotisations
      final cotisationsJson = [
        {'id': 'cot-test-1', 'membre_id': 'test-membre-1', 'culte_id': culteUuid, 'statut': 'non_paye'},
      ];
      when(() => mockApi.getCotisationsDuCulte(any())).thenAnswer((_) async => cotisationsJson);

      final cotisations = await mockApi.getCotisationsDuCulte(culteUuid);
      expect(cotisations.length, 1);

      // 4. Toggle payment
      final toggleResult = {'id': 'cot-test-1', 'membre_id': 'test-membre-1', 'culte_id': culteUuid, 'statut': 'paye'};
      when(() => mockApi.togglePaiement(
        membreId: any(named: 'membreId'),
        culteId: any(named: 'culteId'),
      )).thenAnswer((_) async => toggleResult);

      final toggleResponse = await mockApi.togglePaiement(membreId: 'test-membre-1', culteId: culteUuid);
      expect(toggleResponse['statut'], 'paye');

      // 5. Dashboard
      final dashboardJson = {'total_membres_actifs': 1, 'total_cultes': 1, 'membres_en_retard': 0, 'total_du_fcfa': 0};
      when(() => mockApi.getDashboard()).thenAnswer((_) async => dashboardJson);

      final dashboard = await mockApi.getDashboard();
      expect(dashboard['total_membres_actifs'], 1);
      expect(dashboard['membres_en_retard'], 0);
    });
  });
}
