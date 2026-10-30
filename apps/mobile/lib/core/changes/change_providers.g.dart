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

String _$changeSetApplierHash() => r'df37aa36b79cee13ccf4370a9de2241180756958';

/// A33 §6: the write gate (transition, read-only copy, inactive profile).
/// Null (always writable) unless the app wiring overrides it.

@ProviderFor(profileWriteGate)
final profileWriteGateProvider = ProfileWriteGateProvider._();

/// A33 §6: the write gate (transition, read-only copy, inactive profile).
/// Null (always writable) unless the app wiring overrides it.

final class ProfileWriteGateProvider
    extends $FunctionalProvider<WriteGate?, WriteGate?, WriteGate?>
    with $Provider<WriteGate?> {
  /// A33 §6: the write gate (transition, read-only copy, inactive profile).
  /// Null (always writable) unless the app wiring overrides it.
  ProfileWriteGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileWriteGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileWriteGateHash();

  @$internal
  @override
  $ProviderElement<WriteGate?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WriteGate? create(Ref ref) {
    return profileWriteGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WriteGate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WriteGate?>(value),
    );
  }
}

String _$profileWriteGateHash() => r'6919b5e8512722dd1100443ec4a6c132ad3d861f';
