// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'targets_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only repository composition stays in data (application-db rule).
/// Kept alive like the diary's: stateless over the profile's database, and
/// the session-owned `TargetsActions` reads through it.

@ProviderFor(targetsRepository)
final targetsRepositoryProvider = TargetsRepositoryProvider._();

/// Read-only repository composition stays in data (application-db rule).
/// Kept alive like the diary's: stateless over the profile's database, and
/// the session-owned `TargetsActions` reads through it.

final class TargetsRepositoryProvider
    extends
        $FunctionalProvider<
          TargetsRepository,
          TargetsRepository,
          TargetsRepository
        >
    with $Provider<TargetsRepository> {
  /// Read-only repository composition stays in data (application-db rule).
  /// Kept alive like the diary's: stateless over the profile's database, and
  /// the session-owned `TargetsActions` reads through it.
  TargetsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TargetsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TargetsRepository create(Ref ref) {
    return targetsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TargetsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TargetsRepository>(value),
    );
  }
}

String _$targetsRepositoryHash() => r'd2495d20ae1c08a687c50e70504a77c2c536d464';
