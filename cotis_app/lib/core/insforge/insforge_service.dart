import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'insforge_config.dart';
import '../../providers/auth_provider.dart';

part 'insforge_service.g.dart';

@riverpod
InsForgeService insForgeService(InsForgeServiceRef ref) {
  final auth = ref.watch(authProvider);
  return InsForgeService(
    token: auth.token,
    onUnauthorized: () async {
      if (auth.refreshToken != null) {
        debugPrint('[InsForge] Tentative de rafraîchissement de session...');
        return await ref.read(authProvider.notifier).refreshSession(auth.refreshToken!);
      }
      return false;
    },
  );
}

class InsForgeService {
  late final Dio _dio;
  final Future<bool> Function()? onUnauthorized;

  InsForgeService({String? token, this.onUnauthorized, Dio? dio}) {
    if (dio != null) {
      _dio = dio;
      return;
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: InsForgeConfig.baseUrl,
        headers: InsForgeConfig.buildHeaders(token),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(responseBody: true, requestBody: true),
      );
    }

    // Intercepteur 401 — token expiré ou invalide
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('[InsForge] 401 — session expirée ou accès refusé');
            
            if (onUnauthorized != null) {
              final refreshed = await onUnauthorized!();
              if (refreshed) {
                // Le refresh a réussi, le provider va se reconstruire.
                // Note: On pourrait relancer la requête ici, mais avec Riverpod
                // la plupart des widgets vont se rafraîchir d'eux-mêmes.
                debugPrint('[InsForge] Session rafraîchie avec succès.');
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    throw StateError('Unexpected InsForge response shape: ${data.runtimeType}');
  }

  Map<String, dynamic> _asSingle(dynamic data) {
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw StateError('Unexpected InsForge record shape: ${data.runtimeType}');
  }

  // --- MEMBRES ---
  Future<List<Map<String, dynamic>>> getMembres({
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get(
      '/api/database/records/membres',
      queryParameters: {
        'order': 'nom.asc',
        'is_active': 'eq.true',
        'limit': pageSize.toString(),
        'offset': ((page - 1) * pageSize).toString(),
      },
    );
    return _asList(response.data);
  }

  Future<List<Map<String, dynamic>>> getAllMembres() async {
    final all = <Map<String, dynamic>>[];
    var page = 1;
    const pageSize = 200;
    while (true) {
      final batch = await getMembres(page: page, pageSize: pageSize);
      if (batch.isEmpty) break;
      all.addAll(batch);
      if (batch.length < pageSize) break;
      page++;
    }
    return all;
  }

  Future<Map<String, dynamic>> createMembre(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/database/records/membres',
      data: [data],
    );
    return _asSingle(response.data);
  }

  Future<void> updateMembre(String id, Map<String, dynamic> data) async {
    await _dio.patch(
      '/api/database/records/membres',
      queryParameters: {'id': 'eq.$id'},
      data: data,
    );
  }

  Future<void> deleteMembre(String id) async {
    await _dio.delete(
      '/api/database/records/membres',
      queryParameters: {'id': 'eq.$id'},
    );
  }

  // --- CULTES ---
  Future<List<Map<String, dynamic>>> getCultes({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/api/database/records/cultes',
      queryParameters: {
        'order': 'date_culte.desc',
        'limit': pageSize.toString(),
        'offset': ((page - 1) * pageSize).toString(),
      },
    );
    return _asList(response.data);
  }

  Future<Map<String, dynamic>> createCulte(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/database/records/cultes',
      data: [data],
    );
    return _asSingle(response.data);
  }

  // Créer un culte avec génération automatique des cotisations
  Future<String> creerCulteAvecCotisations({
    required DateTime dateCulte,
    String? titre,
    double montantCotisation = 50.0,
  }) async {
    final response = await _dio.post(
      '/api/database/rpc/creer_culte_avec_cotisations',
      data: {
        'p_date_culte': dateCulte.toIso8601String().substring(0, 10),
        if (titre != null) 'p_titre': titre,
        'p_montant_cotisation': montantCotisation,
      },
    );
    return response.data as String; // Retourne l'UUID du culte créé
  }

  Future<void> updateCulte(String id, Map<String, dynamic> data) async {
    await _dio.patch(
      '/api/database/records/cultes',
      queryParameters: {'id': 'eq.$id'},
      data: data,
    );
  }

  Future<void> deleteCulte(String id) async {
    await _dio.delete(
      '/api/database/records/cultes',
      queryParameters: {'id': 'eq.$id'},
    );
  }

  // --- COTISATIONS ---
  Future<void> createCotisations(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;
    await _dio.post(
      '/api/database/records/cotisations',
      data: data,
    );
  }

