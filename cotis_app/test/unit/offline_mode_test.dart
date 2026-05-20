import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}
class MockLocalCache extends Mock implements LocalCache {}

// Custom AppData subclass to inject mocks and manage initial state
class TestAppData extends AppData {
  final AppState? initialState;
  final InsForgeService mockApi;
  final LocalCache mockCache;

  TestAppData({
    required this.mockApi,
    required this.mockCache,
    this.initialState,
  });

  @override
  Future<AppState> build() async {
    this.api = mockApi;
    this.cache = mockCache;
    return initialState ?? AppState(isOffline: true);
  }

  void setOffline(bool isOffline) {
    state = AsyncValue.data(state.value!.copyWith(isOffline: isOffline));
  }

  void updateLocalState(AppState newState) {
    state = AsyncValue.data(newState);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Membre());
    registerFallbackValue(Culte());
    registerFallbackValue(Cotisation());
    registerFallbackValue(SyncOperation());
    registerFallbackValue(CorbeilleItem());
  });

  group('Offline Mode Test Suite', () {
    late MockInsForgeService mockApi;
    late MockLocalCache mockCache;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();

      // Default mock behaviors for reads
      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);
      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => []);
      when(() => mockCache.getCorbeilleItem(any())).thenAnswer((_) async => null);

      // Default mock behaviors for writes
      when(() => mockCache.saveMembre(any())).thenAnswer((_) async => {});
      when(() => mockCache.saveAllMembres(any())).thenAnswer((_) async => {});
      when(() => mockCache.clearMembres()).thenAnswer((_) async => {});
      when(() => mockCache.deleteMembreById(any())).thenAnswer((_) async => {});

      when(() => mockCache.saveCulte(any())).thenAnswer((_) async => {});
      when(() => mockCache.saveAllCultes(any())).thenAnswer((_) async => {});
      when(() => mockCache.clearCultes()).thenAnswer((_) async => {});
      when(() => mockCache.deleteCulteById(any())).thenAnswer((_) async => {});

      when(() => mockCache.saveCotisation(any())).thenAnswer((_) async => {});
      when(() => mockCache.saveAllCotisations(any())).thenAnswer((_) async => {});
      when(() => mockCache.clearCotisations()).thenAnswer((_) async => {});
      when(() => mockCache.deleteCotisationsByCulteId(any())).thenAnswer((_) async => {});

      when(() => mockCache.saveSyncOp(any())).thenAnswer((_) async => {});
      when(() => mockCache.deleteSyncOp(any())).thenAnswer((_) async => {});

      when(() => mockCache.saveCorbeilleItem(any())).thenAnswer((_) async => {});
      when(() => mockCache.purgeOldCorbeilleItems(any())).thenAnswer((_) async => {});

      // Compound
      when(() => mockCache.deleteMembreAndSaveCorbeilleItem(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.deleteCulteAndCotisationsAndSaveCorbeilleItem(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.saveCulteWithCotisations(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.updateCulteAndCotisations(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.replaceAll(
        membres: any(named: 'membres'),
        cultes: any(named: 'cultes'),
        cotisations: any(named: 'cotisations'),
      )).thenAnswer((_) async => {});
      when(() => mockCache.restoreMembreAndDeleteCorbeilleItem(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.restoreCulteAndDeleteCorbeilleItem(any(), any())).thenAnswer((_) async => {});
    });

    group('Membres Offline Operations', () {
      test('Add Membre when offline: saves to cache and queues SyncOperation', () async {
        final notifier = TestAppData(mockApi: mockApi, mockCache: mockCache);
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.createMembre(any())).thenThrow(Exception('No Internet'));
        when(() => mockApi.getDashboard()).thenThrow(Exception('No Internet'));

        final membre = await container.read(appDataProvider.notifier).addMembre(
          nom: 'Turing',
          prenom: 'Alan',
          dateAdhesion: DateTime(2026, 1, 1),
          notes: 'Pionnier',
        );

        final state = container.read(appDataProvider).value!;
        expect(state.membres.length, equals(1));
        expect(state.membres.first.nom, equals('Turing'));
        expect(state.membres.first.id, equals(membre.id));

        verify(() => mockCache.saveMembre(any())).called(1);

        final capturedOp = verify(() => mockCache.saveSyncOp(captureAny())).captured.first as SyncOperation;
        expect(capturedOp.type, equals('CREATE'));
        expect(capturedOp.entityType, equals('membre'));
        expect(capturedOp.entityId, equals(membre.id));
        
        final payload = jsonDecode(capturedOp.payloadJson);
        expect(payload['nom'], equals('Turing'));
      });

      test('Update Membre when offline: saves to cache and queues SyncOperation', () async {
        final existingMembre = Membre()
          ..id = 'm-uuid'
          ..nom = 'Lovelace'
          ..prenom = 'Ada'
          ..dateAdhesion = DateTime(2026, 1, 1)
          ..isActive = true;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(membres: [existingMembre], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.updateMembre(any(), any())).thenThrow(Exception('No Internet'));

        await container.read(appDataProvider.notifier).updateMembre(
          id: 'm-uuid',
          nom: 'Lovelace-New',
          notes: 'Ada changed',
        );

        final state = container.read(appDataProvider).value!;
        expect(state.membres.first.nom, equals('Lovelace-New'));

        verify(() => mockCache.saveMembre(any())).called(1);

        final capturedOp = verify(() => mockCache.saveSyncOp(captureAny())).captured.first as SyncOperation;
        expect(capturedOp.type, equals('UPDATE'));
        expect(capturedOp.entityType, equals('membre'));
        expect(capturedOp.entityId, equals('m-uuid'));
      });

      test('Delete Membre when offline: soft deletes locally, inserts into corbeille, and queues SyncOperation', () async {
        final existingMembre = Membre()
          ..id = 'm-uuid-del'
          ..nom = 'Curie'
          ..prenom = 'Marie'
          ..dateAdhesion = DateTime(2026, 1, 1);

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(membres: [existingMembre], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.deleteMembre(any())).thenThrow(Exception('No Internet'));
        when(() => mockApi.getDashboard()).thenThrow(Exception('No Internet'));

        await container.read(appDataProvider.notifier).deleteMembre('m-uuid-del');

        final state = container.read(appDataProvider).value!;
        expect(state.membres, isEmpty);

        final args = verify(() => mockCache.deleteMembreAndSaveCorbeilleItem(captureAny(), captureAny())).captured;
        expect(args[0], equals('m-uuid-del'));
        final capturedCorbeille = args[1] as CorbeilleItem;
        expect(capturedCorbeille.entityId, equals('m-uuid-del'));
        expect(capturedCorbeille.entityType, equals('membre'));
        
        final payload = jsonDecode(capturedCorbeille.payloadJson);
        expect(payload['nom'], equals('Curie'));

        final capturedOp = verify(() => mockCache.saveSyncOp(captureAny())).captured.first as SyncOperation;
        expect(capturedOp.type, equals('DELETE'));
        expect(capturedOp.entityType, equals('membre'));
        expect(capturedOp.entityId, equals('m-uuid-del'));
      });
    });

    group('Cultes Offline Operations', () {
      test('Add Culte when offline: saves to cache, generates cotisations, and queues CREATE SyncOperations', () async {
        final m1 = Membre()
          ..id = 'm1'
          ..nom = 'Pascal'
          ..prenom = 'Blaise'
          ..dateAdhesion = DateTime(2026, 1, 1)
          ..isActive = true;
        final m2 = Membre()
          ..id = 'm2'
          ..nom = 'Descartes'
          ..prenom = 'Rene'
          ..dateAdhesion = DateTime(2026, 1, 1)
          ..isActive = false; 

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(membres: [m1, m2], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.createCulte(any())).thenThrow(Exception('No Internet'));
        when(() => mockApi.getDashboard()).thenThrow(Exception('No Internet'));

        await container.read(appDataProvider.notifier).addCulte(
          date: DateTime(2026, 5, 24),
          titre: 'Culte Pentecote',
          montant: 100.0,
        );

        final state = container.read(appDataProvider).value!;
        expect(state.cultes.length, equals(1));
        expect(state.cotisations.length, equals(1));
        expect(state.cotisations.first.membreId, equals('m1'));

        verify(() => mockCache.saveCulteWithCotisations(any(), any())).called(1);

        final capturedOps = verify(() => mockCache.saveSyncOp(captureAny())).captured;
        expect(capturedOps.length, equals(2));

        final opCulte = capturedOps[0] as SyncOperation;
        expect(opCulte.type, equals('CREATE'));
        expect(opCulte.entityType, equals('culte'));

        final opCotisation = capturedOps[1] as SyncOperation;
        expect(opCotisation.type, equals('CREATE'));
        expect(opCotisation.entityType, equals('cotisation'));
      });

      test('Update Culte when offline: updates locally and scales cotisation updates if amount changed', () async {
        final existingCulte = Culte()
          ..id = 'c-uuid'
          ..dateCulte = DateTime(2026, 5, 17)
          ..titre = 'Culte Dimanche'
          ..montantCotisation = 50.0;
        final linkedCot = Cotisation()
          ..id = 'cot-uuid'
          ..membreId = 'm1'
          ..culteId = 'c-uuid'
          ..montant = 50.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(
            cultes: [existingCulte],
            cotisations: [linkedCot],
            isOffline: true,
          ),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.updateCulte(any(), any())).thenThrow(Exception('No Internet'));
        when(() => mockApi.getDashboard()).thenThrow(Exception('No Internet'));

        await container.read(appDataProvider.notifier).updateCulte(
          id: 'c-uuid',
          titre: 'Culte Dimanche Modifie',
          montantCotisation: 75.0, 
        );

        final state = container.read(appDataProvider).value!;
        expect(state.cultes.first.montantCotisation, equals(75.0));
        expect(state.cotisations.first.montant, equals(75.0));

        verify(() => mockCache.updateCulteAndCotisations(any(), any())).called(1);

        final capturedOps = verify(() => mockCache.saveSyncOp(captureAny())).captured;
        expect(capturedOps.length, equals(2));
      });
    });

    group('Cotisations Offline Operations', () {
      test('Toggle payment status offline: optimistically toggles and queues SyncOperation', () async {
        final cot = Cotisation()
          ..id = 'cot-uuid'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..montant = 50.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(cotisations: [cot], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.togglePaiement(membreId: 'm1', culteId: 'c1')).thenThrow(Exception('No Internet'));

        await container.read(appDataProvider.notifier).togglePaiement(membreId: 'm1', culteId: 'c1');

        final state = container.read(appDataProvider).value!;
        expect(state.cotisations.first.statut, equals(StatutCotisation.paye));

        verify(() => mockCache.saveCotisation(any())).called(1);

        final capturedOp = verify(() => mockCache.saveSyncOp(captureAny())).captured.first as SyncOperation;
        expect(capturedOp.type, equals('UPDATE'));
        expect(capturedOp.entityType, equals('cotisation'));
      });

      test('Bulk set payments offline: sets status on all and queues individual UPDATE SyncOperations', () async {
        final cot1 = Cotisation()
          ..id = 'cot1'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..montant = 50.0
          ..statut = StatutCotisation.nonPaye;
        final cot2 = Cotisation()
          ..id = 'cot2'
          ..membreId = 'm2'
          ..culteId = 'c1'
          ..montant = 50.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(cotisations: [cot1, cot2], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.setCotisationStatut(
          membreId: any(named: 'membreId'),
          culteId: any(named: 'culteId'),
          statut: any(named: 'statut'),
        )).thenThrow(Exception('No Internet'));

        await container.read(appDataProvider.notifier).bulkSetPaiements(
          culteId: 'c1',
          newStatut: StatutCotisation.paye,
          membreIds: ['m1', 'm2'],
        );

        final state = container.read(appDataProvider).value!;
        expect(state.cotisations.every((c) => c.statut == StatutCotisation.paye), isTrue);

        verify(() => mockCache.saveAllCotisations(any())).called(1);

        final capturedOps = verify(() => mockCache.saveSyncOp(captureAny())).captured;
        expect(capturedOps.length, equals(2));
      });

      test('Mark absent offline: changes status to absent and queues SyncOperation', () async {
        final cot = Cotisation()
          ..id = 'cot-uuid'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..montant = 50.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(cotisations: [cot], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.marquerAbsent(membreId: 'm1', culteId: 'c1')).thenThrow(Exception('No Internet'));

        await container.read(appDataProvider.notifier).marquerAbsent(membreId: 'm1', culteId: 'c1');

        final state = container.read(appDataProvider).value!;
        expect(state.cotisations.first.statut, equals(StatutCotisation.absent));

        verify(() => mockCache.saveCotisation(any())).called(1);

        final capturedOp = verify(() => mockCache.saveSyncOp(captureAny())).captured.first as SyncOperation;
        expect(capturedOp.type, equals('UPDATE'));
        expect(capturedOp.entityType, equals('cotisation'));
      });
    });

    group('Reconnection and Sync Replay', () {
      test('Transition to online: plays back sync queue sequentially, fetches cloud data, and updates cache', () async {
        final op1 = SyncOperation()
          ..isarId = 101
          ..type = 'CREATE'
          ..entityType = 'membre'
          ..entityId = 'm-new'
          ..payloadJson = jsonEncode({'nom': 'Leibniz', 'prenom': 'Gottfried'})
          ..createdAt = DateTime(2026, 5, 20, 10, 0);

        final op2 = SyncOperation()
          ..isarId = 102
          ..type = 'UPDATE'
          ..entityType = 'cotisation'
          ..entityId = 'cot-upd'
          ..payloadJson = jsonEncode({'statut': 'paye'})
          ..createdAt = DateTime(2026, 5, 20, 10, 5);

        when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [op1, op2]);

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(isOffline: false), // online
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.createMembre(any())).thenAnswer((_) async => {});
        when(() => mockApi.updateCotisation(any(), any())).thenAnswer((_) async => {});

        when(() => mockApi.getAllMembres()).thenAnswer((_) async => [
          {'id': 'membre-1', 'nom': 'Leibniz', 'prenom': 'Gottfried', 'date_adhesion': '2024-01-01T00:00:00.000Z', 'is_active': true},
        ]);
        when(() => mockApi.getCultes(page: any(named: 'page'), pageSize: any(named: 'pageSize'))).thenAnswer((_) async => []);
        when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
        when(() => mockApi.getDashboard()).thenAnswer((_) async => {'stats': {}});

        await container.read(appDataProvider.notifier).syncData();

        verify(() => mockApi.createMembre(any())).called(1);
        verify(() => mockApi.updateCotisation('cot-upd', any())).called(1);

        verify(() => mockCache.deleteSyncOp(101)).called(1);
        verify(() => mockCache.deleteSyncOp(102)).called(1);

        verify(() => mockCache.replaceAll(
          membres: any(named: 'membres'),
          cultes: any(named: 'cultes'),
          cotisations: any(named: 'cotisations'),
        )).called(1);

        final state = container.read(appDataProvider).value!;
        expect(state.membres.length, equals(1));
        expect(state.membres.first.nom, equals('Leibniz'));
        expect(state.isLoading, isFalse);
      });

      test('Sync playback error: stops execution of queue to preserve sequential transaction order', () async {
        final op1 = SyncOperation()
          ..isarId = 101
          ..type = 'CREATE'
          ..entityType = 'membre'
          ..entityId = 'm-new'
          ..payloadJson = jsonEncode({'nom': 'Leibniz', 'prenom': 'Gottfried'})
          ..createdAt = DateTime(2026, 5, 20, 10, 0);

        final op2 = SyncOperation()
          ..isarId = 102
          ..type = 'UPDATE'
          ..entityType = 'cotisation'
          ..entityId = 'cot-upd'
          ..payloadJson = jsonEncode({'statut': 'paye'})
          ..createdAt = DateTime(2026, 5, 20, 10, 5);

        when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => [op1, op2]);

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          initialState: AppState(isOffline: false), // online
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.createMembre(any())).thenThrow(Exception('API Temporary Server Error'));

        await container.read(appDataProvider.notifier).syncData();

        verify(() => mockApi.createMembre(any())).called(1);
        verifyNever(() => mockApi.updateCotisation(any(), any()));
        verifyNever(() => mockCache.deleteSyncOp(any()));
      });
    });
  });
}
