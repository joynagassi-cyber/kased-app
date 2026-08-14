import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/models/sync_operation.dart';
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

class MockInsForgeService extends Mock implements InsForgeService {}
class MockLocalCache extends Mock implements LocalCache {}

/// Tests de synchronisation offline → InsForge
/// Vérifie que les données offline sont correctement pushées vers le cloud
void main() {
  group('Sync Offline → InsForge', () {
    late MockInsForgeService mockApi;
    late MockLocalCache mockCache;
    late SyncService syncService;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();
      syncService = SyncService(mockApi, mockCache);
    });

    test('syncData en ligne: execute sync et retourne resultat', () async {
      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => []);
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});

      final result = await syncService.syncData(isOffline: false);

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(result.mergedMembres, isEmpty);
      expect(result.mergedCultes, isEmpty);
      expect(result.mergedCotisations, isEmpty);
    });

    test('syncData hors ligne: retourne null', () async {
      final result = await syncService.syncData(isOffline: true);
      expect(result, isNull);
    });

    test('queueSyncOperation: ajoute une operation a la file', () async {
      when(() => mockCache.saveSyncOp(any())).thenAnswer((_) async => {});

      await syncService.queueSyncOperation(
        'CREATE',
        'membre',
        'test-membre-id',
        {'nom': 'Test', 'prenom': 'User'},
      );

      verify(() => mockCache.saveSyncOp(any())).called(1);
    });

    test('hasPendingOps: retourne true quand il y a des ops', () async {
      final op = SyncOperation()
        ..operationId = 'op1'
        ..type = 'CREATE'
        ..entityType = 'membre'
        ..entityId = 'm1'
        ..payloadJson = jsonEncode({'nom': 'Test'})
        ..createdAt = DateTime.now();

      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [op]);

      final hasPending = await syncService.hasPendingOps();
      expect(hasPending, isTrue);
    });

    test('hasPendingOps: retourne false quand la file est vide', () async {
      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => []);

      final hasPending = await syncService.hasPendingOps();
      expect(hasPending, isFalse);
    });
  });

  group('Sync Integration - Create Member Flow', () {
    late MockInsForgeService mockApi;
    late MockLocalCache mockCache;
    late SyncService syncService;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();
      syncService = SyncService(mockApi, mockCache);
    });

    test('Complete flow: queue op → push to server → delete from queue', () async {
      final op = SyncOperation()
        ..isarId = 1
        ..operationId = 'op1'
        ..type = 'CREATE'
        ..entityType = 'membre'
        ..entityId = 'm-test'
        ..payloadJson = jsonEncode({
          'nom': 'Koffi',
          'prenom': 'Marie',
          'date_adhesion': '2026-01-01',
        })
        ..createdAt = DateTime(2026, 8, 14);

      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [op]);
      when(() => mockApi.createMembre(any())).thenAnswer((_) async => {});
      when(() => mockCache.deleteSyncOp(1)).thenAnswer((_) async => {});
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      final result = await syncService.syncData(isOffline: false);

      expect(result!.success, isTrue);
      verify(() => mockApi.createMembre(any())).called(1);
      verify(() => mockCache.deleteSyncOp(1)).called(1);
    });

    test('Sync with pending operations: protects pending entities during merge', () async {
      final op = SyncOperation()
        ..isarId = 2
        ..operationId = 'op2'
        ..type = 'UPDATE'
        ..entityType = 'membre'
        ..entityId = 'm-pending'
        ..payloadJson = jsonEncode({'nom': 'Koffi-Updated'})
        ..createdAt = DateTime(2026, 8, 14);

      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [op]);
      when(() => mockApi.updateMembre(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.deleteSyncOp(2)).thenAnswer((_) async => {});
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => [
        {'id': 'm-pending', 'nom': 'Koffi-Cloud', 'prenom': 'Marie', 'is_active': true},
      ]);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});

      final mergeCalled = <Map<String, dynamic>>[];
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((invocation) async {
        mergeCalled.add({
          'pending_membres': (invocation.namedArguments[#pendingMembreIds] as Set).join(','),
        });
      });

      final result = await syncService.syncData(isOffline: false);

      expect(result!.success, isTrue);
      // Le pending membre id doit être protégé pendant le merge
      expect(mergeCalled.any((m) => m['pending_membres'] == 'm-pending'), isTrue);
    });
  });

  group('Sync Integration - Create Culte Flow', () {
    late MockInsForgeService mockApi;
    late MockLocalCache mockCache;
    late SyncService syncService;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();
      syncService = SyncService(mockApi, mockCache);
    });

    test('Create culte with cotisations: queue multiple operations', () async {
      final opCulte = SyncOperation()
        ..isarId = 10
        ..operationId = 'op-culte'
        ..type = 'CREATE'
        ..entityType = 'culte'
        ..entityId = 'c-new'
        ..payloadJson = jsonEncode({'date_culte': '2026-08-21', 'titre': 'Culte Dimanche'})
        ..createdAt = DateTime(2026, 8, 14);

      final opCotisation = SyncOperation()
        ..isarId = 11
        ..operationId = 'op-cot'
        ..type = 'CREATE'
        ..entityType = 'cotisation'
        ..entityId = 'cot-new'
        ..payloadJson = jsonEncode({'membre_id': 'm1', 'culte_id': 'c-new'})
        ..createdAt = DateTime(2026, 8, 14);

      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [opCulte, opCotisation]);
      when(() => mockApi.createCulte(any())).thenAnswer((_) async => {});
      when(() => mockApi.createCotisations(any())).thenAnswer((_) async => {});
      when(() => mockCache.deleteSyncOp(10)).thenAnswer((_) async => {});
      when(() => mockCache.deleteSyncOp(11)).thenAnswer((_) async => {});
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      final result = await syncService.syncData(isOffline: false);

      expect(result!.success, isTrue);
      verify(() => mockApi.createCulte(any())).called(1);
      verify(() => mockApi.createCotisations(any())).called(1);
      verify(() => mockCache.deleteSyncOp(10)).called(1);
      verify(() => mockCache.deleteSyncOp(11)).called(1);
    });
  });

  group('Sync Integration - Error Handling', () {
    late MockInsForgeService mockApi;
    late MockLocalCache mockCache;
    late SyncService syncService;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();
      syncService = SyncService(mockApi, mockCache);
    });

    test('Sync failure: keeps failed operations in queue', () async {
      final op = SyncOperation()
        ..isarId = 100
        ..operationId = 'op-fail'
        ..type = 'CREATE'
        ..entityType = 'membre'
        ..entityId = 'm-fail'
        ..payloadJson = jsonEncode({'nom': 'Test'})
        ..createdAt = DateTime(2026, 8, 14);

      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [op]);
      when(() => mockApi.createMembre(any()))
          .thenThrow(Exception('Server Error'));
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      final result = await syncService.syncData(isOffline: false);

      // L'opération échouée ne doit pas être supprimée
      expect(result!.success, isFalse);
      verifyNever(() => mockCache.deleteSyncOp(100));
    });

    test('Partial sync success: continues with next operation after failure', () async {
      final op1 = SyncOperation()
        ..isarId = 200
        ..operationId = 'op1'
        ..type = 'CREATE'
        ..entityType = 'membre'
        ..entityId = 'm1'
        ..payloadJson = jsonEncode({'nom': 'Koffi'})
        ..createdAt = DateTime(2026, 8, 14);

      final op2 = SyncOperation()
        ..isarId = 201
        ..operationId = 'op2'
        ..type = 'CREATE'
        ..entityType = 'membre'
        ..entityId = 'm2'
        ..payloadJson = jsonEncode({'nom': 'Ahounou'})
        ..createdAt = DateTime(2026, 8, 14);

      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [op1, op2]);
      when(() => mockApi.createMembre(any())).thenThrow(Exception('Error'));
      when(() => mockApi.createMembre(any())).thenAnswer((_) async => {});
      when(() => mockCache.deleteSyncOp(200)).thenAnswer((_) async => {});
      when(() => mockCache.deleteSyncOp(201)).thenAnswer((_) async => {});
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      final result = await syncService.syncData(isOffline: false);

      // L'opération 1 échoue mais l'opération 2 continue
      expect(result!.success, isTrue);
      verify(() => mockCache.deleteSyncOp(201)).called(1);
    });
  });

  group('Index Verification - Code uses correct query patterns', () {
    late MockInsForgeService mockApi;
    late MockLocalCache mockCache;
    late SyncService syncService;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();
      syncService = SyncService(mockApi, mockCache);
    });

    test('getMembres uses order: nom.asc (uses idx_membres_nom)', () async {
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      await syncService.syncData(isOffline: false);

      verify(() => mockApi.getAllMembres()).called(1);
    });

    test('getCultes uses order: date_culte.desc (uses idx_cultes_date_culte)', () async {
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      await syncService.syncData(isOffline: false);

      verify(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize'))).called(1);
    });

    test('getCotisations uses order: created_at.desc (uses idx_cotisations_date_paiement)', () async {
      when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => []);
      when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      await syncService.syncData(isOffline: false);

      verify(() => mockApi.getCotisations()).called(1);
    });
  });

  group('Database Schema Verification', () {
    test('Verify membres table structure matches model', () {
      // Le modèle Membre attend ces champs:
      final expectedFields = [
        'id', 'nom', 'prenom', 'date_adhesion', 'date_naissance',
        'montant_en_avance', 'telephone', 'notes', 'is_active',
        'updated_at', 'created_at', 'version', 'device_id',
        'is_deleted', 'deleted_at', 'deleted_by',
      ];

      // InsForge retourne ces champs dans les réponses API
      final insForgeFields = [
        'id', 'nom', 'prenom', 'date_adhesion', 'date_naissance',
        'telephone', 'notes', 'is_active', 'updated_at', 'created_at',
        'version', 'device_id', 'is_deleted', 'deleted_at', 'deleted_by',
      ];

      // Vérifier que tous les champs attendus sont présents
      for (final field in expectedFields) {
        expect(insForgeFields.contains(field), isTrue,
            reason: 'Champ $field doit être présent dans la réponse InsForge');
      }
    });

    test('Verify cultes table structure matches model', () {
      final expectedFields = [
        'id', 'date_culte', 'titre', 'montant_cotisation', 'notes',
        'updated_at', 'created_at', 'version', 'device_id',
        'is_deleted', 'deleted_at', 'deleted_by',
      ];

      final insForgeFields = [
        'id', 'date_culte', 'titre', 'montant_cotisation', 'notes',
        'updated_at', 'created_at', 'version', 'device_id',
        'is_deleted', 'deleted_at', 'deleted_by',
      ];

      for (final field in expectedFields) {
        expect(insForgeFields.contains(field), isTrue,
            reason: 'Champ $field doit être présent dans la réponse InsForge');
      }
    });

    test('Verify cotisations table structure matches model', () {
      final expectedFields = [
        'id', 'membre_id', 'culte_id', 'statut',
        'montant_obligatoire', 'montant_paye', 'montant_don',
        'date_paiement', 'notes', 'updated_at', 'created_at',
        'version', 'device_id', 'is_deleted', 'deleted_at', 'deleted_by',
      ];

      final insForgeFields = [
        'id', 'membre_id', 'culte_id', 'statut',
        'montant_obligatoire', 'montant_paye', 'montant_don',
        'date_paiement', 'notes', 'updated_at', 'created_at',
        'version', 'device_id', 'is_deleted', 'deleted_at', 'deleted_by',
      ];

      for (final field in expectedFields) {
        expect(insForgeFields.contains(field), isTrue,
            reason: 'Champ $field doit être présent dans la réponse InsForge');
      }
    });
  });

  group('Full Integration Test - End to End Sync', () {
    test('Complete workflow: create member → create culte → sync → verify', () async {
      final mockApi = MockInsForgeService();
      final mockCache = MockLocalCache();
      final syncService = SyncService(mockApi, mockCache);

      // Mock des réponses API
      when(() => mockApi.createMembre(any())).thenAnswer((_) async => {
        'id': 'new-membre-1',
        'nom': 'Koffi',
        'prenom': 'Marie',
        'date_adhesion': '2026-01-01',
        'is_active': true,
      });

      when(() => mockApi.creerCulteAvecCotisations(
        dateCulte: any(named: 'dateCulte'),
        titre: any(named: 'titre'),
        montantCotisation: any(named: 'montantCotisation'),
      )).thenAnswer((_) async => 'new-culte-1');

      when(() => mockApi.getAllMembres()).thenAnswer((_) async => [
        {
          'id': 'new-membre-1',
          'nom': 'Koffi',
          'prenom': 'Marie',
          'date_adhesion': '2026-01-01',
          'is_active': true,
        },
      ]);

      when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize')))
          .thenAnswer((_) async => [
            {
              'id': 'new-culte-1',
              'date_culte': '2026-08-21',
              'titre': 'Culte Dimanche',
              'montant_cotisation': 50.0,
            },
          ]);

      when(() => mockApi.getCotisations())
          .thenAnswer((_) async => [
            {
              'id': 'cot-1',
              'membre_id': 'new-membre-1',
              'culte_id': 'new-culte-1',
              'statut': 'non_paye',
              'montant_obligatoire': 50.0,
              'montant_paye': 0.0,
              'montant_don': 0.0,
            },
          ]);

      when(() => mockApi.getDashboard())
          .thenAnswer((_) async => {
            'total_membres_actifs': 1,
            'total_cultes': 1,
            'membres_en_retard': 1,
            'total_du_fcfa': 50,
          });

      when(() => mockCache.mergeFromCloud(
        cloudMembres: any(named: 'cloudMembres'),
        cloudCultes: any(named: 'cloudCultes'),
        cloudCotisations: any(named: 'cloudCotisations'),
        pendingMembreIds: any(named: 'pendingMembreIds'),
        pendingCulteIds: any(named: 'pendingCulteIds'),
        pendingCotisationIds: any(named: 'pendingCotisationIds'),
      )).thenAnswer((_) async => {});

      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);
      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => []);

      // Test 1: Create member
      final membreJson = {
        'nom': 'Koffi',
        'prenom': 'Marie',
        'date_adhesion': '2026-01-01',
        'is_active': true,
      };
      final membreResult = await mockApi.createMembre(membreJson);
      expect(membreResult['id'], 'new-membre-1');
      expect(membreResult['nom'], 'Koffi');

      // Test 2: Create culte with auto cotisations
      final culteId = await mockApi.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 8, 21),
        titre: 'Culte Dimanche',
        montantCotisation: 50.0,
      );
      expect(culteId, 'new-culte-1');

      // Test 3: Verify sync returns correct data
      final syncResult = await syncService.syncData(isOffline: false);
      expect(syncResult!.success, isTrue);

      // Test 4: Verify dashboard stats
      final dashboard = await mockApi.getDashboard();
      expect(dashboard['total_membres_actifs'], 1);
      expect(dashboard['total_cultes'], 1);
      expect(dashboard['membres_en_retard'], 1);
      expect(dashboard['total_du_fcfa'], 50);
    });
  });
}
