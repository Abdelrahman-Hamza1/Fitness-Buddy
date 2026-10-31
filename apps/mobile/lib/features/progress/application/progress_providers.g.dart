// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The diary days [from]–[to] (inclusive) the charts need: each day with
/// entries or a mark, from the indexed per-day totals and the day marks
/// (A16 D2). Days with neither are left out (unknown, TG-032).

@ProviderFor(progressLogs)
final progressLogsProvider = ProgressLogsFamily._();

/// The diary days [from]–[to] (inclusive) the charts need: each day with
/// entries or a mark, from the indexed per-day totals and the day marks
/// (A16 D2). Days with neither are left out (unknown, TG-032).

final class ProgressLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DayLog>>,
          List<DayLog>,
          FutureOr<List<DayLog>>
        >
    with $FutureModifier<List<DayLog>>, $FutureProvider<List<DayLog>> {
  /// The diary days [from]–[to] (inclusive) the charts need: each day with
  /// entries or a mark, from the indexed per-day totals and the day marks
  /// (A16 D2). Days with neither are left out (unknown, TG-032).
  ProgressLogsProvider._({
    required ProgressLogsFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'progressLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressLogsHash();

  @override
  String toString() {
    return r'progressLogsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<DayLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DayLog>> create(Ref ref) {
    final argument = this.argument as (LocalDate, LocalDate);
    return progressLogs(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressLogsHash() => r'c6e56d76b523f2f7dbd9db57bdedb9ff34df4cc2';

/// The diary days [from]–[to] (inclusive) the charts need: each day with
/// entries or a mark, from the indexed per-day totals and the day marks
/// (A16 D2). Days with neither are left out (unknown, TG-032).

final class ProgressLogsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<DayLog>>,
          (LocalDate, LocalDate)
        > {
  ProgressLogsFamily._()
    : super(
        retry: null,
        name: r'progressLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The diary days [from]–[to] (inclusive) the charts need: each day with
  /// entries or a mark, from the indexed per-day totals and the day marks
  /// (A16 D2). Days with neither are left out (unknown, TG-032).

  ProgressLogsProvider call(LocalDate from, LocalDate to) =>
      ProgressLogsProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'progressLogsProvider';
}

@ProviderFor(_progressTotals)
final _progressTotalsProvider = _ProgressTotalsFamily._();

final class _ProgressTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailyTotals>>,
          List<DailyTotals>,
          Stream<List<DailyTotals>>
        >
    with
        $FutureModifier<List<DailyTotals>>,
        $StreamProvider<List<DailyTotals>> {
  _ProgressTotalsProvider._({
    required _ProgressTotalsFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'_progressTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_progressTotalsHash();

  @override
  String toString() {
    return r'_progressTotalsProvider'
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
    return _progressTotals(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _ProgressTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_progressTotalsHash() => r'd3ba462487f736fc42559a2f4f23045c4167112e';

final class _ProgressTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<DailyTotals>>,
          (LocalDate, LocalDate)
        > {
  _ProgressTotalsFamily._()
    : super(
        retry: null,
        name: r'_progressTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _ProgressTotalsProvider call(LocalDate from, LocalDate to) =>
      _ProgressTotalsProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'_progressTotalsProvider';
}

@ProviderFor(_progressMarks)
final _progressMarksProvider = _ProgressMarksFamily._();

final class _ProgressMarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DayMark>>,
          List<DayMark>,
          Stream<List<DayMark>>
        >
    with $FutureModifier<List<DayMark>>, $StreamProvider<List<DayMark>> {
  _ProgressMarksProvider._({
    required _ProgressMarksFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'_progressMarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_progressMarksHash();

  @override
  String toString() {
    return r'_progressMarksProvider'
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
    return _progressMarks(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _ProgressMarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_progressMarksHash() => r'84dd9754028680f79f4d1e075f5267a17fad9e1e';

final class _ProgressMarksFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<DayMark>>,
          (LocalDate, LocalDate)
        > {
  _ProgressMarksFamily._()
    : super(
        retry: null,
        name: r'_progressMarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _ProgressMarksProvider call(LocalDate from, LocalDate to) =>
      _ProgressMarksProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'_progressMarksProvider';
}

/// Every date from [from] to the earlier of [to] and today with its intake,
/// status and target (A16 D6): [ProgressSeries.build] over the same inputs
/// `dayTargetsProvider` uses (the stored targets, the week start, the
/// trend, the training input), so a day's target equals Today's for it
/// (G10). Follows every source. No automatic retry: the screen shows the
/// error with Try again (UX-052).

@ProviderFor(progressDays)
final progressDaysProvider = ProgressDaysFamily._();

/// Every date from [from] to the earlier of [to] and today with its intake,
/// status and target (A16 D6): [ProgressSeries.build] over the same inputs
/// `dayTargetsProvider` uses (the stored targets, the week start, the
/// trend, the training input), so a day's target equals Today's for it
/// (G10). Follows every source. No automatic retry: the screen shows the
/// error with Try again (UX-052).

final class ProgressDaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProgressDay>>,
          List<ProgressDay>,
          FutureOr<List<ProgressDay>>
        >
    with
        $FutureModifier<List<ProgressDay>>,
        $FutureProvider<List<ProgressDay>> {
  /// Every date from [from] to the earlier of [to] and today with its intake,
  /// status and target (A16 D6): [ProgressSeries.build] over the same inputs
  /// `dayTargetsProvider` uses (the stored targets, the week start, the
  /// trend, the training input), so a day's target equals Today's for it
  /// (G10). Follows every source. No automatic retry: the screen shows the
  /// error with Try again (UX-052).
  ProgressDaysProvider._({
    required ProgressDaysFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: _noAutomaticRetry,
         name: r'progressDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressDaysHash();

  @override
  String toString() {
    return r'progressDaysProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProgressDay>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProgressDay>> create(Ref ref) {
    final argument = this.argument as (LocalDate, LocalDate);
    return progressDays(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressDaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressDaysHash() => r'f4b43e7c05cf3252d39d4d577f395ef06dfccb7c';

/// Every date from [from] to the earlier of [to] and today with its intake,
/// status and target (A16 D6): [ProgressSeries.build] over the same inputs
/// `dayTargetsProvider` uses (the stored targets, the week start, the
/// trend, the training input), so a day's target equals Today's for it
/// (G10). Follows every source. No automatic retry: the screen shows the
/// error with Try again (UX-052).

final class ProgressDaysFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProgressDay>>,
          (LocalDate, LocalDate)
        > {
  ProgressDaysFamily._()
    : super(
        retry: _noAutomaticRetry,
        name: r'progressDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every date from [from] to the earlier of [to] and today with its intake,
  /// status and target (A16 D6): [ProgressSeries.build] over the same inputs
  /// `dayTargetsProvider` uses (the stored targets, the week start, the
  /// trend, the training input), so a day's target equals Today's for it
  /// (G10). Follows every source. No automatic retry: the screen shows the
  /// error with Try again (UX-052).

  ProgressDaysProvider call(LocalDate from, LocalDate to) =>
      ProgressDaysProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'progressDaysProvider';
}

/// The earliest date ‹ can reach (A16 D14): the first diary day (a live
/// entry or day mark), settings version, weigh-in or phase start; today
/// without any.

@ProviderFor(progressEarliestDate)
final progressEarliestDateProvider = ProgressEarliestDateProvider._();

/// The earliest date ‹ can reach (A16 D14): the first diary day (a live
/// entry or day mark), settings version, weigh-in or phase start; today
/// without any.

final class ProgressEarliestDateProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalDate>,
          LocalDate,
          FutureOr<LocalDate>
        >
    with $FutureModifier<LocalDate>, $FutureProvider<LocalDate> {
  /// The earliest date ‹ can reach (A16 D14): the first diary day (a live
  /// entry or day mark), settings version, weigh-in or phase start; today
  /// without any.
  ProgressEarliestDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressEarliestDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressEarliestDateHash();

  @$internal
  @override
  $FutureProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LocalDate> create(Ref ref) {
    return progressEarliestDate(ref);
  }
}

String _$progressEarliestDateHash() =>
    r'4b9834f83a011311200fdedbd83122e07ec6c987';

@ProviderFor(_firstDiaryDate)
final _firstDiaryDateProvider = _FirstDiaryDateProvider._();

final class _FirstDiaryDateProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalDate?>,
          LocalDate?,
          Stream<LocalDate?>
        >
    with $FutureModifier<LocalDate?>, $StreamProvider<LocalDate?> {
  _FirstDiaryDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_firstDiaryDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_firstDiaryDateHash();

  @$internal
  @override
  $StreamProviderElement<LocalDate?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<LocalDate?> create(Ref ref) {
    return _firstDiaryDate(ref);
  }
}

String _$_firstDiaryDateHash() => r'de55b3baf98e05a5208d1b94a587b04da2ff4d7d';

/// The [ProgressView] of the selected period (follows today, the week
/// start, the phases and every diary or targets change).

@ProviderFor(progressView)
final progressViewProvider = ProgressViewProvider._();

/// The [ProgressView] of the selected period (follows today, the week
/// start, the phases and every diary or targets change).

final class ProgressViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressView>,
          ProgressView,
          FutureOr<ProgressView>
        >
    with $FutureModifier<ProgressView>, $FutureProvider<ProgressView> {
  /// The [ProgressView] of the selected period (follows today, the week
  /// start, the phases and every diary or targets change).
  ProgressViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noAutomaticRetry,
        name: r'progressViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressViewHash();

  @$internal
  @override
  $FutureProviderElement<ProgressView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressView> create(Ref ref) {
    return progressView(ref);
  }
}

String _$progressViewHash() => r'07c3db74ac2ccd80c2580cf3c236019d26745206';

/// The selected bar of the calories chart (its details card), or null.
/// Cleared when the period changes.

@ProviderFor(SelectedProgressBar)
final selectedProgressBarProvider = SelectedProgressBarProvider._();

/// The selected bar of the calories chart (its details card), or null.
/// Cleared when the period changes.
final class SelectedProgressBarProvider
    extends $NotifierProvider<SelectedProgressBar, int?> {
  /// The selected bar of the calories chart (its details card), or null.
  /// Cleared when the period changes.
  SelectedProgressBarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedProgressBarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedProgressBarHash();

  @$internal
  @override
  SelectedProgressBar create() => SelectedProgressBar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$selectedProgressBarHash() =>
    r'536999b088afe37939cb0e2ca67714f19dffeeb2';

/// The selected bar of the calories chart (its details card), or null.
/// Cleared when the period changes.

abstract class _$SelectedProgressBar extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The [GoalProgressView] for the selected period, or null without a phase
/// to show. No automatic retry: the card shows the error with Try again.

@ProviderFor(goalProgressCard)
final goalProgressCardProvider = GoalProgressCardProvider._();

/// The [GoalProgressView] for the selected period, or null without a phase
/// to show. No automatic retry: the card shows the error with Try again.

final class GoalProgressCardProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoalProgressView?>,
          GoalProgressView?,
          FutureOr<GoalProgressView?>
        >
    with
        $FutureModifier<GoalProgressView?>,
        $FutureProvider<GoalProgressView?> {
  /// The [GoalProgressView] for the selected period, or null without a phase
  /// to show. No automatic retry: the card shows the error with Try again.
  GoalProgressCardProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noAutomaticRetry,
        name: r'goalProgressCardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalProgressCardHash();

  @$internal
  @override
  $FutureProviderElement<GoalProgressView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GoalProgressView?> create(Ref ref) {
    return goalProgressCard(ref);
  }
}

String _$goalProgressCardHash() => r'63d127fe828e013a990a166fd094bdab40b9461e';

/// The [ProgressWeightView] of the selected period.

@ProviderFor(progressWeight)
final progressWeightProvider = ProgressWeightProvider._();

/// The [ProgressWeightView] of the selected period.

final class ProgressWeightProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProgressWeightView>,
          ProgressWeightView,
          FutureOr<ProgressWeightView>
        >
    with
        $FutureModifier<ProgressWeightView>,
        $FutureProvider<ProgressWeightView> {
  /// The [ProgressWeightView] of the selected period.
  ProgressWeightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressWeightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressWeightHash();

  @$internal
  @override
  $FutureProviderElement<ProgressWeightView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProgressWeightView> create(Ref ref) {
    return progressWeight(ref);
  }
}

String _$progressWeightHash() => r'175ce530f8b5154bb684479210789aada2ceee89';
