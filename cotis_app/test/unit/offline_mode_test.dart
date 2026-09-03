import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/store/kased_store.dart';
import 'package:kased_app/store/kased_action.dart';
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
  Future<void> softDeleteCulteWithCotisationsAndSyncOps(
      Culte culte, List<Cotisation> cotisations, List<SyncOperation> syncOps) async {
    await saveCulte(culte);
    for (final c in cotisations) await saveCotisation(c);
    for (final op in syncOps) await saveSyncOp(op);
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

class FakeDeviceService extends Fake implements DeviceServicePort {
  @override
  Future<String> getDeviceId() async => 'test-device-123';
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
    late LocalCache mockCache;
    late FakeDeviceService mockDeviceService;
    late KasedStore store;

    void setUpMocks() {
      mockApi = MockInsForgeService();
      mockCache = StubLocalCache();
      mockDeviceService = FakeDeviceService();

      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
      store = KasedStore(
        api: mockApi,
        cache: mockCache,
        syncService: SyncService(mockApi, mockCache),
        statsService: StatsService(),
        deviceService: mockDeviceService,
        notifCoordinator: NotificationCoordinator(),
      );
    }

    void configureOffline() {
      when(() => mockApi.createMembre(any())).thenThrow(Exception('No Internet'));
      when(() => mockApi.getDashboard()).thenThrow(Exception('No Internet'));
      when(() => mockApi.updateCulte(any(), any())).thenThrow(Exception('No Internet'));
      when(() => mockApi.createCulte(any())).thenThrow(Exception('No Internet'));
      when(() => mockApi.updateMembre(any(), any())).thenThrow(Exception('No Internet'));
      when(() => mockApi.deleteMembre(any())).thenThrow(Exception('No Internet'));
      when(() => mockApi.updateCotisation(any(), any())).thenThrow(Exception('No Internet'));
      when(() => mockApi.marquerAbsent(membreId: any(named: 'membreId'), culteId: any(named: 'culteId'))).thenThrow(Exception('No Internet'));
    }

    group('Membres Offline Operations', () {
      test('Add Membre when offline: saves to cache and queues SyncOperation', () async {
        setUpMocks();
        configureOffline();

        await store.dispatch(CreateMember(
          nom: 'Turing',
          prenom: 'Alan',
          dateAdhesion: DateTime(2026, 1, 1),
          notes: 'Pionnier',
        ));

        final membres = await mockCache.getAllMembres();
        expect(membres.length, equals(1));
        expect(membres.first.nom, equals('Turing'));
        expect(membres.first.prenom, equals('Alan'));

        final ops = await mockCache.getPendingSyncOps();
        expect(ops.length, equals(1));
        expect(ops.first.type, equals('CREATE'));
        expect(ops.first.entityType, equals('membre'));
      });

      test('Update Membre when offline: saves to cache and queues SyncOperation', () async {
        setUpMocks();
        configureOffline();

        final existingMembre = Membre()
          ..id = 'm-uuid'
          ..nom = 'Lovelace'
          ..prenom = 'Ada'
          ..dateAdhesion = DateTime(2026, 1, 1)
          ..isActive = true;
        await mockCache.saveMembre(existingMembre);

        await store.dispatch(UpdateMember(
          id: 'm-uuid',
          nom: 'Lovelace-New',
          notes: 'Ada changed',
        ));

        final membres = await mockCache.getAllMembres();
        expect(membres.first.nom, equals('Lovelace-New'));

        final ops = await mockCache.getPendingSyncOps();
        expect(ops.length, equals(1));
        expect(ops.first.type, equals('UPDATE'));
      });

      test('Delete Membre when offline: deletes locally and queues DELETE SyncOperation', () async {
        setUpMocks();
        configureOffline();

        final existingMembre = Membre()
          ..id = 'm-uuid-del'
          ..nom = 'Curie'
          ..prenom = 'Marie'
          ..dateAdhesion = DateTime(2026, 1, 1);
        await mockCache.saveMembre(existingMembre);

        await store.dispatch(DeleteMember('m-uuid-del'));

        // Vérifier que l'opération DELETE est bien en file d'attente
        final ops = await mockCache.getPendingSyncOps();
        expect(ops.any((op) => op.type == 'DELETE' && op.entityType == 'membre'), isTrue);
      });
    });

    group('Cultes Offline Operations', () {
      test('Add Culte when offline: saves to cache and queues CREATE SyncOperations', () async {
        setUpMocks();
        configureOffline();

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
        await mockCache.saveMembre(m1);
        await mockCache.saveMembre(m2);

        await store.dispatch(CreateCulte(
          date: DateTime(2026, 5, 24),
          titre: 'Culte Pentecote',
          montant: 100.0,
        ));

        final cultes = await mockCache.getAllCultes();
        expect(cultes.length, equals(1));
        expect(cultes.first.titre, equals('Culte Pentecote'));

        final ops = await mockCache.getPendingSyncOps();
        expect(ops.length, greaterThanOrEqualTo(1));
      });

      test('Update Culte when offline: updates locally and queues UPDATE SyncOperation', () async {
        setUpMocks();
        configureOffline();

        final existingCulte = Culte()
          ..id = 'c-uuid'
          ..dateCulte = DateTime(2026, 8, 20)
          ..titre = 'Culte Dimanche'
          ..montantCotisation = 50.0;
        await mockCache.saveCulte(existingCulte);

        await store.dispatch(UpdateCulte(
          id: 'c-uuid',
          titre: 'Culte Dimanche Modifie',
          montantCotisation: 75.0,
        ));

        final cultes = await mockCache.getAllCultes();
        expect(cultes.first.montantCotisation, equals(75.0));

        final ops = await mockCache.getPendingSyncOps();
        expect(ops.length, greaterThanOrEqualTo(1));
      });

      test('Update Culte when older than 30 days: logs error but does not crash', () async {
        setUpMocks();

        final existingCulte = Culte()
          ..id = 'c-locked'
          ..dateCulte = DateTime(2026, 5, 1)
          ..titre = 'Culte ancien'
          ..montantCotisation = 50.0;
        await mockCache.saveCulte(existingCulte);

        // Le store capture les exceptions — vérifie que l'état reste inchangé
        await store.dispatch(UpdateCulte(
          id: 'c-locked',
          montantCotisation: 75.0,
        ));

        final cultes = await mockCache.getAllCultes();
        expect(cultes.first.montantCotisation, equals(50.0));
      });
    });

    group('Cotisations Offline Operations', () {
      test('Mark absent offline: changes status to absent and queues SyncOperation', () async {
        setUpMocks();
        configureOffline();

        final membre = Membre()
          ..id = 'm1'
          ..nom = 'Test'
          ..prenom = 'Membre'
          ..dateAdhesion = DateTime(2026, 1, 1);
        await mockCache.saveMembre(membre);

        final culte = Culte()
          ..id = 'c1'
          ..dateCulte = DateTime.now()
          ..titre = 'Culte Test'
          ..montantCotisation = 50.0;
        await mockCache.saveCulte(culte);

        final cot = Cotisation()
          ..id = 'cot-uuid'
          ..membreId = 'm1'
          ..culteId = 'c1'
          ..montantObligatoire = 50.0
          ..montantPaye = 0.0
          ..montantDon = 0.0
          ..statut = StatutCotisation.nonPaye;
        await mockCache.saveCotisation(cot);

        await store.dispatch(MarkAbsent(membreId: 'm1', culteId: 'c1'));

        final cots = await mockCache.getAllCotisations();
        expect(cots.first.statut, equals(StatutCotisation.absent));
      });
    });

    group('Reconnection and Sync Replay', () {
      test('Sync operations are queued when offline', () async {
        setUpMocks();
        configureOffline();
        await store.dispatch(CreateMember(
          nom: 'Turing', prenom: 'Alan', dateAdhesion: DateTime(2026, 1, 1),
        ));
        final ops = await mockCache.getPendingSyncOps();
        expect(ops.length, greaterThanOrEqualTo(1));
        expect(ops.first.entityType, equals('membre'));
      });
      test('deleteSyncOp removes a queued operation', () async {
        setUpMocks();
        await store.dispatch(CreateMember(
          nom: 'Turing', prenom: 'Alan', dateAdhesion: DateTime(2026, 1, 1),
        ));
        final ops = await mockCache.getPendingSyncOps();
        expect(ops.length, greaterThanOrEqualTo(1));
        final op = ops.first;
        await mockCache.deleteSyncOp(op.isarId);
        final remaining = await mockCache.getPendingSyncOps();
        expect(remaining, isEmpty);
      });
    });
  });
}
