import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/controllers/membre_controller.dart';
import 'package:kased_app/controllers/culte_controller.dart';
import 'package:kased_app/controllers/cotisation_controller.dart';
import 'package:kased_app/controllers/system_controller.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}
class MockLocalCache extends Mock implements LocalCache {}

/// Stub cache that persists data in-memory for tests that need cross-call state.
class StubLocalCache implements LocalCache {
  final List<Membre> _membres = [];
  final List<Culte> _cultes = [];
  final List<Cotisation> _cotisations = [];
  final List<SyncOperation> _syncOps = [];
  final Map<int, CorbeilleItem> _corbeille = {};

  @override
  Future<List<Membre>> getAllMembres() async => List.from(_membres);
  @override
  Future<List<Culte>> getAllCultes() async => List.from(_cultes);
  @override
  Future<List<Cotisation>> getAllCotisations() async => List.from(_cotisations);
  @override
  Future<List<SyncOperation>> getPendingSyncOps() async => List.from(_syncOps);

  @override
  Future<void> saveMembre(Membre m) async {
    final idx = _membres.indexWhere((e) => e.id == m.id);
    if (idx >= 0) _membres[idx] = m; else _membres.add(m);
  }
  @override
  Future<void> deleteMembreById(String id) async { _membres.removeWhere((e) => e.id == id); }

  @override
  Future<void> saveCulte(Culte c) async {
    final idx = _cultes.indexWhere((e) => e.id == c.id);
    if (idx >= 0) _cultes[idx] = c; else _cultes.add(c);
  }
  @override
  Future<void> deleteCulteById(String id) async { _cultes.removeWhere((e) => e.id == id); }

  @override
  Future<void> saveCotisation(Cotisation c) async {
    final idx = _cotisations.indexWhere((e) => e.id == c.id);
    if (idx >= 0) _cotisations[idx] = c; else _cotisations.add(c);
  }
  @override
  Future<void> saveAllCotisations(List<Cotisation> list) async { _cotisations.clear(); _cotisations.addAll(list); }
  @override
  Future<void> deleteCotisationsByCulteId(String culteId) async {
    _cotisations.removeWhere((e) => e.culteId == culteId);
  }

  @override
  Future<void> saveSyncOp(SyncOperation op) async { _syncOps.add(op); }
  @override
  Future<void> deleteSyncOp(int isarId) async { _syncOps.removeWhere((e) => e.isarId == isarId); }

  @override
  Future<CorbeilleItem?> getCorbeilleItem(int isarId) async => _corbeille[isarId];
  @override
  Future<void> saveCorbeilleItem(CorbeilleItem item) async {
    _corbeille[item.isarId] = item;
  }
  @override
  Future<void> purgeOldCorbeilleItems(DateTime before) async {
    _corbeille.removeWhere((k, v) => v.deletedAt.isBefore(before));
  }
  @override
  Future<void> deleteCorbeilleItem(int isarId) async { _corbeille.remove(isarId); }
  @override
  Future<void> deleteAllCorbeilleItems() async { _corbeille.clear(); }

