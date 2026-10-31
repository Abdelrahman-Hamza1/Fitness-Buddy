// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current [SyncView].

@ProviderFor(syncView)
final syncViewProvider = SyncViewProvider._();

/// The current [SyncView].

final class SyncViewProvider
    extends $FunctionalProvider<SyncView, SyncView, SyncView>
    with $Provider<SyncView> {
  /// The current [SyncView].
  SyncViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncViewHash();

  @$internal
  @override
  $ProviderElement<SyncView> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncView create(Ref ref) {
    return syncView(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncView>(value),
    );
  }
}

String _$syncViewHash() => r'5c302ac146ac04e6d1acb20bb9e1125d92d8cdfa';

/// The earlier versions of one row (online, G7).

@ProviderFor(earlierVersions)
final earlierVersionsProvider = EarlierVersionsFamily._();

/// The earlier versions of one row (online, G7).

final class EarlierVersionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EarlierVersion>>,
          List<EarlierVersion>,
          FutureOr<List<EarlierVersion>>
        >
    with
        $FutureModifier<List<EarlierVersion>>,
        $FutureProvider<List<EarlierVersion>> {
  /// The earlier versions of one row (online, G7).
  EarlierVersionsProvider._({
    required EarlierVersionsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'earlierVersionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$earlierVersionsHash();

  @override
  String toString() {
    return r'earlierVersionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<EarlierVersion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EarlierVersion>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return earlierVersions(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is EarlierVersionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$earlierVersionsHash() => r'2dbe2d40f9b0392b80a8959bf9227b0273aab4cc';

/// The earlier versions of one row (online, G7).

final class EarlierVersionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<EarlierVersion>>,
          (String, String)
        > {
  EarlierVersionsFamily._()
    : super(
        retry: null,
        name: r'earlierVersionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The earlier versions of one row (online, G7).

  EarlierVersionsProvider call(String entity, String id) =>
      EarlierVersionsProvider._(argument: (entity, id), from: this);

  @override
  String toString() => r'earlierVersionsProvider';
}

/// Sync commands for the UI.

@ProviderFor(SyncActions)
final syncActionsProvider = SyncActionsProvider._();

/// Sync commands for the UI.
final class SyncActionsProvider extends $NotifierProvider<SyncActions, void> {
  /// Sync commands for the UI.
  SyncActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncActionsHash();

  @$internal
  @override
  SyncActions create() => SyncActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$syncActionsHash() => r'36e5e755e62de7a7bff4ea05d2dba0811f330042';

/// Sync commands for the UI.

abstract class _$SyncActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
