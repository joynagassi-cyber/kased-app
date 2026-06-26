import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/sync/sync_manager.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}
class MockLocalCache extends Mock implements LocalCache {}

class TestAppData extends AppData {
  final AppState? initialState;
  final InsForgeService mockApi;
  final LocalCache mockCache;

  TestAppData({required this.mockApi, required this.mockCache, this.initialState});

  @override
  Future<AppState> build() async {
    this.api = mockApi;
    this.cache = mockCache;
    this.syncManager = SyncManager(mockApi, mockCache);
    return initialState ?? AppState();
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
  setUpAll(() {
    registerFallbackValue(Cotisation());
    registerFallbackValue(SyncOperation());
  });

  late MockInsForgeService mockApi;
  late MockLocalCache mockCache;

  setUp(() {
    mockApi = MockInsForgeService();
    mockCache = MockLocalCache();

    when(() => mockCache.saveCotisation(any())).thenAnswer((_) async => {});
    when(() => mockCache.saveSyncOp(any())).thenAnswer((_) async => {});
    when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
  });

  group('enregistrerPaiementPersonnel', () {
    test('paiement exact = obligatoire → statut paye, don = 0', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      final initialState = AppState(
        cultes: [_culte(culteId)],
        cotisations: [
          _cotisation(membreId: membreId, culteId: culteId),
        ],
      );

      final notifier = TestAppData(
          mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      when(() => mockApi.updateCotisation(any(), any()))
          .thenAnswer((_) async => {});

      await container.read(appDataProvider.notifier).enregistrerPaiementPersonnel(
            membreId: membreId,
            culteId: culteId,
            montant: 50.0,
          );

      final cot = container.read(appDataProvider).value!.cotisations.first;
      expect(cot.statut, StatutCotisation.paye);
      expect(cot.montantPaye, 50.0);
      expect(cot.montantDon, 0.0);
      expect(cot.datePaiement, isNotNull);
    });

    test('paiement supérieur → don enregistré (excédent)', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      final initialState = AppState(
        cultes: [_culte(culteId)],
        cotisations: [
          _cotisation(membreId: membreId, culteId: culteId),
        ],
      );

      final notifier = TestAppData(
          mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      when(() => mockApi.updateCotisation(any(), any()))
          .thenAnswer((_) async => {});

      await container.read(appDataProvider.notifier).enregistrerPaiementPersonnel(
            membreId: membreId,
            culteId: culteId,
            montant: 150.0,
          );

      final cot = container.read(appDataProvider).value!.cotisations.first;
      expect(cot.statut, StatutCotisation.paye);
      expect(cot.montantPaye, 150.0);
      expect(cot.montantDon, 100.0); // 150 - 50 = 100 de don
    });

    test('montant inférieur à l\'obligatoire → lève une exception', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      final initialState = AppState(
        cultes: [_culte(culteId)],
        cotisations: [
          _cotisation(membreId: membreId, culteId: culteId),
        ],
      );

      final notifier = TestAppData(
          mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      when(() => mockApi.updateCotisation(any(), any()))
          .thenAnswer((_) async => {});

      expect(
        () => container.read(appDataProvider.notifier).enregistrerPaiementPersonnel(
              membreId: membreId,
              culteId: culteId,
              montant: 30.0,
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('échec réseau → état local conservé + sync op en file', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      final initialState = AppState(
        cultes: [_culte(culteId)],
        cotisations: [
          _cotisation(membreId: membreId, culteId: culteId),
        ],
      );

      final notifier = TestAppData(
          mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      // L'API échoue → la cotisation doit tout de même rester payée localement.
      when(() => mockApi.updateCotisation(any(), any()))
          .thenAnswer((_) async => throw Exception('Network down'));

      await container.read(appDataProvider.notifier).enregistrerPaiementPersonnel(
            membreId: membreId,
            culteId: culteId,
            montant: 75.0,
          );

      final cot = container.read(appDataProvider).value!.cotisations.first;
      expect(cot.statut, StatutCotisation.paye);
      expect(cot.montantPaye, 75.0);
      expect(cot.montantDon, 25.0);
      // Une opération de sync a dû être mise en file
      verify(() => mockCache.saveSyncOp(any())).called(1);
    });

    test('nouvelle cotisation (inexistante) → créée puis synchronisée', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      // Pas de cotisation existante pour ce membre/culte
      final initialState = AppState(
        cultes: [_culte(culteId)],
        cotisations: [],
      );

      final notifier = TestAppData(
          mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      when(() => mockApi.createCotisations(any()))
          .thenAnswer((_) async => []);

      await container.read(appDataProvider.notifier).enregistrerPaiementPersonnel(
            membreId: membreId,
            culteId: culteId,
            montant: 50.0,
          );

      final cots = container.read(appDataProvider).value!.cotisations;
      expect(cots.length, 1);
      expect(cots.first.statut, StatutCotisation.paye);
      expect(cots.first.membreId, membreId);
      expect(cots.first.culteId, culteId);
      verify(() => mockApi.createCotisations(any())).called(1);
    });

    test('paiement verrouillé après 30 jours si déjà payé', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      final initialState = AppState(
        cultes: [_culte(culteId, date: DateTime.now().subtract(const Duration(days: 35)))],
        cotisations: [
          _cotisation(
            membreId: membreId,
            culteId: culteId,
            statut: StatutCotisation.paye,
            paye: 50.0,
          ),
        ],
      );

      final notifier = TestAppData(
          mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      expect(
        () => container.read(appDataProvider.notifier).enregistrerPaiementPersonnel(
              membreId: membreId,
              culteId: culteId,
              montant: 100.0,
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
