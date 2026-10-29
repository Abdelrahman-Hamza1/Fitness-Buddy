// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weigh_in_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The repository over the profile database (read-only composition stays in
/// data, the application-db rule).

@ProviderFor(weighInRepository)
final weighInRepositoryProvider = WeighInRepositoryProvider._();

/// The repository over the profile database (read-only composition stays in
/// data, the application-db rule).

final class WeighInRepositoryProvider
    extends
        $FunctionalProvider<
          WeighInRepository,
          WeighInRepository,
          WeighInRepository
        >
    with $Provider<WeighInRepository> {
  /// The repository over the profile database (read-only composition stays in
  /// data, the application-db rule).
  WeighInRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weighInRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weighInRepositoryHash();

  @$internal
  @override
  $ProviderElement<WeighInRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WeighInRepository create(Ref ref) {
    return weighInRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeighInRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeighInRepository>(value),
    );
  }
}

String _$weighInRepositoryHash() => r'26d9fee52e23c203b0eb2bdc7f5258ab7282efb5';
