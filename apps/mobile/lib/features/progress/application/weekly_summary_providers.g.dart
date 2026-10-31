// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_summary_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The first day of the week containing today (follows midnight and the
/// week-start setting).

@ProviderFor(currentWeekStart)
final currentWeekStartProvider = CurrentWeekStartProvider._();

/// The first day of the week containing today (follows midnight and the
/// week-start setting).

final class CurrentWeekStartProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalDate>,
          LocalDate,
          FutureOr<LocalDate>
        >
    with $FutureModifier<LocalDate>, $FutureProvider<LocalDate> {
  /// The first day of the week containing today (follows midnight and the
  /// week-start setting).
  CurrentWeekStartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentWeekStartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentWeekStartHash();

  @$internal
  @override
  $FutureProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LocalDate> create(Ref ref) {
    return currentWeekStart(ref);
  }
}

String _$currentWeekStartHash() => r'2180e11aa5fc8f282bbf85c71726994793c6ddb8';

/// The [WeeklySummary] of the week from [weekStart] (IN-001, A39a D1):
/// the same per-date series as the charts ([progressDaysProvider], so the
/// numbers agree with them), the weight trend and the week's workouts. All
/// local; follows every source. A week after today has no summary (null).
/// No automatic retry: the card shows the error with Try again (UX-052).

@ProviderFor(weeklySummary)
final weeklySummaryProvider = WeeklySummaryFamily._();

/// The [WeeklySummary] of the week from [weekStart] (IN-001, A39a D1):
/// the same per-date series as the charts ([progressDaysProvider], so the
/// numbers agree with them), the weight trend and the week's workouts. All
/// local; follows every source. A week after today has no summary (null).
/// No automatic retry: the card shows the error with Try again (UX-052).

final class WeeklySummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeeklySummary?>,
          WeeklySummary?,
          FutureOr<WeeklySummary?>
        >
    with $FutureModifier<WeeklySummary?>, $FutureProvider<WeeklySummary?> {
  /// The [WeeklySummary] of the week from [weekStart] (IN-001, A39a D1):
  /// the same per-date series as the charts ([progressDaysProvider], so the
  /// numbers agree with them), the weight trend and the week's workouts. All
  /// local; follows every source. A week after today has no summary (null).
  /// No automatic retry: the card shows the error with Try again (UX-052).
  WeeklySummaryProvider._({
    required WeeklySummaryFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: _noAutomaticRetry,
         name: r'weeklySummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weeklySummaryHash();

  @override
  String toString() {
    return r'weeklySummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WeeklySummary?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeeklySummary?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return weeklySummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklySummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weeklySummaryHash() => r'4717294c8565e484d4b4bd3e27eee490ec2ccf4e';

/// The [WeeklySummary] of the week from [weekStart] (IN-001, A39a D1):
/// the same per-date series as the charts ([progressDaysProvider], so the
/// numbers agree with them), the weight trend and the week's workouts. All
/// local; follows every source. A week after today has no summary (null).
/// No automatic retry: the card shows the error with Try again (UX-052).

final class WeeklySummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WeeklySummary?>, LocalDate> {
  WeeklySummaryFamily._()
    : super(
        retry: _noAutomaticRetry,
        name: r'weeklySummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The [WeeklySummary] of the week from [weekStart] (IN-001, A39a D1):
  /// the same per-date series as the charts ([progressDaysProvider], so the
  /// numbers agree with them), the weight trend and the week's workouts. All
  /// local; follows every source. A week after today has no summary (null).
  /// No automatic retry: the card shows the error with Try again (UX-052).

  WeeklySummaryProvider call(LocalDate weekStart) =>
      WeeklySummaryProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'weeklySummaryProvider';
}

/// The earliest date a weekly summary can show (IN-001 "any past week"):
/// the charts' earliest data date or the first logged workout, whichever
/// is earlier, so a week with only workouts is reachable (A40 review 7).

@ProviderFor(summaryEarliestDate)
final summaryEarliestDateProvider = SummaryEarliestDateProvider._();

/// The earliest date a weekly summary can show (IN-001 "any past week"):
/// the charts' earliest data date or the first logged workout, whichever
/// is earlier, so a week with only workouts is reachable (A40 review 7).

final class SummaryEarliestDateProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalDate>,
          LocalDate,
          FutureOr<LocalDate>
        >
    with $FutureModifier<LocalDate>, $FutureProvider<LocalDate> {
  /// The earliest date a weekly summary can show (IN-001 "any past week"):
  /// the charts' earliest data date or the first logged workout, whichever
  /// is earlier, so a week with only workouts is reachable (A40 review 7).
  SummaryEarliestDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'summaryEarliestDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$summaryEarliestDateHash();

  @$internal
  @override
  $FutureProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LocalDate> create(Ref ref) {
    return summaryEarliestDate(ref);
  }
}

String _$summaryEarliestDateHash() =>
    r'd2216ad664c27e93f8ad902a1243a9cd9d069623';
