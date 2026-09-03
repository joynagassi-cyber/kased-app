import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/store/kased_store.dart';
import 'package:kased_app/store/kased_action.dart';
import 'package:kased_app/store/app_state.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}

class FakeDeviceService extends Fake implements DeviceServicePort {
  @override
  Future<String> getDeviceId() async => 'test-device-123';
}

/// Stub cache that persists data in-memory for tests.
class StubLocalCache implements LocalCache {
  final List<Cotisation> _cotisations = [];
  final List<Culte> _cultes = [];
  final List<SyncOperation> _syncOps = [];

  @override
  Future<List<Membre>> getAllMembres() async => [];

  @override
  Future<List<Culte>> getAllCultes() async => List.from(_cultes);

  @override
  Future<List<Cotisation>> getAllCotisations() async => List.from(_cotisations);

  @override
  Future<List<SyncOperation>> getPendingSyncOps() async => List.from(_syncOps);

  @override
  Future<void> saveCotisation(Cotisation c) async {
    final idx = _cotisations.indexWhere((e) => e.id == c.id);
    if (idx >= 0) _cotisations[idx] = c; else _cotisations.add(c);
  }

  @override
  Future<void> saveAllCotisations(List<Cotisation> list) async {
    _cotisations.clear();
    _cotisations.addAll(list);
  }

  @override
  Future<void> saveCulte(Culte c) async {
    final idx = _cultes.indexWhere((e) => e.id == c.id);
    if (idx >= 0) _cultes[idx] = c; else _cultes.add(c);
  }

  @override
  Future<void> saveMembre(Membre m) async {}

  @override
  Future<void> deleteMembreById(String id) async {}

  @override
  Future<void> deleteCulteById(String id) async {}

  @override
  Future<void> deleteCotisationsByCulteId(String culteId) async {}

  @override
  Future<void> saveSyncOp(SyncOperation op) async { _syncOps.add(op); }

  @override
  Future<void> deleteSyncOp(int isarId) async {
    _syncOps.removeWhere((e) => e.isarId == isarId);
  }

  @override
  Future<void> saveMembreWithSyncOp(Membre m, SyncOperation op) async {
    await saveMembre(m);
    await saveSyncOp(op);
  }

  @override
  Future<void> saveCulteWithSyncOp(Culte c, SyncOperation op) async {
    await saveCulte(c);
    await saveSyncOp(op);
  }

  @override
  Future<void> saveCotisationWithSyncOp(Cotisation c, SyncOperation op) async {
    await saveCotisation(c);
    await saveSyncOp(op);
  }

  @override
  Future<void> softDeleteMembreWithSyncOp(Membre m, SyncOperation op) async {
    await saveMembre(m);
    await saveSyncOp(op);
  }

  @override
  Future<void> softDeleteCulteWithSyncOp(Culte c, List<Cotisation> co, SyncOperation op) async {
    await saveCulte(c);
    for (final item in co) await saveCotisation(item);
    await saveSyncOp(op);
  }
  @override
  Future<void> softDeleteCulteWithCotisationsAndSyncOps(
      Culte c, List<Cotisation> co, List<SyncOperation> ops) async {
    await saveCulte(c);
    for (final item in co) await saveCotisation(item);
    for (final op in ops) await saveSyncOp(op);
  }

  @override
  Future<void> restoreMembreWithSyncOp(Membre m, SyncOperation op) async {
    await saveMembre(m);
    await saveSyncOp(op);
  }

  @override
  Future<void> restoreCulteWithSyncOp(Culte c, SyncOperation op) async {
    await saveCulte(c);
    await saveSyncOp(op);
  }

  @override
  Future<CorbeilleItem?> getCorbeilleItem(int isarId) async => null;

  @override
  Future<void> saveCorbeilleItem(CorbeilleItem item) async {}

  @override
  Future<void> purgeOldCorbeilleItems(DateTime before) async {}

  @override
  Future<void> deleteCorbeilleItem(int isarId) async {}

  @override
  Future<void> deleteAllCorbeilleItems() async {}

  @override
  Future<void> restoreMembreAndDeleteCorbeilleItem(Membre m, int id) async {
    await saveMembre(m);
  }

  @override
  Future<void> restoreCulteAndDeleteCorbeilleItem(Culte c, int id) async {
    await saveCulte(c);
  }

  @override
  Future<void> deleteMembreAndSaveCorbeilleItem(String id, CorbeilleItem item) async {}

  @override
  Future<void> deleteCulteAndCotisationsAndSaveCorbeilleItem(String culteId, CorbeilleItem item) async {}

  @override
  Future<void> saveCulteWithCotisations(Culte c, List<Cotisation> co) async {
    final idx = _cultes.indexWhere((e) => e.id == c.id);
    if (idx >= 0) _cultes[idx] = c; else _cultes.add(c);
    _cotisations.addAll(co);
  }

  @override
  Future<void> updateCulteAndCotisations(Culte c, List<Cotisation>? co) async {
    final idx = _cultes.indexWhere((e) => e.id == c.id);
    if (idx >= 0) _cultes[idx] = c; else _cultes.add(c);
    if (co != null) {
      for (final item in co) {
        final cIdx = _cotisations.indexWhere((e) => e.id == item.id);
        if (cIdx >= 0) _cotisations[cIdx] = item; else _cotisations.add(item);
      }
    }
  }

