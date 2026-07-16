import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/models/corbeille_item.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/sync_operation.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}
class MockLocalCache extends Mock implements LocalCache {}

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
    this.syncService = SyncService(mockApi, mockCache);
    return initialState ?? AppState();
  }
}

CorbeilleItem _membreItem(int isarId, {String entityId = 'm1'}) => CorbeilleItem()
  ..isarId = isarId
  ..entityId = entityId
  ..entityType = 'membre'
  ..deletedAt = DateTime.now()
  ..payloadJson = jsonEncode({
    'id': entityId,
    'prenom': 'Jean',
    'nom': 'Dupont',
    'date_adhesion': DateTime(2024, 1, 1).toIso8601String(),
    'telephone': '',
    'is_active': false,
  });

Membre _membre(String id) => Membre()
  ..id = id
  ..prenom = 'Jean'
  ..nom = 'Dupont';

void main() {
  setUpAll(() {
    registerFallbackValue(Membre());
    registerFallbackValue(Culte());
    registerFallbackValue(Cotisation());
    registerFallbackValue(SyncOperation());
    registerFallbackValue(CorbeilleItem());
  });

  late MockInsForgeService mockApi;
  late MockLocalCache mockCache;

  setUp(() {
    mockApi = MockInsForgeService();
    mockCache = MockLocalCache();

    when(() => mockCache.saveSyncOp(any())).thenAnswer((_) async => {});
    when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
    when(() => mockCache.getAllCultes()).thenAnswer((_) async => []);
    when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);
    when(() => mockApi.getDashboard()).thenAnswer((_) async => {});
  });

  group('supprimerDefinitivement', () {
    test('purge l\'élément local sans appel cloud', () async {
      when(() => mockCache.deleteCorbeilleItem(any()))
          .thenAnswer((_) async => {});

      final notifier = TestAppData(mockApi: mockApi, mockCache: mockCache);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      await container.read(appDataProvider.notifier).supprimerDefinitivement(42);

      verify(() => mockCache.deleteCorbeilleItem(42)).called(1);
      verifyNever(() => mockApi.updateMembre(any(), any()));
    });
  });

  group('viderCorbeille', () {
    test('vide toute la corbeille locale en une fois', () async {
      when(() => mockCache.deleteAllCorbeilleItems())
          .thenAnswer((_) async => {});

      final notifier = TestAppData(mockApi: mockApi, mockCache: mockCache);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      await container.read(appDataProvider.notifier).viderCorbeille();

      verify(() => mockCache.deleteAllCorbeilleItems()).called(1);
    });
  });

  group('restaurerElement (offline-first)', () {
    test('restaure localement AVANT le push cloud — réseau KO', () async {
      // La restauration locale doit réussir même si l'API échoue.
      final item = _membreItem(7);
      when(() => mockCache.getCorbeilleItem(7))
          .thenAnswer((_) async => item);
      when(() => mockCache.restoreMembreAndDeleteCorbeilleItem(any(), any()))
          .thenAnswer((_) async => {});
      when(() => mockCache.getAllMembres())
          .thenAnswer((_) async => [_membre('m1')]);
      // L'API échoue → doit être mis en file de sync, pas lever d'exception.
      when(() => mockApi.updateMembre(any(), any()))
          .thenAnswer((_) async => throw Exception('Network down'));

      final notifier = TestAppData(mockApi: mockApi, mockCache: mockCache);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      await container.read(appDataProvider.notifier).restaurerElement(7);

      // La restauration locale a bien eu lieu.
      verify(() => mockCache.restoreMembreAndDeleteCorbeilleItem(any(), 7)).called(1);
      // Une sync op a été mise en file pour le retry.
      verify(() => mockCache.saveSyncOp(any())).called(1);
      // L'état local reflète le membre restauré.
      final state = container.read(appDataProvider).value!;
      expect(state.membres.length, 1);
    });

    test('restaure localement ET pousse au cloud quand le réseau est OK', () async {
      final item = _membreItem(8);
      when(() => mockCache.getCorbeilleItem(8))
          .thenAnswer((_) async => item);
      when(() => mockCache.restoreMembreAndDeleteCorbeilleItem(any(), any()))
          .thenAnswer((_) async => {});
      when(() => mockCache.getAllMembres())
          .thenAnswer((_) async => [_membre('m1')]);
      when(() => mockApi.updateMembre(any(), any()))
          .thenAnswer((_) async => {});

      final notifier = TestAppData(mockApi: mockApi, mockCache: mockCache);
      final container = ProviderContainer(
        overrides: [appDataProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      await container.read(appDataProvider.future);

      await container.read(appDataProvider.notifier).restaurerElement(8);

      verify(() => mockCache.restoreMembreAndDeleteCorbeilleItem(any(), 8)).called(1);
      verify(() => mockApi.updateMembre(any(), any())).called(1);
      verifyNever(() => mockCache.saveSyncOp(any()));
    });
  });
}
