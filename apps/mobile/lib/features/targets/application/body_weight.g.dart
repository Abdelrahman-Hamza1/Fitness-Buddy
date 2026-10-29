// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_weight.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date], else null, and the projection then falls back
/// to the effective version's `basis_weight_kg`. Weigh-ins are the only
/// stored body weight; there is no profile weight.
///
/// **Seam (A13a WP4):** A14 (`features/body/`) isn't on `main` yet, so this
/// returns null and every number uses the basis weight. A13b WP6 wires it
/// after A14 merges, by replacing the body with:
///
/// ```dart
/// final trend = await ref.watch(weightTrendProvider.future);
/// return trend.trendOn(date)?.trendKg;
/// ```
///
/// (importing `features/body/body.dart`). Callers ([TargetsTimeline.day],
/// `TargetsActions`) already treat null as "use the basis weight", so the
/// wiring touches only this function.
///
/// Kept alive (one small entry per date asked for) so the session-owned
/// `TargetsActions` can read it.

@ProviderFor(bodyWeight)
final bodyWeightProvider = BodyWeightFamily._();

/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date], else null, and the projection then falls back
/// to the effective version's `basis_weight_kg`. Weigh-ins are the only
/// stored body weight; there is no profile weight.
///
/// **Seam (A13a WP4):** A14 (`features/body/`) isn't on `main` yet, so this
/// returns null and every number uses the basis weight. A13b WP6 wires it
/// after A14 merges, by replacing the body with:
///
/// ```dart
/// final trend = await ref.watch(weightTrendProvider.future);
/// return trend.trendOn(date)?.trendKg;
/// ```
///
/// (importing `features/body/body.dart`). Callers ([TargetsTimeline.day],
/// `TargetsActions`) already treat null as "use the basis weight", so the
/// wiring touches only this function.
///
/// Kept alive (one small entry per date asked for) so the session-owned
/// `TargetsActions` can read it.

final class BodyWeightProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  /// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
  /// weight on or before [date], else null, and the projection then falls back
  /// to the effective version's `basis_weight_kg`. Weigh-ins are the only
  /// stored body weight; there is no profile weight.
  ///
  /// **Seam (A13a WP4):** A14 (`features/body/`) isn't on `main` yet, so this
  /// returns null and every number uses the basis weight. A13b WP6 wires it
  /// after A14 merges, by replacing the body with:
  ///
  /// ```dart
  /// final trend = await ref.watch(weightTrendProvider.future);
  /// return trend.trendOn(date)?.trendKg;
  /// ```
  ///
  /// (importing `features/body/body.dart`). Callers ([TargetsTimeline.day],
  /// `TargetsActions`) already treat null as "use the basis weight", so the
  /// wiring touches only this function.
  ///
  /// Kept alive (one small entry per date asked for) so the session-owned
  /// `TargetsActions` can read it.
  BodyWeightProvider._({
    required BodyWeightFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'bodyWeightProvider',
         isAutoDispose: false,
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

String _$bodyWeightHash() => r'8400865a9b94e3ca108d5e05a0cf4bf3c9d4e6d2';

/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date], else null, and the projection then falls back
/// to the effective version's `basis_weight_kg`. Weigh-ins are the only
/// stored body weight; there is no profile weight.
///
/// **Seam (A13a WP4):** A14 (`features/body/`) isn't on `main` yet, so this
/// returns null and every number uses the basis weight. A13b WP6 wires it
/// after A14 merges, by replacing the body with:
///
/// ```dart
/// final trend = await ref.watch(weightTrendProvider.future);
/// return trend.trendOn(date)?.trendKg;
/// ```
///
/// (importing `features/body/body.dart`). Callers ([TargetsTimeline.day],
/// `TargetsActions`) already treat null as "use the basis weight", so the
/// wiring touches only this function.
///
/// Kept alive (one small entry per date asked for) so the session-owned
/// `TargetsActions` can read it.

final class BodyWeightFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double?>, LocalDate> {
  BodyWeightFamily._()
    : super(
        retry: null,
        name: r'bodyWeightProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
  /// weight on or before [date], else null, and the projection then falls back
  /// to the effective version's `basis_weight_kg`. Weigh-ins are the only
  /// stored body weight; there is no profile weight.
  ///
  /// **Seam (A13a WP4):** A14 (`features/body/`) isn't on `main` yet, so this
  /// returns null and every number uses the basis weight. A13b WP6 wires it
  /// after A14 merges, by replacing the body with:
  ///
  /// ```dart
  /// final trend = await ref.watch(weightTrendProvider.future);
  /// return trend.trendOn(date)?.trendKg;
  /// ```
  ///
  /// (importing `features/body/body.dart`). Callers ([TargetsTimeline.day],
  /// `TargetsActions`) already treat null as "use the basis weight", so the
  /// wiring touches only this function.
  ///
  /// Kept alive (one small entry per date asked for) so the session-owned
  /// `TargetsActions` can read it.

  BodyWeightProvider call(LocalDate date) =>
      BodyWeightProvider._(argument: date, from: this);

  @override
  String toString() => r'bodyWeightProvider';
}
