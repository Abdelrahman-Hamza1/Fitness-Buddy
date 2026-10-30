// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_coverage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The coverage counter.

@ProviderFor(barcodeCoverage)
final barcodeCoverageProvider = BarcodeCoverageProvider._();

/// The coverage counter.

final class BarcodeCoverageProvider
    extends
        $FunctionalProvider<BarcodeCoverage, BarcodeCoverage, BarcodeCoverage>
    with $Provider<BarcodeCoverage> {
  /// The coverage counter.
  BarcodeCoverageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'barcodeCoverageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$barcodeCoverageHash();

  @$internal
  @override
  $ProviderElement<BarcodeCoverage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BarcodeCoverage create(Ref ref) {
    return barcodeCoverage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BarcodeCoverage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BarcodeCoverage>(value),
    );
  }
}

String _$barcodeCoverageHash() => r'0cc598df616456aa2a83c286bb5dc7f9fa9f6adb';

/// The counts for About; refreshed when About opens.

@ProviderFor(barcodeCoverageCounts)
final barcodeCoverageCountsProvider = BarcodeCoverageCountsProvider._();

/// The counts for About; refreshed when About opens.

final class BarcodeCoverageCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<BarcodeCoverageCounts>,
          BarcodeCoverageCounts,
          FutureOr<BarcodeCoverageCounts>
        >
    with
        $FutureModifier<BarcodeCoverageCounts>,
        $FutureProvider<BarcodeCoverageCounts> {
  /// The counts for About; refreshed when About opens.
  BarcodeCoverageCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'barcodeCoverageCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$barcodeCoverageCountsHash();

  @$internal
  @override
  $FutureProviderElement<BarcodeCoverageCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BarcodeCoverageCounts> create(Ref ref) {
    return barcodeCoverageCounts(ref);
  }
}

String _$barcodeCoverageCountsHash() =>
    r'3ad2713c67a140003a3a5a0e5ae7fe851f340167';
