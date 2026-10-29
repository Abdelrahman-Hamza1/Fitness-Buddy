// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_weight.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date] (`WeightTrend.trendOn`), else null, and the
/// projection then falls back to the effective version's `basis_weight_kg`.
/// Weigh-ins are the only stored body weight; there is no profile weight.
/// Callers ([TargetsTimeline.day] through `dayTargetsProvider`) treat null as
/// "use the basis weight". Commands don't watch this: `TargetsActions` reads
/// the same trend once per command through A14's `bodyWeightReaderProvider`.
///
/// Follows every weigh-in change (A14's `weightTrendProvider`, which is
/// auto-disposed, so this is too).

@ProviderFor(bodyWeight)
final bodyWeightProvider = BodyWeightFamily._();

/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date] (`WeightTrend.trendOn`), else null, and the
/// projection then falls back to the effective version's `basis_weight_kg`.
/// Weigh-ins are the only stored body weight; there is no profile weight.
/// Callers ([TargetsTimeline.day] through `dayTargetsProvider`) treat null as
/// "use the basis weight". Commands don't watch this: `TargetsActions` reads
/// the same trend once per command through A14's `bodyWeightReaderProvider`.
///
/// Follows every weigh-in change (A14's `weightTrendProvider`, which is
/// auto-disposed, so this is too).

final class BodyWeightProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  /// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
  /// weight on or before [date] (`WeightTrend.trendOn`), else null, and the
  /// projection then falls back to the effective version's `basis_weight_kg`.
  /// Weigh-ins are the only stored body weight; there is no profile weight.
  /// Callers ([TargetsTimeline.day] through `dayTargetsProvider`) treat null as
  /// "use the basis weight". Commands don't watch this: `TargetsActions` reads
  /// the same trend once per command through A14's `bodyWeightReaderProvider`.
  ///
  /// Follows every weigh-in change (A14's `weightTrendProvider`, which is
  /// auto-disposed, so this is too).
  BodyWeightProvider._({
    required BodyWeightFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'bodyWeightProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bodyWeightHash();

  @override
  String toString() {
    return r'bodyWeightProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return bodyWeight(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BodyWeightProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bodyWeightHash() => r'4be9fecf3c4f46faebc04b93886a45d98724f560';

/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date] (`WeightTrend.trendOn`), else null, and the
/// projection then falls back to the effective version's `basis_weight_kg`.
/// Weigh-ins are the only stored body weight; there is no profile weight.
/// Callers ([TargetsTimeline.day] through `dayTargetsProvider`) treat null as
/// "use the basis weight". Commands don't watch this: `TargetsActions` reads
/// the same trend once per command through A14's `bodyWeightReaderProvider`.
///
/// Follows every weigh-in change (A14's `weightTrendProvider`, which is
/// auto-disposed, so this is too).

final class BodyWeightFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double?>, LocalDate> {
  BodyWeightFamily._()
    : super(
        retry: null,
        name: r'bodyWeightProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
  /// weight on or before [date] (`WeightTrend.trendOn`), else null, and the
  /// projection then falls back to the effective version's `basis_weight_kg`.
  /// Weigh-ins are the only stored body weight; there is no profile weight.
  /// Callers ([TargetsTimeline.day] through `dayTargetsProvider`) treat null as
  /// "use the basis weight". Commands don't watch this: `TargetsActions` reads
  /// the same trend once per command through A14's `bodyWeightReaderProvider`.
  ///
  /// Follows every weigh-in change (A14's `weightTrendProvider`, which is
  /// auto-disposed, so this is too).

  BodyWeightProvider call(LocalDate date) =>
      BodyWeightProvider._(argument: date, from: this);

  @override
  String toString() => r'bodyWeightProvider';
}
