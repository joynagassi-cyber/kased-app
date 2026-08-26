import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/store/kased_store.dart';
import 'package:kased_app/store/kased_action.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}
class MockLocalCache extends Mock implements LocalCache {}

class FakeDeviceService extends Fake implements DeviceServicePort {
  @override
  Future<String> getDeviceId() async => 'test-device-123';
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
  setUpAll(() {
    registerFallbackValue(Cotisation());
    registerFallbackValue(SyncOperation());
  });

  late MockInsForgeService mockApi;
  late MockLocalCache mockCache;

  setUp(() {
    mockApi = MockInsForgeService();
    mockCache = MockLocalCache();
    when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
  });

  KasedStore createStore(AppState state) {
    return KasedStore(
      api: mockApi,
      cache: mockCache,
      syncService: SyncService(mockApi, mockCache),
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

      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => [_culte(culteId)]);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => [_cotisation(membreId: membreId, culteId: culteId)]);
      when(() => mockApi.updateCotisation(any(), any())).thenAnswer((_) async => {});

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 50.0,
      ));

      final cots = await mockCache.getAllCotisations();
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

      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => [_culte(culteId)]);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => [_cotisation(membreId: membreId, culteId: culteId)]);
      when(() => mockApi.updateCotisation(any(), any())).thenAnswer((_) async => {});

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 150.0,
      ));

      final cots = await mockCache.getAllCotisations();
      expect(cots.first.statut, StatutCotisation.paye);
      expect(cots.first.montantPaye, 150.0);
      expect(cots.first.montantDon, 100.0);
    });

    test('echec reseau -> etat local conserve + sync op en file', () async {
      const membreId = 'm1';
      const culteId = 'c1';

      final store = createStore(AppState(
        cultes: [_culte(culteId)],
        cotisations: [_cotisation(membreId: membreId, culteId: culteId)],
      ));

      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => [_culte(culteId)]);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => [_cotisation(membreId: membreId, culteId: culteId)]);
      when(() => mockApi.updateCotisation(any(), any())).thenThrow(Exception('Network down'));

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 75.0,
      ));

      final cots = await mockCache.getAllCotisations();
      expect(cots.first.statut, StatutCotisation.paye);
      expect(cots.first.montantPaye, 75.0);
      expect(cots.first.montantDon, 25.0);
    });

    test('nouvelle cotisation (inexistante) -> cee puis synchronisee', () async {
      const membreId = 'm1';
      const culteId = 'c1';

      final store = createStore(AppState(
        cultes: [_culte(culteId)],
        cotisations: [],
      ));

      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => [_culte(culteId)]);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);
      when(() => mockApi.createCotisations(any())).thenAnswer((_) async => []);

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 50.0,
      ));

      final cots = await mockCache.getAllCotisations();
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

      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => [_culte(culteId, date: DateTime.now().subtract(const Duration(days: 35)))]);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => [_cotisation(membreId: membreId, culteId: culteId, statut: StatutCotisation.paye, paye: 50.0)]);

      await store.dispatch(RegisterPayment(
        membreId: membreId,
        culteId: culteId,
        montant: 100.0,
      ));

      final cots = await mockCache.getAllCotisations();
      expect(cots.first.statut, equals(StatutCotisation.paye));
    });
  });
}
