// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adaptive_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weekly check-in rows (`targetChange`), live.

@ProviderFor(targetChangeRows)
final targetChangeRowsProvider = TargetChangeRowsProvider._();

/// The weekly check-in rows (`targetChange`), live.

final class TargetChangeRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProposalRecord>>,
          List<ProposalRecord>,
          Stream<List<ProposalRecord>>
        >
    with
        $FutureModifier<List<ProposalRecord>>,
        $StreamProvider<List<ProposalRecord>> {
  /// The weekly check-in rows (`targetChange`), live.
  TargetChangeRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetChangeRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetChangeRowsHash();

  @$internal
  @override
  $StreamProviderElement<List<ProposalRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProposalRecord>> create(Ref ref) {
    return targetChangeRows(ref);
  }
}

String _$targetChangeRowsHash() => r'749d21b5a0dda20149e3a1520eec5ea6c8e60cea';

/// The answered incomplete-day suggestions (`dayIncomplete`), live.

@ProviderFor(dayIncompleteRows)
final dayIncompleteRowsProvider = DayIncompleteRowsProvider._();

/// The answered incomplete-day suggestions (`dayIncomplete`), live.

final class DayIncompleteRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProposalRecord>>,
          List<ProposalRecord>,
          Stream<List<ProposalRecord>>
        >
    with
        $FutureModifier<List<ProposalRecord>>,
        $StreamProvider<List<ProposalRecord>> {
  /// The answered incomplete-day suggestions (`dayIncomplete`), live.
  DayIncompleteRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dayIncompleteRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dayIncompleteRowsHash();

  @$internal
  @override
  $StreamProviderElement<List<ProposalRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProposalRecord>> create(Ref ref) {
    return dayIncompleteRows(ref);
  }
}

String _$dayIncompleteRowsHash() => r'c01869167ca11467f96864fb4e9719594b981d8f';

/// The estimate's intake days [from]–[to] (A38 D1): the diary totals with
/// meal counts, the day marks and the confirmed-complete answers. Follows
/// every source.

@ProviderFor(adaptiveIntake)
final adaptiveIntakeProvider = AdaptiveIntakeFamily._();

/// The estimate's intake days [from]–[to] (A38 D1): the diary totals with
/// meal counts, the day marks and the confirmed-complete answers. Follows
/// every source.