  Future<void> updateCotisation(String id, Map<String, dynamic> data) async {
    await _dio.patch(
      '/api/database/records/cotisations',
      queryParameters: {'id': 'eq.$id'},
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getCotisations() async {
    final response = await _dio.get(
      '/api/database/records/cotisations',
      queryParameters: {
        'order': 'created_at.desc',
      },
    );
    return _asList(response.data);
  }

  Future<List<Map<String, dynamic>>> getCotisationsDuCulte(String culteId) async {
    final response = await _dio.get(
      '/api/database/records/cotisations',
      queryParameters: {
        'culte_id': 'eq.$culteId',
        'order': 'created_at.desc',
      },
    );
    return _asList(response.data);
  }

  Future<List<Map<String, dynamic>>> getCotisationsDuMembre(String membreId) async {
    final response = await _dio.get(
      '/api/database/records/cotisations',
      queryParameters: {
        'membre_id': 'eq.$membreId',
        'order': 'created_at.desc',
      },
    );
    return _asList(response.data);
  }

  // Toggle paiement (marquer/démarquer comme payé)
  Future<Map<String, dynamic>> togglePaiement({
    required String membreId,
    required String culteId,
  }) async {
    final response = await _dio.post(
      '/api/database/rpc/toggle_paiement',
      data: {
        'p_membre_id': membreId,
        'p_culte_id': culteId,
      },
    );
    return _asSingle(response.data);
  }

  // Marquer un membre comme absent
  Future<Map<String, dynamic>> marquerAbsent({
    required String membreId,
    required String culteId,
  }) async {
    final response = await _dio.post(
      '/api/database/rpc/marquer_absent',
      data: {
        'p_membre_id': membreId,
        'p_culte_id': culteId,
      },
    );
    return _asSingle(response.data);
  }

  // Historique d'un membre
  Future<List<Map<String, dynamic>>> getHistoriqueMembre(String membreId) async {
    final response = await _dio.post(
      '/api/database/rpc/historique_membre',
      data: {
        'p_membre_id': membreId,
      },
    );
    return _asList(response.data);
  }

  Future<void> deleteCotisation(String id) async {
    await _dio.delete(
      '/api/database/records/cotisations',
      queryParameters: {'id': 'eq.$id'},
    );
  }

  /// Définit directement le statut d'une cotisation (utilisé pour les opérations bulk).
  Future<void> setCotisationStatut({
    required String membreId,
    required String culteId,
    required String statut,
  }) async {
    await _dio.patch(
      '/api/database/records/cotisations',
      queryParameters: {
        'membre_id': 'eq.$membreId',
        'culte_id': 'eq.$culteId',
      },
      data: {
        'statut': statut,
        if (statut == 'paye')
          'date_paiement': DateTime.now().toIso8601String(),
        if (statut == 'non_paye') 'date_paiement': null,
      },
    );
  }

  Future<void> deleteCotisationsDuCulte(String culteId) async {
    await _dio.delete(
      '/api/database/records/cotisations',
      queryParameters: {'culte_id': 'eq.$culteId'},
    );
  }

  // --- VUES CALCULÉES ---
  
  // Dashboard global
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get(
      '/api/database/records/v_dashboard',
    );
    final list = _asList(response.data);
    return list.isNotEmpty ? list.first : {};
  }

  // Résumé des cultes
  Future<List<Map<String, dynamic>>> getResumeCultes() async {
    final response = await _dio.get(
      '/api/database/records/v_resume_culte',
      queryParameters: {
        'order': 'date_culte.desc',
      },
    );
    return _asList(response.data);
  }

  // Membres en retard
  Future<List<Map<String, dynamic>>> getRetardsMembres() async {
    final response = await _dio.get(
      '/api/database/records/v_retards_membres',
      queryParameters: {
        'order': 'montant_du_fcfa.desc',
      },
    );
    return _asList(response.data);
  }

  // Membres à jour
  Future<List<Map<String, dynamic>>> getMembresAJour() async {
    final response = await _dio.get(
      '/api/database/records/v_membres_a_jour',
      queryParameters: {
        'order': 'nom.asc',
      },
    );
    return _asList(response.data);
  }

  // Membres en avance
  Future<List<Map<String, dynamic>>> getMembresEnAvance() async {
    final response = await _dio.get(
      '/api/database/records/v_membres_en_avance',
      queryParameters: {
        'order': 'nom.asc',
      },
    );
    return _asList(response.data);
  }

  // --- UPLOAD PHOTO ---
  Future<String?> uploadMembrePhoto(String filePath, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        '/api/storage/object/${InsForgeConfig.membersPhotosBucket}/$fileName',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '${InsForgeConfig.baseUrl}/api/storage/object/public/${InsForgeConfig.membersPhotosBucket}/$fileName';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
