// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kased_app_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$kasedAppHash() => r'3a4a71c27274aaca453aa252be9a2953111ff01d';

/// Provider Riverpod adaptateur pour [KasedStore].
///
/// Ce provider est un adaptateur fin (~80 lignes) qui :
/// 1. Initialise le store avec les dépendances (cache, API, sync, etc.)
/// 2. Charge l'état initial depuis le cache Isar
/// 3. Lance un sync différé de 3 secondes
/// 4. Écoute les changements de connectivité
/// 5. Délégue tous les appels au store via [dispatch]
///
/// Les screens utilisent ce provider au lieu d'[appDataProvider].
///
/// Copied from [KasedApp].
@ProviderFor(KasedApp)
final kasedAppProvider = AsyncNotifierProvider<KasedApp, AppState>.internal(
  KasedApp.new,
  name: r'kasedAppProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$kasedAppHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$KasedApp = AsyncNotifier<AppState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