  @override
  Future<void> restoreMembreAndDeleteCorbeilleItem(Membre membre, int corbeilleIsarId) async {
    await saveMembre(membre);
    _corbeille.remove(corbeilleIsarId);
  }
  @override
  Future<void> restoreCulteAndDeleteCorbeilleItem(Culte culte, int corbeilleIsarId) async {
    await saveCulte(culte);
    _corbeille.remove(corbeilleIsarId);
  }
  @override
  Future<void> deleteMembreAndSaveCorbeilleItem(String id, CorbeilleItem item) async {
    _membres.removeWhere((e) => e.id == id);
    await saveCorbeilleItem(item);
  }
  @override
  Future<void> deleteCulteAndCotisationsAndSaveCorbeilleItem(String culteId, CorbeilleItem item) async {
    _cultes.removeWhere((e) => e.id == culteId);
    _cotisations.removeWhere((e) => e.culteId == culteId);
    await saveCorbeilleItem(item);
  }
  @override
  Future<void> saveCulteWithCotisations(Culte culte, List<Cotisation> cotisations) async {
    final idx = _cultes.indexWhere((e) => e.id == culte.id);
    if (idx >= 0) _cultes[idx] = culte; else _cultes.add(culte);
    _cotisations.addAll(cotisations);
  }
  @override
  Future<void> updateCulteAndCotisations(Culte culte, List<Cotisation>? cotisationsToUpdate) async {
    final idx = _cultes.indexWhere((e) => e.id == culte.id);
    if (idx >= 0) _cultes[idx] = culte; else _cultes.add(culte);
    if (cotisationsToUpdate != null) {
      for (final c in cotisationsToUpdate) {
        final cIdx = _cotisations.indexWhere((e) => e.id == c.id);
        if (cIdx >= 0) _cotisations[cIdx] = c; else _cotisations.add(c);
      }
    }
  }
  @override
  Future<void> replaceAll({required List<Membre> membres, required List<Culte> cultes, required List<Cotisation> cotisations}) async {
    _membres.clear(); _membres.addAll(membres);
    _cultes.clear(); _cultes.addAll(cultes);
    _cotisations.clear(); _cotisations.addAll(cotisations);
  }
  @override
  Future<void> mergeFromCloud({required List<Membre> cloudMembres, required List<Culte> cloudCultes, required List<Cotisation> cloudCotisations, required Set<String> pendingMembreIds, required Set<String> pendingCulteIds, required Set<String> pendingCotisationIds}) async {
    _membres.clear(); _membres.addAll(cloudMembres);
    _cultes.clear(); _cultes.addAll(cloudCultes);
    _cotisations.clear(); _cotisations.addAll(cloudCotisations);
  }
  @override
  Future<void> saveMembreWithSyncOp(Membre membre, SyncOperation op) async {
    await saveMembre(membre);
    await saveSyncOp(op);
  }
  @override
  Future<void> saveCulteWithSyncOp(Culte culte, SyncOperation op) async {
    await saveCulte(culte);
    await saveSyncOp(op);
  }
  @override
  Future<void> saveCotisationWithSyncOp(Cotisation cotisation, SyncOperation op) async {
    await saveCotisation(cotisation);
    await saveSyncOp(op);
  }
  @override
  Future<void> softDeleteMembreWithSyncOp(Membre membre, SyncOperation op) async {
    await saveMembre(membre);
    await saveSyncOp(op);
  }
  @override
  Future<void> softDeleteCulteWithSyncOp(Culte culte, List<Cotisation> cotisations, SyncOperation op) async {
    await saveCulte(culte);
    for (final c in cotisations) await saveCotisation(c);
    await saveSyncOp(op);
  }
  @override
  Future<void> restoreMembreWithSyncOp(Membre membre, SyncOperation op) async {
    await saveMembre(membre);
    await saveSyncOp(op);
  }
  @override
  Future<void> restoreCulteWithSyncOp(Culte culte, SyncOperation op) async {
    await saveCulte(culte);
    await saveSyncOp(op);
  }
}

// Custom AppData subclass to inject mocks and manage initial state
class TestAppData extends AppData {
  final AppState? initialState;
  final InsForgeService mockApi;
  final LocalCache mockCache;
  final DeviceServicePort mockDeviceService;

  TestAppData({
    required this.mockApi,
    required this.mockCache,
    required this.mockDeviceService,
    this.initialState,
  });

