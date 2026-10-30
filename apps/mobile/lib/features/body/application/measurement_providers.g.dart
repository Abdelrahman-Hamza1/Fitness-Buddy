// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live custom types and measurements (A15b D25): reactive, local. No
/// automatic retry: the screens show the error with Try again (UX-052).

@ProviderFor(measurements)
final measurementsProvider = MeasurementsProvider._();

/// The live custom types and measurements (A15b D25): reactive, local. No
/// automatic retry: the screens show the error with Try again (UX-052).

final class MeasurementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MeasurementData>,
          MeasurementData,
          Stream<MeasurementData>
        >
    with $FutureModifier<MeasurementData>, $StreamProvider<MeasurementData> {
  /// The live custom types and measurements (A15b D25): reactive, local. No
  /// automatic retry: the screens show the error with Try again (UX-052).
  MeasurementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noAutomaticRetry,
        name: r'measurementsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measurementsHash();

  @$internal
  @override
  $StreamProviderElement<MeasurementData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MeasurementData> create(Ref ref) {
    return measurements(ref);
  }
}

String _$measurementsHash() => r'e21c87a580d44a91c9fdc4bd50a7de69a035df03';

/// Every type in display order (WB-040, A15b D18): the built-in kinds
/// (waist, chest, hips, arm, thigh, neck, body fat), then custom types by
/// name, each with its series (its latest value and date come from it).

@ProviderFor(latestByType)
final latestByTypeProvider = LatestByTypeProvider._();

/// Every type in display order (WB-040, A15b D18): the built-in kinds
/// (waist, chest, hips, arm, thigh, neck, body fat), then custom types by
/// name, each with its series (its latest value and date come from it).

final class LatestByTypeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MeasurementTypeView>>,
          List<MeasurementTypeView>,
          FutureOr<List<MeasurementTypeView>>
        >
    with
        $FutureModifier<List<MeasurementTypeView>>,
        $FutureProvider<List<MeasurementTypeView>> {
  /// Every type in display order (WB-040, A15b D18): the built-in kinds
  /// (waist, chest, hips, arm, thigh, neck, body fat), then custom types by
  /// name, each with its series (its latest value and date come from it).
  LatestByTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestByTypeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestByTypeHash();

  @$internal
  @override
  $FutureProviderElement<List<MeasurementTypeView>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MeasurementTypeView>> create(Ref ref) {
    return latestByType(ref);
  }
}

String _$latestByTypeHash() => r'52fdc71c2547cc7e591b872e1fb4a07eca139381';

/// The type of route key [key] (`MeasurementTypeRef.key`), or `null` when
/// the key is unknown or the custom type was removed.

@ProviderFor(measurementSeries)
final measurementSeriesProvider = MeasurementSeriesFamily._();

/// The type of route key [key] (`MeasurementTypeRef.key`), or `null` when
/// the key is unknown or the custom type was removed.

final class MeasurementSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<MeasurementTypeView?>,
          MeasurementTypeView?,
          FutureOr<MeasurementTypeView?>
        >
    with
        $FutureModifier<MeasurementTypeView?>,
        $FutureProvider<MeasurementTypeView?> {
  /// The type of route key [key] (`MeasurementTypeRef.key`), or `null` when
  /// the key is unknown or the custom type was removed.
  MeasurementSeriesProvider._({
    required MeasurementSeriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'measurementSeriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$measurementSeriesHash();

  @override
  String toString() {
    return r'measurementSeriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MeasurementTypeView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MeasurementTypeView?> create(Ref ref) {
    final argument = this.argument as String;
    return measurementSeries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MeasurementSeriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$measurementSeriesHash() => r'9a3b70fa39c3dd02619c4375967cec8d285d9d93';

/// The type of route key [key] (`MeasurementTypeRef.key`), or `null` when
/// the key is unknown or the custom type was removed.

final class MeasurementSeriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MeasurementTypeView?>, String> {
  MeasurementSeriesFamily._()
    : super(
        retry: null,
        name: r'measurementSeriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The type of route key [key] (`MeasurementTypeRef.key`), or `null` when
  /// the key is unknown or the custom type was removed.

  MeasurementSeriesProvider call(String key) =>
      MeasurementSeriesProvider._(argument: key, from: this);

  @override
  String toString() => r'measurementSeriesProvider';
}