  @override
  Future<void> replaceAll({required List<Membre> membres, required List<Culte> cultes, required List<Cotisation> cotisations}) async {
    _cultes.clear();
    _cultes.addAll(cultes);
    _cotisations.clear();
    _cotisations.addAll(cotisations);
  }

  @override
  Future<void> mergeFromCloud({
    required List<Membre> cloudMembres,
    required List<Culte> cloudCultes,
    required List<Cotisation> cloudCotisations,
    required Set<String> pendingMembreIds,
    required Set<String> pendingCulteIds,
    required Set<String> pendingCotisationIds,
  }) async {
    _cultes.clear();
    _cultes.addAll(cloudCultes);
    _cotisations.clear();
    _cotisations.addAll(cloudCotisations);
  }
}

Culte _culte(String id, {double montant = 50.0, DateTime? date}) => Culte()
  ..id = id
  ..titre = 'Culte $id'
  ..montantCotisation = montant
  ..dateCulte = date ?? DateTime.now();

Cotisation _cotisation({
  String id = 'cot1',
  String membreId = 'm1',
  String culteId = 'c1',
  double obligatoire = 50.0,
  double paye = 0.0,
  double don = 0.0,
  StatutCotisation statut = StatutCotisation.nonPaye,
}) =>
    Cotisation()
      ..id = id
      ..membreId = membreId
      ..culteId = culteId
      ..montantObligatoire = obligatoire
      ..montantPaye = paye
      ..montantDon = don
      ..statut = statut;

void main() {
  late MockInsForgeService mockApi;

  setUp(() {
    mockApi = MockInsForgeService();
    when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
  });

  KasedStore createStore(AppState state) {
    final cache = StubLocalCache();
    // Seed the cache with initial state
    for (final c in state.cultes) cache.saveCulte(c);
    for (final c in state.cotisations) cache.saveCotisation(c);

    return KasedStore(
      api: mockApi,
      cache: cache,
      syncService: SyncService(mockApi, cache),
      statsService: StatsService(),
      deviceService: FakeDeviceService(),
      notifCoordinator: NotificationCoordinator(),
    );
  }

  group('enregistrerPaiementPersonnel', () {
    test('paiement exact = obligatoire -> statut paye, don = 0', () async {
      const membreId = 'm1';
      const culteId = 'c1';

      final store = createStore(AppState(
        cultes: [_culte(culteId)],
        cotisations: [_cotisation(membreId: membreId, culteId: culteId)],
      ));

      when(() => mockApi.updateCotisation(any(), any())).thenAnswer((_) async => {});

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 50.0,
      ));

      final cots = await store.state.cotisations;
      expect(cots.first.statut, StatutCotisation.paye);
      expect(cots.first.montantPaye, 50.0);
      expect(cots.first.montantDon, 0.0);
    });

    test('paiement superieur -> don enregistre (excèdent)', () async {
      const membreId = 'm1';
      const culteId = 'c1';

      final store = createStore(AppState(
        cultes: [_culte(culteId)],
        cotisations: [_cotisation(membreId: membreId, culteId: culteId)],
      ));

      when(() => mockApi.updateCotisation(any(), any())).thenAnswer((_) async => {});

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 150.0,
      ));

      final cots = await store.state.cotisations;
      expect(cots.first.statut, StatutCotisation.paye);
      expect(cots.first.montantPaye, 150.0);
      expect(cots.first.montantDon, 100.0);
    });

    test('echec reseau -> etat local conserve', () async {
      const membreId = 'm1';
      const culteId = 'c1';

      final store = createStore(AppState(
        cultes: [_culte(culteId)],
        cotisations: [_cotisation(membreId: membreId, culteId: culteId)],
      ));

      when(() => mockApi.updateCotisation(any(), any())).thenThrow(Exception('Network down'));

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 75.0,
      ));

      final cots = await store.state.cotisations;
      expect(cots.first.statut, StatutCotisation.paye);
      expect(cots.first.montantPaye, 75.0);
      expect(cots.first.montantDon, 25.0);
    });

    test('nouvelle cotisation (inexistante) -> creee', () async {
      const membreId = 'm1';
      const culteId = 'c1';

      final store = createStore(AppState(
        cultes: [_culte(culteId)],
        cotisations: [],
      ));

      when(() => mockApi.createCotisations(any())).thenAnswer((_) async => []);

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 50.0,
      ));

      final cots = await store.state.cotisations;
      expect(cots.length, 1);
      expect(cots.first.statut, StatutCotisation.paye);
      expect(cots.first.membreId, membreId);
      expect(cots.first.culteId, culteId);
    });

    test('paiement verrouille apres 30 jours si deja paye', () async {
      const membreId = 'm1';
      const culteId = 'c1';

      final store = createStore(AppState(
        cultes: [_culte(culteId, date: DateTime.now().subtract(const Duration(days: 35)))],
        cotisations: [_cotisation(membreId: membreId, culteId: culteId, statut: StatutCotisation.paye, paye: 50.0)],
      ));

      // Le store capture l'exception internement - le paiement n'est pas modifié
      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 100.0,
      ));

      // La cotisation originale devrait rester inchangée dans le cache
      final cachedCots = await store.cache.getAllCotisations();
      expect(cachedCots.any((c) => c.membreId == membreId && c.culteId == culteId), isTrue);
      final originalCot = cachedCots.firstWhere((c) => c.membreId == membreId && c.culteId == culteId);
      expect(originalCot.statut, equals(StatutCotisation.paye));
      expect(originalCot.montantPaye, equals(50.0));
    });
  });
}
