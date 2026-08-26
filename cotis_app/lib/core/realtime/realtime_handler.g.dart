// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$realtimeHandlerHash() => r'dd6b5d3d9e85f0c7a66a6fc4f381ee13ae94b8bb';

/// Gestionnaire d'événements temps réel.
///
/// Reçoit les événements du [RealtimeService] et déclenche un reload
/// via un callback configuré au moment de la connexion.
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