final class AdaptiveIntakeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IntakeDay>>,
          List<IntakeDay>,
          FutureOr<List<IntakeDay>>
        >
    with $FutureModifier<List<IntakeDay>>, $FutureProvider<List<IntakeDay>> {
  /// The estimate's intake days [from]–[to] (A38 D1): the diary totals with
  /// meal counts, the day marks and the confirmed-complete answers. Follows
  /// every source.
  AdaptiveIntakeProvider._({
    required AdaptiveIntakeFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'adaptiveIntakeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adaptiveIntakeHash();

  @override
  String toString() {
    return r'adaptiveIntakeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<IntakeDay>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IntakeDay>> create(Ref ref) {
    final argument = this.argument as (LocalDate, LocalDate);
    return adaptiveIntake(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is AdaptiveIntakeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adaptiveIntakeHash() => r'f68ec51126e2dd5a83e444707863bc90b4bb40e7';

/// The estimate's intake days [from]–[to] (A38 D1): the diary totals with
/// meal counts, the day marks and the confirmed-complete answers. Follows
/// every source.

final class AdaptiveIntakeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<IntakeDay>>,
          (LocalDate, LocalDate)
        > {
  AdaptiveIntakeFamily._()
    : super(
        retry: null,
        name: r'adaptiveIntakeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The estimate's intake days [from]–[to] (A38 D1): the diary totals with
  /// meal counts, the day marks and the confirmed-complete answers. Follows
  /// every source.

  AdaptiveIntakeProvider call(LocalDate from, LocalDate to) =>
      AdaptiveIntakeProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'adaptiveIntakeProvider';
}

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

/// The [ExpenditureView], or null before setup. Local data only.

@ProviderFor(expenditureView)
final expenditureViewProvider = ExpenditureViewProvider._();

/// The [ExpenditureView], or null before setup. Local data only.

final class ExpenditureViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExpenditureView?>,
          ExpenditureView?,
          FutureOr<ExpenditureView?>
        >
    with $FutureModifier<ExpenditureView?>, $FutureProvider<ExpenditureView?> {
  /// The [ExpenditureView], or null before setup. Local data only.
  ExpenditureViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noAutomaticRetry,
        name: r'expenditureViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenditureViewHash();

  @$internal
  @override
  $FutureProviderElement<ExpenditureView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExpenditureView?> create(Ref ref) {
    return expenditureView(ref);
  }
}

String _$expenditureViewHash() => r'c73a601d535a6f87c0551917fb97ce919c1a2a6b';

/// This week's pending check-in card (or a stale one), or null; the
/// automatic change's note is [appliedCheckInCard].

@ProviderFor(checkInCard)
final checkInCardProvider = CheckInCardProvider._();

/// This week's pending check-in card (or a stale one), or null; the
/// automatic change's note is [appliedCheckInCard].

final class CheckInCardProvider
    extends
        $FunctionalProvider<
          AsyncValue<CheckInCardView?>,
          CheckInCardView?,
          FutureOr<CheckInCardView?>
        >
    with $FutureModifier<CheckInCardView?>, $FutureProvider<CheckInCardView?> {
  /// This week's pending check-in card (or a stale one), or null; the
  /// automatic change's note is [appliedCheckInCard].
  CheckInCardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInCardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInCardHash();

  @$internal
  @override
  $FutureProviderElement<CheckInCardView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CheckInCardView?> create(Ref ref) {
    return checkInCard(ref);
  }
}

String _$checkInCardHash() => r'f47f9b81484f10693c9d5db5f2dca7156e754414';

/// The unseen automatic change's card ("Your target changed … Change
/// back"), or null. Separate from [checkInCard], so a newer week's
/// proposal never hides it: it stays, past the week's end and a restart,
/// until the user says OK or the targets move on (the version it wrote
/// must still be in effect; A38 review 5, 6).

@ProviderFor(appliedCheckInCard)
final appliedCheckInCardProvider = AppliedCheckInCardProvider._();

/// The unseen automatic change's card ("Your target changed … Change
/// back"), or null. Separate from [checkInCard], so a newer week's
/// proposal never hides it: it stays, past the week's end and a restart,
/// until the user says OK or the targets move on (the version it wrote
/// must still be in effect; A38 review 5, 6).

final class AppliedCheckInCardProvider
    extends
        $FunctionalProvider<
          AsyncValue<CheckInCardView?>,
          CheckInCardView?,
          FutureOr<CheckInCardView?>
        >
    with $FutureModifier<CheckInCardView?>, $FutureProvider<CheckInCardView?> {
  /// The unseen automatic change's card ("Your target changed … Change
  /// back"), or null. Separate from [checkInCard], so a newer week's
  /// proposal never hides it: it stays, past the week's end and a restart,
  /// until the user says OK or the targets move on (the version it wrote
  /// must still be in effect; A38 review 5, 6).
  AppliedCheckInCardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appliedCheckInCardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appliedCheckInCardHash();

  @$internal
  @override
  $FutureProviderElement<CheckInCardView?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CheckInCardView?> create(Ref ref) {
    return appliedCheckInCard(ref);
  }
}

String _$appliedCheckInCardHash() =>
    r'135a09606efbc3f0fd17eaed7be9d58a1b7c6383';

/// The most recent unanswered day of the last two weeks that looks
/// incomplete: under half of its target in fewer than two meals (DY-004),
/// not marked, not confirmed, not answered. Never today. Null without one.

@ProviderFor(incompleteDaySuggestion)
final incompleteDaySuggestionProvider = IncompleteDaySuggestionProvider._();

/// The most recent unanswered day of the last two weeks that looks
/// incomplete: under half of its target in fewer than two meals (DY-004),
/// not marked, not confirmed, not answered. Never today. Null without one.

final class IncompleteDaySuggestionProvider
    extends
        $FunctionalProvider<
          AsyncValue<IncompleteDaySuggestion?>,
          IncompleteDaySuggestion?,
          FutureOr<IncompleteDaySuggestion?>
        >
    with
        $FutureModifier<IncompleteDaySuggestion?>,
        $FutureProvider<IncompleteDaySuggestion?> {
  /// The most recent unanswered day of the last two weeks that looks
  /// incomplete: under half of its target in fewer than two meals (DY-004),
  /// not marked, not confirmed, not answered. Never today. Null without one.
  IncompleteDaySuggestionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incompleteDaySuggestionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incompleteDaySuggestionHash();

  @$internal
  @override
  $FutureProviderElement<IncompleteDaySuggestion?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IncompleteDaySuggestion?> create(Ref ref) {
    return incompleteDaySuggestion(ref);
  }
}

String _$incompleteDaySuggestionHash() =>
    r'96a9fdc0ad705c60f19120f3b8fa90eb15aa8840';
