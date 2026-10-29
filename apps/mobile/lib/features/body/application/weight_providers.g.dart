// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live weigh-ins, ordered by local date, measured time and ID (A14
/// D12).

@ProviderFor(weighIns)
final weighInsProvider = WeighInsProvider._();

/// The live weigh-ins, ordered by local date, measured time and ID (A14
/// D12).

final class WeighInsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WeighIn>>,
          List<WeighIn>,
          Stream<List<WeighIn>>
        >
    with $FutureModifier<List<WeighIn>>, $StreamProvider<List<WeighIn>> {
  /// The live weigh-ins, ordered by local date, measured time and ID (A14
  /// D12).
  WeighInsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weighInsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weighInsHash();

  @$internal
  @override
  $StreamProviderElement<List<WeighIn>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WeighIn>> create(Ref ref) {
    return weighIns(ref);
  }
}

String _$weighInsHash() => r'0f9eb11e6dafe4eceba46b51d412a0dabac9e507';

/// The weight trend over the live weigh-ins (WB-010–012, A14 D1/D2/D12):
/// recomputed once per change of the weigh-ins, derived, never stored.

@ProviderFor(weightTrend)
final weightTrendProvider = WeightTrendProvider._();

/// The weight trend over the live weigh-ins (WB-010–012, A14 D1/D2/D12):
/// recomputed once per change of the weigh-ins, derived, never stored.

final class WeightTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeightTrend>,
          WeightTrend,
          Stream<WeightTrend>
        >
    with $FutureModifier<WeightTrend>, $StreamProvider<WeightTrend> {
  /// The weight trend over the live weigh-ins (WB-010–012, A14 D1/D2/D12):
  /// recomputed once per change of the weigh-ins, derived, never stored.
  WeightTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightTrendHash();

  @$internal
  @override
  $StreamProviderElement<WeightTrend> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WeightTrend> create(Ref ref) {
    return weightTrend(ref);
  }
}

String _$weightTrendHash() => r'88cfb78c5c7ccba66a1edd3542137a967045696e';

/// The app's current weight in kg: the latest trend, `null` without
/// weigh-ins (A14 PA1, a fixed name: targets (A13) read weight only through
/// this and `weightTrendProvider`'s `trendOn(date)`; there is no profile
/// weight).

@ProviderFor(currentWeightKg)
final currentWeightKgProvider = CurrentWeightKgProvider._();

/// The app's current weight in kg: the latest trend, `null` without
/// weigh-ins (A14 PA1, a fixed name: targets (A13) read weight only through
/// this and `weightTrendProvider`'s `trendOn(date)`; there is no profile
/// weight).

final class CurrentWeightKgProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, Stream<double?>>
    with $FutureModifier<double?>, $StreamProvider<double?> {
  /// The app's current weight in kg: the latest trend, `null` without
  /// weigh-ins (A14 PA1, a fixed name: targets (A13) read weight only through
  /// this and `weightTrendProvider`'s `trendOn(date)`; there is no profile
  /// weight).
  CurrentWeightKgProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentWeightKgProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentWeightKgHash();

  @$internal
  @override
  $StreamProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double?> create(Ref ref) {
    return currentWeightKg(ref);
  }
}

String _$currentWeightKgHash() => r'11a978c2b1b311c19c60cf62ce91dc6d4a9b4b15';