  @override
  Future<AppState> build() async {
    this.api = mockApi;
    this.cache = mockCache;
    final syncSvc = SyncService(mockApi, mockCache);
    this.syncService = syncSvc;
    this.statsService = StatsService();
    this.deviceServicePort = mockDeviceService;
    this.statsService = StatsService();

    // Initialize controllers for member/culte operations
    final ss = StatsService();
    this.membreController = MembreController(
      cache: mockCache,
      api: mockApi,
      syncService: syncSvc,
      deviceService: mockDeviceService,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );
    this.culteController = CulteController(
      cache: mockCache,
      api: mockApi,
      syncService: syncSvc,
      deviceService: mockDeviceService,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );
    this.cotisationController = CotisationController(
      cache: mockCache,
      api: mockApi,
      deviceService: mockDeviceService,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );
    this.systemController = SystemController(
      cache: mockCache,
      api: mockApi,
      syncService: syncSvc,
      statsService: ss,
      onStateChanged: (appState) => state = AsyncValue.data(appState),
    );

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
    late FakeDeviceService mockDeviceService;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();
      mockDeviceService = FakeDeviceService(deviceId: 'test-device-123');

      // Default mock behaviors for reads
      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);
      when(() => mockCache.getPendingSyncOps()).thenAnswer((_) async => []);
      when(() => mockCache.getCorbeilleItem(any())).thenAnswer((_) async => null);

