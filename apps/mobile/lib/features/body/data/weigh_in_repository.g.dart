// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weigh_in_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The repository over the profile database (read-only composition stays in
/// data, the application-db rule). Keep-alive: a stateless wrapper that
/// session-owned readers (`bodyWeightReaderProvider`) depend on.

@ProviderFor(weighInRepository)
final weighInRepositoryProvider = WeighInRepositoryProvider._();

/// The repository over the profile database (read-only composition stays in
/// data, the application-db rule). Keep-alive: a stateless wrapper that
/// session-owned readers (`bodyWeightReaderProvider`) depend on.

final class WeighInRepositoryProvider
    extends
        $FunctionalProvider<
          WeighInRepository,
          WeighInRepository,
          WeighInRepository
        >
    with $Provider<WeighInRepository> {
  /// The repository over the profile database (read-only composition stays in
  /// data, the application-db rule). Keep-alive: a stateless wrapper that
  /// session-owned readers (`bodyWeightReaderProvider`) depend on.
  WeighInRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weighInRepositoryProvider',
        isAutoDispose: false,
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

String _$weighInRepositoryHash() => r'7e3a4560ad85a34fa4d590b0dfcd64ad17f898bc';
