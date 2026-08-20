// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$realtimeHandlerHash() => r'90f73c6efc7ba63e3802e49299dce87288bdcba6';

/// Gestionnaire d'événements temps réel.
///
/// Reçoit les événements du [RealtimeService] et applique les changements
/// de manière ciblée (patch) au lieu de recharger toute la base.
///
/// Le provider est keepAlive car il doit persister pendant toute la durée
/// de l'application.
///
/// Copied from [RealtimeHandler].
@ProviderFor(RealtimeHandler)
final realtimeHandlerProvider =
    NotifierProvider<RealtimeHandler, bool>.internal(
  RealtimeHandler.new,
  name: r'realtimeHandlerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$realtimeHandlerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RealtimeHandler = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