      // Default mock behaviors for writes
      when(() => mockCache.saveMembreWithSyncOp(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.softDeleteMembreWithSyncOp(any(), any())).thenAnswer((_) async => {});

      when(() => mockCache.saveCulteWithSyncOp(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.softDeleteCulteWithSyncOp(any(), any(), any())).thenAnswer((_) async => {});

      when(() => mockCache.saveCotisationWithSyncOp(any(), any())).thenAnswer((_) async => {});
      when(() => mockCache.saveCotisation(any())).thenAnswer((_) async => {});
      when(() => mockCache.saveAllCotisations(any())).thenAnswer((_) async => {});
      when(() => mockCache.deleteCotisationsByCulteId(any())).thenAnswer((_) async => {});
      when(() => mockCache.saveSyncOp(any())).thenAnswer((_) async => {});

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
        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
        );
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

        verify(() => mockCache.saveMembreWithSyncOp(any(), any())).called(1);
      });      test('Update Membre when offline: saves to cache and queues SyncOperation', () async {
        final existingMembre = Membre()
          ..id = 'm-uuid'
          ..nom = 'Lovelace'
          ..prenom = 'Ada'
          ..dateAdhesion = DateTime(2026, 1, 1)
          ..isActive = true;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
          initialState: AppState(membres: [existingMembre], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.updateMembre(any(), any())).thenThrow(Exception('No Internet'));
        when(() => mockCache.getAllMembres()).thenAnswer((_) async => [existingMembre]);

        await container.read(appDataProvider.notifier).updateMembre(
          id: 'm-uuid',
          nom: 'Lovelace-New',
          notes: 'Ada changed',
        );

        final state = container.read(appDataProvider).value!;
        expect(state.membres.first.nom, equals('Lovelace-New'));

        verify(() => mockCache.saveMembreWithSyncOp(any(), any())).called(1);

        // Vérifier que la SyncOp est bien enregistrée
      });

      test('Delete Membre when offline: soft deletes locally, inserts into SyncQueue', () async {
        final existingMembre = Membre()
          ..id = 'm-uuid-del'
          ..nom = 'Curie'
          ..prenom = 'Marie'
          ..dateAdhesion = DateTime(2026, 1, 1);

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
          initialState: AppState(membres: [existingMembre], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.deleteMembre(any())).thenThrow(Exception('No Internet'));
        when(() => mockApi.getDashboard()).thenThrow(Exception('No Internet'));
        when(() => mockCache.getAllMembres()).thenAnswer((_) async => [existingMembre]);

        await container.read(appDataProvider.notifier).deleteMembre('m-uuid-del');

        final state = container.read(appDataProvider).value!;
        expect(state.membres, isEmpty);

        verify(() => mockCache.softDeleteMembreWithSyncOp(any(), any())).called(1);
      });

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
          mockDeviceService: mockDeviceService,
          initialState: AppState(membres: [m1, m2], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        when(() => mockApi.createCulte(any())).thenThrow(Exception('No Internet'));
        when(() => mockApi.getDashboard()).thenThrow(Exception('No Internet'));
        when(() => mockCache.getAllMembres()).thenAnswer((_) async => [m1, m2]);
        when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);
        when(() => mockCache.getAllCotisations()).thenAnswer((_) async => [
          Cotisation()
            ..id = 'cot1'
            ..membreId = 'm1'
            ..culteId = 'new-culte-id'
            ..statut = StatutCotisation.nonPaye,
        ]);

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
          ..dateCulte = DateTime(2026, 8, 20) // dans le futur (< 30 jours)
          ..titre = 'Culte Dimanche'
          ..montantCotisation = 50.0;
        final linkedCot = Cotisation()
          ..id = 'cot-uuid'
          ..membreId = 'm1'
          ..culteId = 'c-uuid'
          ..montantObligatoire = 50.0
          ..montantPaye = 0.0
          ..montantDon = 0.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
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
        expect(state.cotisations.first.montantObligatoire, equals(75.0));

        verify(() => mockCache.updateCulteAndCotisations(any(), any())).called(1);

        final capturedOps = verify(() => mockCache.saveSyncOp(captureAny())).captured;
        expect(capturedOps.length, equals(2));
      });

      test('Update Culte when older than 30 days: throws exception', () async {
        final existingCulte = Culte()
          ..id = 'c-locked'
          ..dateCulte = DateTime(2026, 5, 1) // > 30 jours dans le passé
          ..titre = 'Culte ancien'
          ..montantCotisation = 50.0;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
          initialState: AppState(
            cultes: [existingCulte],
            cotisations: [],
            isOffline: true,
          ),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        await expectLater(
          () => container.read(appDataProvider.notifier).updateCulte(
                id: 'c-locked',
                montantCotisation: 75.0,
              ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Cotisations Offline Operations', () {
      test('Toggle payment status offline: optimistically toggles and queues SyncOperation', () async {
        final cot = Cotisation()
          ..id = 'cot-uuid'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..montantObligatoire = 50.0
          ..montantPaye = 0.0
          ..montantDon = 0.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
          initialState: AppState(
            cultes: [
              Culte()
                ..id = 'c1'
                ..titre = 'Culte Test'
                ..montantCotisation = 50.0
                ..dateCulte = DateTime.now(),
            ],
            cotisations: [cot],
            isOffline: true,
          ),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        // togglePaiement appelle en interne enregistrerPaiementPersonnel qui
        // utilise _api.createCotisations (cas nouveau) ou updateCotisation.
        when(() => mockApi.updateCotisation(any(), any())).thenThrow(Exception('No Internet'));

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
          ..montantObligatoire = 50.0
          ..montantPaye = 0.0
          ..montantDon = 0.0
          ..statut = StatutCotisation.nonPaye;
        final cot2 = Cotisation()
          ..id = 'cot2'
          ..membreId = 'm2'
          ..culteId = 'c1'
          ..montantObligatoire = 50.0
          ..montantPaye = 0.0
          ..montantDon = 0.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
          initialState: AppState(cotisations: [cot1, cot2], isOffline: true),
        );
        final container = ProviderContainer(
          overrides: [appDataProvider.overrideWith(() => notifier)],
        );
        addTearDown(container.dispose);
        await container.read(appDataProvider.future);

        // bulkSetPaiements appelle _api.updateCotisation pour chaque cotisation.
        when(() => mockApi.updateCotisation(any(), any())).thenThrow(Exception('No Internet'));

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
          ..montantObligatoire = 50.0
          ..montantPaye = 0.0
          ..montantDon = 0.0
          ..statut = StatutCotisation.nonPaye;

        final notifier = TestAppData(
          mockApi: mockApi,
          mockCache: mockCache,
          mockDeviceService: mockDeviceService,
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
          mockDeviceService: mockDeviceService,
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
        when(() => mockCache.mergeFromCloud(
          cloudMembres: any(named: 'cloudMembres'),
          cloudCultes: any(named: 'cloudCultes'),
          cloudCotisations: any(named: 'cloudCotisations'),
          pendingMembreIds: any(named: 'pendingMembreIds'),
          pendingCulteIds: any(named: 'pendingCulteIds'),
          pendingCotisationIds: any(named: 'pendingCotisationIds'),
        )).thenAnswer((invocation) async {
          // Stocker dans le cache mock pour que getAllMembres le retourne
          final membres = (invocation.namedArguments[#cloudMembres] as List).map((e) => e as Membre).toList();
          when(() => mockCache.getAllMembres()).thenAnswer((_) async => membres);
          when(() => mockCache.getAllCultes()).thenAnswer((_) async => []);
          when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);
        });

        await container.read(appDataProvider.notifier).syncData();

        verify(() => mockApi.createMembre(any())).called(1);
        verify(() => mockApi.updateCotisation('cot-upd', any())).called(1);

        verify(() => mockCache.deleteSyncOp(101)).called(1);
        verify(() => mockCache.deleteSyncOp(102)).called(1);

        verify(() => mockCache.mergeFromCloud(
          cloudMembres: any(named: 'cloudMembres'),
          cloudCultes: any(named: 'cloudCultes'),
          cloudCotisations: any(named: 'cloudCotisations'),
          pendingMembreIds: any(named: 'pendingMembreIds'),
          pendingCulteIds: any(named: 'pendingCulteIds'),
          pendingCotisationIds: any(named: 'pendingCotisationIds'),
        )).called(1);

        final state = container.read(appDataProvider).value!;
        expect(state.membres.length, equals(1));
        expect(state.membres.first.nom, equals('Leibniz'));
        expect(state.isLoading, isFalse);
      });

      test(
        'Sync playback error: retries each operation with backoff, never deletes failed ops',
        () async {
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
            mockDeviceService: mockDeviceService,
            initialState: AppState(isOffline: false), // online
          );
          final container = ProviderContainer(
            overrides: [appDataProvider.overrideWith(() => notifier)],
          );
          addTearDown(container.dispose);
          await container.read(appDataProvider.future);

          when(() => mockApi.createMembre(any()))
              .thenThrow(Exception('API Temporary Server Error'));
          when(() => mockApi.updateCotisation(any(), any()))
              .thenThrow(Exception('API Temporary Server Error'));
          when(() => mockApi.getAllMembres()).thenAnswer((_) async => []);
          when(() => mockApi.getCultes(
                page: any(named: 'page'),
                pageSize: any(named: 'pageSize'),
              )).thenAnswer((_) async => []);
          when(() => mockApi.getCotisations()).thenAnswer((_) async => []);
          when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
          when(() => mockCache.mergeFromCloud(
                cloudMembres: any(named: 'cloudMembres'),
                cloudCultes: any(named: 'cloudCultes'),
                cloudCotisations: any(named: 'cloudCotisations'),
                pendingMembreIds: any(named: 'pendingMembreIds'),
                pendingCulteIds: any(named: 'pendingCulteIds'),
                pendingCotisationIds: any(named: 'pendingCotisationIds'),
              )).thenAnswer((invocation) async {
            final membres = (invocation.namedArguments[#cloudMembres] as List)
                .map((e) => e as Membre)
                .toList();
            when(() => mockCache.getAllMembres())
                .thenAnswer((_) async => membres);
            when(() => mockCache.getAllCultes())
                .thenAnswer((_) async => <Culte>[]);
            when(() => mockCache.getAllCotisations())
                .thenAnswer((_) async => <Cotisation>[]);
          });

          await container.read(appDataProvider.notifier).syncData();

          // Chaque opération est retentée 5 fois (syncMaxRetries = 5)
          verify(() => mockApi.createMembre(any())).called(greaterThanOrEqualTo(5));
          verify(() => mockApi.updateCotisation(any(), any())).called(greaterThanOrEqualTo(5));
          // Les ops échouées ne sont jamais supprimées de la queue
          verifyNever(() => mockCache.deleteSyncOp(101));
          verifyNever(() => mockCache.deleteSyncOp(102));
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    });
  });
}
