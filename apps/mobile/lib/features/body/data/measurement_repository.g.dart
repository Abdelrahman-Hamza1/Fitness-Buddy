// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The repository over the profile database (read-only composition stays
/// in data, the application-db rule).

@ProviderFor(measurementRepository)
final measurementRepositoryProvider = MeasurementRepositoryProvider._();

/// The repository over the profile database (read-only composition stays
/// in data, the application-db rule).

final class MeasurementRepositoryProvider
    extends
        $FunctionalProvider<
          MeasurementRepository,
          MeasurementRepository,
          MeasurementRepository
        >
    with $Provider<MeasurementRepository> {
  /// The repository over the profile database (read-only composition stays
  /// in data, the application-db rule).
  MeasurementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'measurementRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measurementRepositoryHash();

  @$internal
  @override
  $ProviderElement<MeasurementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeasurementRepository create(Ref ref) {
    return measurementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeasurementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeasurementRepository>(value),
    );
  }
}

String _$measurementRepositoryHash() =>
    r'667d6a8c2f35fc50163815bbc3506dfe9e0478d8';
