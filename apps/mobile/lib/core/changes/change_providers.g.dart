// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Makes the op handlers, one per family, for the applier's database.
/// Composed by `lib/app/app_scope.dart`, the only layer that sees every
/// feature (A01 §3.2).

@ProviderFor(changeOpHandlers)
final changeOpHandlersProvider = ChangeOpHandlersProvider._();

/// Makes the op handlers, one per family, for the applier's database.
/// Composed by `lib/app/app_scope.dart`, the only layer that sees every
/// feature (A01 §3.2).

final class ChangeOpHandlersProvider
    extends
        $FunctionalProvider<
          OpHandlerFactory<AppDatabase>,
          OpHandlerFactory<AppDatabase>,
          OpHandlerFactory<AppDatabase>
        >
    with $Provider<OpHandlerFactory<AppDatabase>> {
  /// Makes the op handlers, one per family, for the applier's database.
  /// Composed by `lib/app/app_scope.dart`, the only layer that sees every
  /// feature (A01 §3.2).
  ChangeOpHandlersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changeOpHandlersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changeOpHandlersHash();

  @$internal
  @override
  $ProviderElement<OpHandlerFactory<AppDatabase>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OpHandlerFactory<AppDatabase> create(Ref ref) {
    return changeOpHandlers(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpHandlerFactory<AppDatabase> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpHandlerFactory<AppDatabase>>(
        value,
      ),
    );
  }
}

String _$changeOpHandlersHash() => r'5dbd1db4ad4360445625c895d02fdd7c69d8adde';

/// The app's single writer over the open profile's database.

@ProviderFor(changeSetApplier)
final changeSetApplierProvider = ChangeSetApplierProvider._();

/// The app's single writer over the open profile's database.

final class ChangeSetApplierProvider
    extends
        $FunctionalProvider<
          ChangeSetApplier<AppDatabase>,
          ChangeSetApplier<AppDatabase>,
          ChangeSetApplier<AppDatabase>
        >
    with $Provider<ChangeSetApplier<AppDatabase>> {
  /// The app's single writer over the open profile's database.
  ChangeSetApplierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changeSetApplierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changeSetApplierHash();

  @$internal
  @override
  $ProviderElement<ChangeSetApplier<AppDatabase>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChangeSetApplier<AppDatabase> create(Ref ref) {
    return changeSetApplier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChangeSetApplier<AppDatabase> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChangeSetApplier<AppDatabase>>(
        value,
      ),
    );
  }
}

String _$changeSetApplierHash() => r'a7e88f86a601cb00a59bd09ea118fbcb8c7a90b7';
