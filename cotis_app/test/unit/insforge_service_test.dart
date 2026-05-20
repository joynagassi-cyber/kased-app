import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kased_app/core/insforge/insforge_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response {}

void main() {
  late MockDio mockDio;
  late InsForgeService service;

  setUp(() {
    mockDio = MockDio();
    service = InsForgeService(dio: mockDio);
  });

  group('InsForgeService - Membres', () {
    test('getMembres success returns list of maps', () async {
      final mockData = [
        {'id': '1', 'nom': 'Doe'},
        {'id': '2', 'nom': 'Smith'},
      ];
      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn(mockData);
      
      when(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.getMembres();

      expect(result.length, 2);
      expect(result.first['nom'], 'Doe');
    });

    test('getMembres error throws DioException', () async {
      when(() => mockDio.get(
        '/api/database/records/membres',
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      expect(() => service.getMembres(), throwsA(isA<DioException>()));
    });
  });

  group('InsForgeService - RPC', () {
    test('togglePaiement calls correct endpoint', () async {
      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn({'success': true});
      
      when(() => mockDio.post(
        '/api/database/rpc/toggle_paiement',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.togglePaiement(membreId: 'm1', culteId: 'c1');

      expect(result['success'], isTrue);
      verify(() => mockDio.post(
        '/api/database/rpc/toggle_paiement',
        data: {'p_membre_id': 'm1', 'p_culte_id': 'c1'},
      )).called(1);
    });

    test('creerCulteAvecCotisations calls RPC and returns UUID', () async {
      final mockResponse = MockResponse();
      const expectedUuid = 'new-culte-uuid';
      when(() => mockResponse.data).thenReturn(expectedUuid);
      
      when(() => mockDio.post(
        '/api/database/rpc/creer_culte_avec_cotisations',
        data: any(named: 'data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await service.creerCulteAvecCotisations(
        dateCulte: DateTime(2026, 5, 15),
        titre: 'Dimanche de Pentecôte',
      );

      expect(result, expectedUuid);
      verify(() => mockDio.post(
        '/api/database/rpc/creer_culte_avec_cotisations',
        data: {
          'p_date_culte': '2026-05-15',
          'p_titre': 'Dimanche de Pentecôte',
          'p_montant_cotisation': 50.0,
        },
      )).called(1);
    });
  });

  group('InsForgeService - Dashboard', () {
    test('getDashboard returns first element of list', () async {
      final mockData = [
        {'total_membres': 10, 'total_cultes': 5}
      ];
      final mockResponse = MockResponse();
      when(() => mockResponse.data).thenReturn(mockData);
      
      when(() => mockDio.get('/api/database/records/v_dashboard'))
          .thenAnswer((_) async => mockResponse);

      final result = await service.getDashboard();

      expect(result['total_membres'], 10);
    });
  });
}
