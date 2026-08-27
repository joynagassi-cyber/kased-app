// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unnecessary_cast
part of 'realtime_handler.dart';

// **************************************************************************
// NotifierGenerator
// **************************************************************************

String _$realtimeHandlerHash() => r'dd6b5d3d9e85f0c7a66a6fc4f381ee13ae94b8bb';

/// @nodoc
mixin _$RealtimeHandler {
  bool get isConnected => throw new _Private(), Used by `$build`;
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload}) =>
      throw new _Private(), Used by `$build`;
  void disconnect() => throw new _Private(), Used by `$build`;
}

/// @nodoc
abstract class $RealtimeHandlerConstructor {
  RealtimeHandler copyWith({bool? isConnected});
  RealtimeHandler rebuild(void Function(RealtimeHandler) updates);
  factory $RealtimeHandlerConstructor({required LocalCache cache}) = _\$RealtimeHandler;
}

/// @nodoc
abstract class _$RealtimeHandlerNotifier extends Notifier<bool> {
  bool get isConnected => throw new _Private();
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload});
  void disconnect();
}

/// @nodoc
class _$$RealtimeHandlerNotifier extends _$RealtimeHandlerNotifier {
  @override
  bool build() => (ref) {
    ref.watch(realtimeHandlerProvider);
    return false;
  }(ref);

  @override
  bool get isConnected => throw new _Private();

  @override
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload}) =>
      throw new _Private();

  @override
  void disconnect() => throw new _Private();
}

/// @nodoc
class _$$RealtimeHandlerNotifierWithEquality extends _$RealtimeHandlerNotifier {
  _$$RealtimeHandlerNotifierWithEquality(this.equals);

  final Equals equals;

  @override
  bool build() => (ref) {
    ref.watch(realtimeHandlerProvider);
    return false;
  }(ref);

  @override
  bool get isConnected => throw new _Private();

  @override
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload}) =>
      throw new _Private();

  @override
  void disconnect() => throw new _Private();
}

/// @nodoc
class _$$RealtimeHandlerNotifierWithEqualityAndDebug extends _$RealtimeHandlerNotifier {
  _$$RealtimeHandlerNotifierWithEqualityAndDebug(this.equals, this.debugPrint);

  final Equals equals;
  final void Function(String event, [bool? printOverride]) debugPrint;

  @override
  bool build() => (ref) {
    ref.watch(realtimeHandlerProvider);
    return false;
  }(ref);

  @override
  bool get isConnected => throw new _Private();

  @override
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload}) =>
      throw new _Private();

  @override
  void disconnect() => throw new _Private();
}

/// @nodoc
class _$$RealtimeHandlerNotifierWithEqualityAndDebugAndPostInit extends _$RealtimeHandlerNotifier {
  _$$RealtimeHandlerNotifierWithEqualityAndDebugAndPostInit(
      this.equals, this.debugPrint, this.postInit);

  final Equals equals;
  final void Function(String event, [bool? printOverride]) debugPrint;
  final Future<void> Function() postInit;

  @override
  Future<bool> build() async => (ref) async {
    ref.watch(realtimeHandlerProvider);
    return false;
  }(ref);

  @override
  bool get isConnected => throw new _Private();

  @override
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload}) =>
      throw new _Private();

  @override
  void disconnect() => throw new _Private();
}

/// @nodoc
class _$$RealtimeHandlerNotifierWithEqualityAndDebugAndPostInitAndInitNotifier extends
    _$RealtimeHandlerNotifier {
  _$$RealtimeHandlerNotifierWithEqualityAndDebugAndPostInitAndInitNotifier(
      this.equals, this.debugPrint, this.postInit, this.initNotifier);

  final Equals equals;
  final void Function(String event, [bool? printOverride]) debugPrint;
  final Future<void> Function() postInit;
  final void Function() initNotifier;

  @override
  Future<bool> build() async => (ref) async {
    ref.watch(realtimeHandlerProvider);
    return false;
  }(ref);

  @override
  bool get isConnected => throw new _Private();

  @override
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload}) =>
      throw new _Private();

  @override
  void disconnect() => throw new _Private();
}

/// @nodoc
class _$$RealtimeHandlerNotifierWithEqualityAndDebugAndPostInitAndInitNotifierAndDispose extends
    _$RealtimeHandlerNotifier {
  _$$RealtimeHandlerNotifierWithEqualityAndDebugAndPostInitAndInitNotifierAndDispose(
      this.equals, this.debugPrint, this.postInit, this.initNotifier, this.dispose);

  final Equals equals;
  final void Function(String event, [bool? printOverride]) debugPrint;
  final Future<void> Function() postInit;
  final void Function() initNotifier;
  final void Function() dispose;

  @override
  Future<bool> build() async => (ref) async {
    ref.watch(realtimeHandlerProvider);
    return false;
  }(ref);

  @override
  bool get isConnected => throw new _Private();

  @override
  void connectWithAuth({required String token, required String email, ReloadCallback? onReload}) =>
      throw new _Private();

  @override
  void disconnect() => throw new _Private();
}

/// @nodoc
class _$RealtimeHandlerCopyWithImpl<$V> extends _$CopyWithImpl<$V> implements $RealtimeHandlerCopyWith<$V> {
  _$RealtimeHandlerCopyWithImpl($RealtimeHandler _value, $V _resolveValue);

  @override
  $RealtimeHandler get _value => super._value as RealtimeHandler;

  @override
  $RealtimeHandlerCopyWith<$V> call({Object? isConnected = null, Object? connectWithAuth = null, Object? disconnect = null}) {
    return _$RealtimeHandlerCopyWithImpl<$V>(_value.copyWith(
      isConnected: isConnected == null ? _value.isConnected : isConnected as bool,
    ), _resolveValue);
  }
}

/// @nodoc
abstract class $RealtimeHandlerCopyWith<$V> {
  factory $RealtimeHandlerCopyWith.$V$V = $RealtimeHandlerCopyWith<$V>;
  $RealtimeHandlerCopyWith<$V> call({Object? isConnected});
}

/// Generated
class _$$RealtimeHandlerNotifierInternal extends _$$RealtimeHandlerNotifierWithEquality {
  _$$RealtimeHandlerNotifierInternal(super.equals);

  @override
  bool build() {
    final internal = RealtimeHandler(cache: ref.watch(isarProvider.notifier).isar);
    ref.onDispose(() => internal.dispose());
    return internal.build();
  }
}

/// Generated
@ProviderFor(RealtimeHandler)
final realtimeHandlerProvider =
    NotifierProvider<RealtimeHandler, bool>.internal(
  RealtimeHandler.new,
  name: r'realtimeHandlerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product') ? null : _$realtimeHandlerHash,
);

typedef _$RealtimeHandler = Notifier<bool>;
