import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/insforge/insforge_config.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response {
  MockResponse({this.statusCode = 200, this.data});
  @override
  final int statusCode;
  @override
  final dynamic data;
  @override
  final Headers headers = Headers();
}

/// Test d'intégration complet pour la synchronisation offline → InsForge
void main() {
  late MockDio mockDio;
  late InsForgeService service;

  setUp(() {
    mockDio = MockDio();
    service = InsForgeService(dio: mockDio);
  });

  group('Synchronisation InsForge - Membres', () {
    test('createMembre appelle le bon endpoint avec payload complet', () async {
      final membreJson = {
        'id': 'membre-uuid',
        'nom': 'Koffi',
        'prenom': 'Marie',
        'date_adhesion': '2026-01-01',
        'telephone': '+229 97 00 00 01',
        'notes': 'Test membre',
        'is_active': true,
        'created_at': '2026-08-14T10:00:00.000Z',
        'updated_at': '2026-08-14T10:00:00.000Z',
      };

      final mockResponse = MockResponse(data: membreJson);
      when(() => mockDio.post(
        '/api/database/records/membres',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.createMembre(membreJson);

      expect(result['id'], 'membre-uuid');
      expect(result['nom'], 'Koffi');
      verify(() => mockDio.post(
        '/api/database/records/membres',
        data: [membreJson],
      )).called(1);
    });

    test('getMembres avec pagination utilise les bons queryParameters', () async {
      final membresJson = [
        {'id': 'm1', 'nom': 'Koffi', 'prenom': 'Marie', 'is_active': true},
        {'id': 'm2', 'nom': 'Ahounou', 'prenom': 'Paul', 'is_active': true},
      ];

      final mockResponse = MockResponse(data: membresJson);
      when(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getMembres(page: 1, pageSize: 100);

      expect(result.length, 2);
      verify(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: {
          'order': 'nom.asc',
          'is_active': 'eq.true',
          'limit': '100',
          'offset': '0',
        },
      )).called(1);
    });

    test('updateMembre utilise le filtre eq.$id', () async {
      final updates = {'nom': 'Koffi-Martin', 'notes': 'Modifié'};
      final mockResponse = MockResponse(data: {'id': 'm1', 'nom': 'Koffi-Martin', 'notes': 'Modifié'});
      when(() => mockDio.patch(
        '/api/database/records/membres',
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      await service.updateMembre('m1', updates);

      verify(() => mockDio.patch(
        '/api/database/records/membres',
        queryParameters: {'id': 'eq.m1'},
        data: updates,
      )).called(1);
    });

    test('deleteMembre utilise le filtre eq.$id', () async {
      final mockResponse = MockResponse();
      when(() => mockDio.delete(
        '/api/database/records/membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.deleteMembre('m1');

      verify(() => mockDio.delete(
        '/api/database/records/membres',
        queryParameters: {'id': 'eq.m1'},
      )).called(1);
    });

    test('getAllMembres paginé récupère toutes les pages', () async {
      final page1 = [
        {'id': 'm1', 'nom': 'A', 'prenom': 'Alice', 'is_active': true},
        {'id': 'm2', 'nom': 'B', 'prenom': 'Bob', 'is_active': true},
      ];
      final page2 = [
        {'id': 'm3', 'nom': 'C', 'prenom': 'Charlie', 'is_active': true},
      ];

      when(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: {'limit': '200', 'offset': '0'},
      )).thenAnswer((_) async => MockResponse(data: page1));
      when(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: {'limit': '200', 'offset': '200'},
      )).thenAnswer((_) async => MockResponse(data: page2));
      when(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: {'limit': '200', 'offset': '400'},
      )).thenAnswer((_) async => MockResponse(data: []));

      final result = await service.getAllMembres();

      expect(result.length, 3);
      expect(result.map((e) => e['id']).toList(), ['m1', 'm2', 'm3']);
    });
  });

  group('Synchronisation InsForge - Cultes', () {
    test('createCulte avec payload complet', () async {
      final culteJson = {
        'id': 'culte-uuid',
        'date_culte': '2026-08-21',
        'titre': 'Culte de Pentecôte',
        'montant_cotisation': 50.0,
        'created_at': '2026-08-14T10:00:00.000Z',
      };

      final mockResponse = MockResponse(data: culteJson);
      when(() => mockDio.post(
        '/api/database/records/cultes',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.createCulte(culteJson);

      expect(result['id'], 'culte-uuid');
      expect(result['date_culte'], '2026-08-21');
    });

    test('getCultes avec ordre décroissant', () async {
      final cultesJson = [
        {'id': 'c1', 'date_culte': '2026-08-14', 'titre': 'Culte A'},
        {'id': 'c2', 'date_culte': '2026-08-07', 'titre': 'Culte B'},
      ];

      final mockResponse = MockResponse(data: cultesJson);
      when(() => mockDio.get(
        '/api/database/records/cultes',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getCultes(page: 1, pageSize: 50);

      expect(result.length, 2);
      verify(() => mockDio.get(
        '/api/database/records/cultes',
        queryParameters: {
          'order': 'date_culte.desc',
          'limit': '50',
          'offset': '0',
        },
      )).called(1);
    });

    test('creerCulteAvecCotisations appelle la fonction RPC', () async {
      const culteUuid = 'new-culte-uuid';
      final mockResponse = MockResponse(data: culteUuid);
      when(() => mockDio.post(
        '/api/database/rpc/creer_culte_avec_cotisations',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 8, 21),
        titre: 'Culte du 21',
        montantCotisation: 50.0,
      );

      expect(result, culteUuid);
      verify(() => mockDio.post(
        '/api/database/rpc/creer_culte_avec_cotisations',
        data: {
          'p_date_culte': '2026-08-21',
          'p_titre': 'Culte du 21',
          'p_montant_cotisation': 50.0,
        },
      )).called(1);
    });

    test('deleteCulte utilise le filtre eq.$id', () async {
      final mockResponse = MockResponse();
      when(() => mockDio.delete(
        '/api/database/records/cultes',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.deleteCulte('c1');

      verify(() => mockDio.delete(
        '/api/database/records/cultes',
        queryParameters: {'id': 'eq.c1'},
      )).called(1);
    });
  });

  group('Synchronisation InsForge - Cotisations', () {
    test('createCotisations appelle le bon endpoint', () async {
      final cotisationsJson = [
        {'id': 'cot1', 'membre_id': 'm1', 'culte_id': 'c1', 'statut': 'non_paye'},
        {'id': 'cot2', 'membre_id': 'm2', 'culte_id': 'c1', 'statut': 'non_paye'},
      ];

      final mockResponse = MockResponse();
      when(() => mockDio.post(
        '/api/database/records/cotisations',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      await service.createCotisations(cotisationsJson);

      verify(() => mockDio.post(
        '/api/database/records/cotisations',
        data: cotisationsJson,
      )).called(1);
    });

    test('getCotisations avec ordre décroissant', () async {
      final cotisationsJson = [
        {'id': 'cot1', 'membre_id': 'm1', 'culte_id': 'c1', 'statut': 'paye'},
        {'id': 'cot2', 'membre_id': 'm2', 'culte_id': 'c1', 'statut': 'non_paye'},
      ];

      final mockResponse = MockResponse(data: cotisationsJson);
      when(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getCotisations();

      expect(result.length, 2);
      verify(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: {'order': 'created_at.desc'},
      )).called(1);
    });

    test('getCotisationsDuCulte filtre par culte_id', () async {
      final cotisationsJson = [
        {'id': 'cot1', 'membre_id': 'm1', 'culte_id': 'c1', 'statut': 'paye'},
      ];

      final mockResponse = MockResponse(data: cotisationsJson);
      when(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getCotisationsDuCulte('c1');

      expect(result.length, 1);
      verify(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: {'culte_id': 'eq.c1', 'order': 'created_at.desc'},
      )).called(1);
    });

    test('getCotisationsDuMembre filtre par membre_id', () async {
      final cotisationsJson = [
        {'id': 'cot1', 'membre_id': 'm1', 'culte_id': 'c1', 'statut': 'paye'},
        {'id': 'cot2', 'membre_id': 'm1', 'culte_id': 'c2', 'statut': 'non_paye'},
      ];

      final mockResponse = MockResponse(data: cotisationsJson);
      when(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getCotisationsDuMembre('m1');

      expect(result.length, 2);
      verify(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: {'membre_id': 'eq.m1', 'order': 'created_at.desc'},
      )).called(1);
    });

    test('updateCotisation utilise le filtre eq.$id', () async {
      final updates = {'statut': 'paye', 'date_paiement': '2026-08-14T10:00:00.000Z'};
      final mockResponse = MockResponse(data: {'id': 'cot1', ...updates});
      when(() => mockDio.patch(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      await service.updateCotisation('cot1', updates);

      verify(() => mockDio.patch(
        '/api/database/records/cotisations',
        queryParameters: {'id': 'eq.cot1'},
        data: updates,
      )).called(1);
    });

    test('deleteCotisation utilise le filtre eq.$id', () async {
      final mockResponse = MockResponse();
      when(() => mockDio.delete(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.deleteCotisation('cot1');

      verify(() => mockDio.delete(
        '/api/database/records/cotisations',
        queryParameters: {'id': 'eq.cot1'},
      )).called(1);
    });

    test('deleteCotisationsDuCulte supprime par culte_id', () async {
      final mockResponse = MockResponse();
      when(() => mockDio.delete(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.deleteCotisationsDuCulte('c1');

      verify(() => mockDio.delete(
        '/api/database/records/cotisations',
        queryParameters: {'culte_id': 'eq.c1'},
      )).called(1);
    });

    test('setCotisationStatut avec statut paye et date', () async {
      final mockResponse = MockResponse();
      when(() => mockDio.patch(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      await service.setCotisationStatut(
        membreId: 'm1',
        culteId: 'c1',
        statut: 'paye',
      );

      verify(() => mockDio.patch(
        '/api/database/records/cotisations',
        queryParameters: {
          'membre_id': 'eq.m1',
          'culte_id': 'eq.c1',
        },
        data: {
          'statut': 'paye',
          'date_paiement': any(named: 'date_paiement'),
        },
      )).called(1);
    });
  });

  group('Synchronisation InsForge - Fonctions RPC', () {
    test('togglePaiement appelle la fonction SQL', () async {
      final resultJson = {
        'id': 'cot1',
        'membre_id': 'm1',
        'culte_id': 'c1',
        'statut': 'paye',
        'date_paiement': '2026-08-14T10:00:00.000Z',
        'montant': '50.00',
      };

      final mockResponse = MockResponse(data: resultJson);
      when(() => mockDio.post(
        '/api/database/rpc/toggle_paiement',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.togglePaiement(
        membreId: 'm1',
        culteId: 'c1',
      );

      expect(result['statut'], 'paye');
      verify(() => mockDio.post(
        '/api/database/rpc/toggle_paiement',
        data: {'p_membre_id': 'm1', 'p_culte_id': 'c1'},
      )).called(1);
    });

    test('marquerAbsent appelle la fonction SQL', () async {
      final resultJson = {
        'id': 'cot1',
        'membre_id': 'm1',
        'culte_id': 'c1',
        'statut': 'absent',
        'date_paiement': null,
      };

      final mockResponse = MockResponse(data: resultJson);
      when(() => mockDio.post(
        '/api/database/rpc/marquer_absent',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.marquerAbsent(
        membreId: 'm1',
        culteId: 'c1',
      );

      expect(result['statut'], 'absent');
      expect(result['date_paiement'], isNull);
      verify(() => mockDio.post(
        '/api/database/rpc/marquer_absent',
        data: {'p_membre_id': 'm1', 'p_culte_id': 'c1'},
      )).called(1);
    });

    test('getHistoriqueMembre appelle la fonction SQL', () async {
      final historique = [
        {
          'culte_date': '2026-08-14',
          'culte_titre': 'Culte du 14',
          'statut': 'paye',
          'montant': '50.00',
          'date_paiement': '2026-08-14T10:00:00.000Z',
        },
        {
          'culte_date': '2026-08-07',
          'culte_titre': 'Culte du 7',
          'statut': 'non_paye',
          'montant': '50.00',
          'date_paiement': null,
        },
      ];

      final mockResponse = MockResponse(data: historique);
      when(() => mockDio.post(
        '/api/database/rpc/historique_membre',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getHistoriqueMembre('m1');

      expect(result.length, 2);
      expect(result[0]['statut'], 'paye');
      verify(() => mockDio.post(
        '/api/database/rpc/historique_membre',
        data: {'p_membre_id': 'm1'},
      )).called(1);
    });
  });

  group('Synchronisation InsForge - Vues calculées', () {
    test('getDashboard retourne les stats globales', () async {
      final dashboard = [
        {
          'total_membres_actifs': 10,
          'total_cultes': 5,
          'membres_en_retard': 3,
          'total_du_fcfa': 150,
          'dernier_culte_collecte': 250,
          'dernier_culte_date': '2026-08-14',
        },
      ];

      final mockResponse = MockResponse(data: dashboard);
      when(() => mockDio.get('/api/database/records/v_dashboard'))
          .thenAnswer((_) async => mockResponse);

      final result = await service.getDashboard();

      expect(result['total_membres_actifs'], 10);
      expect(result['total_cultes'], 5);
      expect(result['membres_en_retard'], 3);
      expect(result['total_du_fcfa'], 150);
    });

    test('getResumeCultes retourne les résumés par culte', () async {
      final resumes = [
        {
          'culte_id': 'c1',
          'date_culte': '2026-08-14',
          'titre': 'Culte du 14',
          'total_membres': 10,
          'total_payes': 8,
          'total_non_payes': 1,
          'total_absents': 1,
          'montant_collecte': 400,
          'montant_attendu': 500,
        },
      ];

      final mockResponse = MockResponse(data: resumes);
      when(() => mockDio.get(
        '/api/database/records/v_resume_culte',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getResumeCultes();

      expect(result.length, 1);
      expect(result[0]['total_payes'], 8);
      expect(result[0]['total_absents'], 1);
    });

    test('getRetardsMembres retourne les retards triés par montant', () async {
      final retards = [
        {
          'membre_id': 'm1',
          'nom': 'Koffi',
          'prenom': 'Marie',
          'cultes_en_retard': 2,
          'montant_du_fcfa': 100,
        },
        {
          'membre_id': 'm2',
          'nom': 'Ahounou',
          'prenom': 'Paul',
          'cultes_en_retard': 1,
          'montant_du_fcfa': 50,
        },
      ];

      final mockResponse = MockResponse(data: retards);
      when(() => mockDio.get(
        '/api/database/records/v_retards_membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getRetardsMembres();

      expect(result.length, 2);
      expect(result[0]['montant_du_fcfa'], 100); // Tri décroissant
      verify(() => mockDio.get(
        '/api/database/records/v_retards_membres',
        queryParameters: {'order': 'montant_du_fcfa.desc'},
      )).called(1);
    });

    test('getMembresAJour retourne les membres sans retard', () async {
      final membres = [
        {'id': 'm1', 'nom': 'Koffi', 'prenom': 'Marie'},
      ];

      final mockResponse = MockResponse(data: membres);
      when(() => mockDio.get(
        '/api/database/records/v_membres_a_jour',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getMembresAJour();

      expect(result.length, 1);
      verify(() => mockDio.get(
        '/api/database/records/v_membres_a_jour',
        queryParameters: {'order': 'nom.asc'},
      )).called(1);
    });

    test('getMembresEnAvance retourne les paiements anticipés', () async {
      final membres = [
        {
          'membre_id': 'm1',
          'nom': 'Koffi',
          'prenom': 'Marie',
          'paiements_anticipes': 2,
          'montant_anticipe': 100,
        },
      ];

      final mockResponse = MockResponse(data: membres);
      when(() => mockDio.get(
        '/api/database/records/v_membres_en_avance',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getMembresEnAvance();

      expect(result.length, 1);
      expect(result[0]['paiements_anticipes'], 2);
    });
  });

  group('Synchronisation InsForge - Erreurs et cas limites', () {
    test('getMembres avec erreur réseau lève DioException', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/test'), error: 'Connection timeout'));

      expect(() => service.getMembres(), throwsA(isA<DioException>()));
    });

    test('createMembre avec erreur serveur lève DioException', () async {
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 500,
        data: 'Server Error',
      );
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(response: mockResponse));

      expect(() => service.createMembre({}), throwsA(isA<DioException>()));
    });

    test('togglePaiement avec membre inexistant retourne erreur', () async {
      final mockResponse = MockResponse(
        statusCode: 404,
        data: {'message': 'Not found'},
      );
      when(() => mockDio.post(
        '/api/database/rpc/toggle_paiement',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      expect(
        () => service.togglePaiement(membreId: 'non-existent', culteId: 'c1'),
        throwsA(isA<DioException>()),
      );
    });

    test('getDashboard avec données vides retourne map vide', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get('/api/database/records/v_dashboard'))
          .thenAnswer((_) async => mockResponse);

      final result = await service.getDashboard();

      expect(result, isEmpty);
    });

    test('creerCulteAvecCotisations avec date existante retourne le même ID', () async {
      const existingUuid = 'existing-culte-uuid';
      final mockResponse = MockResponse(data: existingUuid);
      when(() => mockDio.post(
        '/api/database/rpc/creer_culte_avec_cotisations',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 8, 14),
        titre: 'Culte du 14',
      );

      expect(result, existingUuid);
    });
  });

  group('Vérification des index SQL utilisés dans le code', () {
    test('getMembres utilise l\'index idx_membres_nom via order: nom.asc', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getMembres();

      verify(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: {'order': 'nom.asc'},
      )).called(1);
    });

    test('getCultes utilise l\'index idx_cultes_date_culte via order: date_culte.desc', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/cultes',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getCultes();

      verify(() => mockDio.get(
        '/api/database/records/cultes',
        queryParameters: {'order': 'date_culte.desc'},
      )).called(1);
    });

    test('getCotisations utilise l\'index idx_cotisations_date_paiement via order: created_at.desc', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getCotisations();

      verify(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: {'order': 'created_at.desc'},
      )).called(1);
    });

    test('getCotisationsDuCulte utilise l\'index idx_cotisations_culte_id', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getCotisationsDuCulte('c1');

      verify(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: {'culte_id': 'eq.c1'},
      )).called(1);
    });

    test('getCotisationsDuMembre utilise l\'index idx_cotisations_membre_id', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getCotisationsDuMembre('m1');

      verify(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: {'membre_id': 'eq.m1'},
      )).called(1);
    });

    test('getRetardsMembres utilise l\'index via order: montant_du_fcfa.desc', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/v_retards_membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getRetardsMembres();

      verify(() => mockDio.get(
        '/api/database/records/v_retards_membres',
        queryParameters: {'order': 'montant_du_fcfa.desc'},
      )).called(1);
    });

    test('getMembresAJour utilise l\'index via order: nom.asc', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/v_membres_a_jour',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getMembresAJour();

      verify(() => mockDio.get(
        '/api/database/records/v_membres_a_jour',
        queryParameters: {'order': 'nom.asc'},
      )).called(1);
    });

    test('getMembresEnAvance utilise l\'index via order: nom.asc', () async {
      final mockResponse = MockResponse(data: []);
      when(() => mockDio.get(
        '/api/database/records/v_membres_en_avance',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      await service.getMembresEnAvance();

      verify(() => mockDio.get(
        '/api/database/records/v_membres_en_avance',
        queryParameters: {'order': 'nom.asc'},
      )).called(1);
    });
  });

  group('Test d\'intégration complet - Flux utilisateur', () {
    test('Flux complet: create membre → create culte → toggle paiement → dashboard', () async {
      // 1. Créer un membre
      final membreJson = {
        'id': 'test-membre-1',
        'nom': 'Koffi',
        'prenom': 'Marie',
        'date_adhesion': '2026-01-01',
        'is_active': true,
      };
      when(() => mockDio.post('/api/database/records/membres', data: any(named: 'data')))
          .thenAnswer((_) async => MockResponse(data: membreJson));

      final membre = await service.createMembre(membreJson);
      expect(membre['id'], 'test-membre-1');

      // 2. Créer un culte (génère auto les cotisations)
      const culteUuid = 'test-culte-1';
      when(() => mockDio.post('/api/database/rpc/creer_culte_avec_cotisations', data: any(named: 'data')))
          .thenAnswer((_) async => MockResponse(data: culteUuid));

      final culteId = await service.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 8, 14),
        titre: 'Culte Test',
      );
      expect(culteId, culteUuid);

      // 3. Récupérer les cotisations du culte
      final cotisationsJson = [
        {
          'id': 'cot-test-1',
          'membre_id': 'test-membre-1',
          'culte_id': culteUuid,
          'statut': 'non_paye',
          'montant': '50.00',
        },
      ];
      when(() => mockDio.get(
        '/api/database/records/cotisations',
        queryParameters: {'culte_id': 'eq.$culteUuid', 'order': 'created_at.desc'},
      )).thenAnswer((_) async => MockResponse(data: cotisationsJson));

      final cotisations = await service.getCotisationsDuCulte(culteUuid);
      expect(cotisations.length, 1);
      expect(cotisations[0]['statut'], 'non_paye');

      // 4. Toggle paiement
      final toggleResult = {
        'id': 'cot-test-1',
        'membre_id': 'test-membre-1',
        'culte_id': culteUuid,
        'statut': 'paye',
        'date_paiement': '2026-08-14T10:00:00.000Z',
      };
      when(() => mockDio.post(
        '/api/database/rpc/toggle_paiement',
        data: {'p_membre_id': 'test-membre-1', 'p_culte_id': culteUuid},
      )).thenAnswer((_) async => MockResponse(data: toggleResult));

      final toggleResponse = await service.togglePaiement(
        membreId: 'test-membre-1',
        culteId: culteUuid,
      );
      expect(toggleResponse['statut'], 'paye');

      // 5. Vérifier le dashboard
      final dashboardJson = [
        {
          'total_membres_actifs': 1,
          'total_cultes': 1,
          'membres_en_retard': 0,
          'total_du_fcfa': 0,
        },
      ];
      when(() => mockDio.get('/api/database/records/v_dashboard'))
          .thenAnswer((_) async => MockResponse(data: dashboardJson));

      final dashboard = await service.getDashboard();
      expect(dashboard['total_membres_actifs'], 1);
      expect(dashboard['membres_en_retard'], 0);
      expect(dashboard['total_du_fcfa'], 0);

      // 6. Vérifier les retards (doit être vide)
      final retardsJson = <Map<String, dynamic>>[];
      when(() => mockDio.get(
        '/api/database/records/v_retards_membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => MockResponse(data: retardsJson));

      final retards = await service.getRetardsMembres();
      expect(retards, isEmpty);
    });

    test('Flux avec multiple membres et cultes', () async {
      // Créer 3 membres
      final membresData = [
        {'id': 'm1', 'nom': 'Koffi', 'prenom': 'Marie', 'is_active': true},
        {'id': 'm2', 'nom': 'Ahounou', 'prenom': 'Paul', 'is_active': true},
        {'id': 'm3', 'nom': 'Dossou', 'prenom': 'Samuel', 'is_active': false},
      ];

      when(() => mockDio.post('/api/database/records/membres', data: any(named: 'data')))
          .thenAnswer((_) async => MockResponse(data: membresData[0]));

      for (final membre in membresData) {
        await service.createMembre(membre);
      }

      // Créer 2 cultes
      const culte1Uuid = 'c1';
      const culte2Uuid = 'c2';

      when(() => mockDio.post('/api/database/rpc/creer_culte_avec_cotisations', data: any(named: 'data')))
          .thenAnswer((invocation) async {
        final data = (invocation.namedArguments[#data] as Map? ?? {}) as Map<String, dynamic>;
        return MockResponse(data: data['p_date_culte'] == '2026-08-07' ? culte1Uuid : culte2Uuid);
      });

      await service.creerCulteAvecCotisations(dateCulte: DateTime(2026, 8, 7), titre: 'Culte 1');
      await service.creerCulteAvecCotisations(dateCulte: DateTime(2026, 8, 14), titre: 'Culte 2');

      // Vérifier le dashboard
      final dashboardJson = [
        {
          'total_membres_actifs': 2,
          'total_cultes': 2,
          'membres_en_retard': 0,
          'total_du_fcfa': 0,
        },
      ];
      when(() => mockDio.get('/api/database/records/v_dashboard'))
          .thenAnswer((_) async => MockResponse(data: dashboardJson));

      final dashboard = await service.getDashboard();
      expect(dashboard['total_membres_actifs'], 2);
      expect(dashboard['total_cultes'], 2);
    });
  });
}
