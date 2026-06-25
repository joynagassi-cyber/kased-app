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

// Subclass to bypass Isar build() while initializing fields
class TestAppData extends AppData {
  final AppState? initialState;
  final InsForgeService mockApi;
  final LocalCache mockCache;

  TestAppData({required this.mockApi, required this.mockCache, this.initialState});

  @override
  Future<AppState> build() async {
    // Manually set the late fields using the setters we added
    this.api = mockApi;
    this.cache = mockCache;
    this.syncManager = SyncManager(mockApi, mockCache);
    return initialState ?? AppState();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(Cotisation());
    registerFallbackValue(SyncOperation());
  });

  group('AppState', () {
    test('valeur initiale vide', () {
      final state = AppState();
      expect(state.membres, isEmpty);
      expect(state.cultes, isEmpty);
      expect(state.cotisations, isEmpty);
    });
  });

  group('AppData Provider (Riverpod)', () {
    late MockInsForgeService mockApi;
    late MockLocalCache mockCache;

    setUp(() {
      mockApi = MockInsForgeService();
      mockCache = MockLocalCache();

      when(() => mockCache.saveCotisation(any())).thenAnswer((_) async => {});
      when(() => mockCache.saveSyncOp(any())).thenAnswer((_) async => {});
    });

    test('TogglePaiement offline-first: pas de rollback sur erreur réseau', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      final cotisation = Cotisation()
        ..id = 'cot1'
        ..membreId = membreId
        ..culteId = culteId
        ..montantObligatoire = 50.0
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye;

      final initialState = AppState(
        cultes: [
          Culte()
            ..id = culteId
            ..titre = 'Culte Test'
            ..montantCotisation = 50.0
            ..dateCulte = DateTime.now(),
        ],
        cotisations: [cotisation],
      );

      final notifier = TestAppData(mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [
          appDataProvider.overrideWith(() => notifier),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appDataProvider.future);

      // togglePaiement → enregistrerPaiementPersonnel → updateCotisation
      when(() => mockApi.updateCotisation(any(), any()))
          .thenAnswer((_) async => throw Exception('API Error'));
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});

      try {
        await container.read(appDataProvider.notifier).togglePaiement(
          membreId: membreId,
          culteId: culteId,
        );
      } catch (_) {}

      final state = container.read(appDataProvider).value!;
      // En mode offline-first, l'état reste 'paye' et est mis en file d'attente
      expect(state.cotisations.first.statut, StatutCotisation.paye);
    });

    test('TogglePaiement success update', () async {
      const membreId = 'm1';
      const culteId = 'c1';
      final cotisation = Cotisation()
        ..id = 'cot1'
        ..membreId = membreId
        ..culteId = culteId
        ..montantObligatoire = 50.0
        ..montantPaye = 0.0
        ..montantDon = 0.0
        ..statut = StatutCotisation.nonPaye;

      final initialState = AppState(
        cultes: [
          Culte()
            ..id = culteId
            ..titre = 'Culte Test'
            ..montantCotisation = 50.0
            ..dateCulte = DateTime.now(),
        ],
        cotisations: [cotisation],
      );

      final notifier = TestAppData(mockApi: mockApi, mockCache: mockCache, initialState: initialState);
      final container = ProviderContainer(
        overrides: [
          appDataProvider.overrideWith(() => notifier),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appDataProvider.future);

      // togglePaiement → enregistrerPaiementPersonnel → updateCotisation
      when(() => mockApi.updateCotisation(any(), any()))
          .thenAnswer((_) async => {});
      when(() => mockApi.getDashboard()).thenAnswer((_) async => {});

      await container.read(appDataProvider.notifier).togglePaiement(
        membreId: membreId,
        culteId: culteId,
      );

      final state = container.read(appDataProvider).value!;
      expect(state.cotisations.first.statut, StatutCotisation.paye);
    });
  });
}
