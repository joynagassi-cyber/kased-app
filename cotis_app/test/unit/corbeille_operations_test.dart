import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:kased_app/core/local_cache.dart';
import 'package:kased_app/core/services/notification_coordinator.dart';
import 'package:kased_app/core/services/sync_service.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/sync/device_service_port.dart';
import 'package:kased_app/store/kased_store.dart';
import 'package:kased_app/store/kased_action.dart';
import 'package:mocktail/mocktail.dart';

class MockInsForgeService extends Mock implements InsForgeService {}
class MockLocalCache extends Mock implements LocalCache {}

class FakeDeviceService extends Fake implements DeviceServicePort {
  @override
  Future<String> getDeviceId() async => 'test-device-123';
}

void main() {
  late MockInsForgeService mockApi;
  late MockLocalCache mockCache;
  late FakeDeviceService mockDeviceService;
  late KasedStore store;
  late NotificationCoordinator notifCoordinator;

  setUp(() {
    mockApi = MockInsForgeService();
    mockCache = MockLocalCache();
    mockDeviceService = FakeDeviceService();
    notifCoordinator = NotificationCoordinator();

    store = KasedStore(
      api: mockApi,
      cache: mockCache,
      syncService: SyncService(mockApi, mockCache),
      statsService: StatsService(),
      deviceService: mockDeviceService,
      notifCoordinator: notifCoordinator,
    );
  });

  group('supprimerDefinitivement', () {
    test('purge l\'élément local sans appel cloud', () async {
      when(() => mockCache.deleteCorbeilleItem(any()))
          .thenAnswer((_) async => {});

      await store.dispatch(PermanentlyDelete(42));

      verify(() => mockCache.deleteCorbeilleItem(42)).called(1);
      verifyNever(() => mockApi.updateMembre(any(), any()));
    });
  });

  group('viderCorbeille', () {
    test('vide toute la corbeille locale en une fois', () async {
      when(() => mockCache.deleteAllCorbeilleItems())
          .thenAnswer((_) async => {});
      when(() => mockCache.getAllMembres()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCultes()).thenAnswer((_) async => []);
      when(() => mockCache.getAllCotisations()).thenAnswer((_) async => []);

      await store.dispatch(EmptyTrash());

      verify(() => mockCache.deleteAllCorbeilleItems()).called(1);
    });
  });
}
