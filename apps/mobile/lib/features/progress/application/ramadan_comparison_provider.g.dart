// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ramadan_comparison_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Ramadan comparison on Progress (IN-008, A41a D9): the latest
/// Ramadan with the mode on, from its first day until 30 days after its
/// end; null otherwise. Local data only.

@ProviderFor(ramadanComparison)
final ramadanComparisonProvider = RamadanComparisonProvider._();

/// The Ramadan comparison on Progress (IN-008, A41a D9): the latest
/// Ramadan with the mode on, from its first day until 30 days after its
/// end; null otherwise. Local data only.

final class RamadanComparisonProvider
    extends
        $FunctionalProvider<
          AsyncValue<RamadanComparison?>,
          RamadanComparison?,
          FutureOr<RamadanComparison?>
        >
    with
        $FutureModifier<RamadanComparison?>,
        $FutureProvider<RamadanComparison?> {
  /// The Ramadan comparison on Progress (IN-008, A41a D9): the latest
  /// Ramadan with the mode on, from its first day until 30 days after its
  /// end; null otherwise. Local data only.
  RamadanComparisonProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanComparisonProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanComparisonHash();

  @$internal
  @override
  $FutureProviderElement<RamadanComparison?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RamadanComparison?> create(Ref ref) {
    return ramadanComparison(ref);
  }
}

String _$ramadanComparisonHash() => r'f2a1ccd5ad88b97d458b89df23d1c47d17d1fb3a';

@ProviderFor(_totals)
final _totalsProvider = _TotalsFamily._();

final class _TotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailyTotals>>,
          List<DailyTotals>,
          Stream<List<DailyTotals>>
        >
    with
        $FutureModifier<List<DailyTotals>>,
        $StreamProvider<List<DailyTotals>> {
  _TotalsProvider._({
    required _TotalsFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'_totalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_totalsHash();

  @override
  String toString() {
    return r'_totalsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<DailyTotals>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DailyTotals>> create(Ref ref) {
    final argument = this.argument as (LocalDate, LocalDate);
    return _totals(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _TotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_totalsHash() => r'ad68b26357db6ddee0fab40c90f1fa570dd2e1db';

final class _TotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<DailyTotals>>,
          (LocalDate, LocalDate)
        > {
  _TotalsFamily._()
    : super(
        retry: null,
        name: r'_totalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _TotalsProvider call(LocalDate from, LocalDate to) =>
      _TotalsProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'_totalsProvider';
}

@ProviderFor(_marks)
final _marksProvider = _MarksFamily._();

final class _MarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DayMark>>,
          List<DayMark>,
          Stream<List<DayMark>>
        >
    with $FutureModifier<List<DayMark>>, $StreamProvider<List<DayMark>> {
  _MarksProvider._({
    required _MarksFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'_marksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_marksHash();

  @override
  String toString() {
    return r'_marksProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<DayMark>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DayMark>> create(Ref ref) {
    final argument = this.argument as (LocalDate, LocalDate);
    return _marks(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _MarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_marksHash() => r'3ce8ffae049ee021b1d030cb32f310d08a78a5b3';

final class _MarksFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<DayMark>>,
          (LocalDate, LocalDate)
        > {
  _MarksFamily._()
    : super(
        retry: null,
        name: r'_marksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _MarksProvider call(LocalDate from, LocalDate to) =>
      _MarksProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'_marksProvider';
}
