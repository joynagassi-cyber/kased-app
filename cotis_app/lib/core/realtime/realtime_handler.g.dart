// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$realtimeHandlerHash() => r'd6fc492347b93de53466fb9afc69d49040fd72c7';

/// Gestionnaire d'événements temps réel.
///
/// Reçoit les événements du [RealtimeService] et :
/// 1. Applique un patch local via [RealtimePatchEngine]
/// 2. Déclenche un reload si nécessaire
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
