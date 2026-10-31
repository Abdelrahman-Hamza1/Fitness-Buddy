// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'targets_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One read of the targets tables, live (tolerant decode, skipped rows
/// counted). Local only: no spinner beyond the first frame (UX-001).

@ProviderFor(targetsData)
final targetsDataProvider = TargetsDataProvider._();

/// One read of the targets tables, live (tolerant decode, skipped rows
/// counted). Local only: no spinner beyond the first frame (UX-001).

final class TargetsDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<TargetsData>,
          TargetsData,
          Stream<TargetsData>
        >
    with $FutureModifier<TargetsData>, $StreamProvider<TargetsData> {
  /// One read of the targets tables, live (tolerant decode, skipped rows
  /// counted). Local only: no spinner beyond the first frame (UX-001).
  TargetsDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetsDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetsDataHash();

  @$internal
  @override
  $StreamProviderElement<TargetsData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TargetsData> create(Ref ref) {
    return targetsData(ref);
  }
}

String _$targetsDataHash() => r'02c5654f0a438fc8e67b5c5ef4bc85e379867ba4';

/// The live profile with its row version, or null before setup.

@ProviderFor(profile)
final profileProvider = ProfileProvider._();

/// The live profile with its row version, or null before setup.

final class ProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<Versioned<ProfileRecord>?>,
          Versioned<ProfileRecord>?,
          FutureOr<Versioned<ProfileRecord>?>
        >
    with
        $FutureModifier<Versioned<ProfileRecord>?>,
        $FutureProvider<Versioned<ProfileRecord>?> {
  /// The live profile with its row version, or null before setup.
  ProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileHash();

  @$internal
  @override
  $FutureProviderElement<Versioned<ProfileRecord>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Versioned<ProfileRecord>?> create(Ref ref) {
    return profile(ref);
  }
}

String _$profileHash() => r'5afc6b16ac802584c14b489e4997d5472c232c03';

/// The live goal phases and their projection (TG-012).

@ProviderFor(goalHistory)
final goalHistoryProvider = GoalHistoryProvider._();

/// The live goal phases and their projection (TG-012).

final class GoalHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoalPhases>,
          GoalPhases,
          FutureOr<GoalPhases>
        >
    with $FutureModifier<GoalPhases>, $FutureProvider<GoalPhases> {
  /// The live goal phases and their projection (TG-012).
  GoalHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalHistoryHash();

  @$internal
  @override
  $FutureProviderElement<GoalPhases> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GoalPhases> create(Ref ref) {
    return goalHistory(ref);
  }
}

String _$goalHistoryHash() => r'ef00f43243d235f53384514b832dad164600c746';

/// The live target settings versions with their row versions.

@ProviderFor(targetSettingsRecords)
final targetSettingsRecordsProvider = TargetSettingsRecordsProvider._();

/// The live target settings versions with their row versions.

final class TargetSettingsRecordsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Versioned<TargetSettingsRecord>>>,
          List<Versioned<TargetSettingsRecord>>,
          FutureOr<List<Versioned<TargetSettingsRecord>>>
        >
    with
        $FutureModifier<List<Versioned<TargetSettingsRecord>>>,
        $FutureProvider<List<Versioned<TargetSettingsRecord>>> {
  /// The live target settings versions with their row versions.
  TargetSettingsRecordsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetSettingsRecordsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetSettingsRecordsHash();

  @$internal
  @override
  $FutureProviderElement<List<Versioned<TargetSettingsRecord>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Versioned<TargetSettingsRecord>>> create(Ref ref) {
    return targetSettingsRecords(ref);
  }
}

String _$targetSettingsRecordsHash() =>
    r'2d44543aad8dea8aea67e9d393b637c1426d59b8';

/// The live [SetupStatus].

@ProviderFor(setupStatus)
final setupStatusProvider = SetupStatusProvider._();

/// The live [SetupStatus].

final class SetupStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<SetupStatus>,
          SetupStatus,
          FutureOr<SetupStatus>
        >
    with $FutureModifier<SetupStatus>, $FutureProvider<SetupStatus> {
  /// The live [SetupStatus].
  SetupStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setupStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setupStatusHash();

  @$internal
  @override
  $FutureProviderElement<SetupStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SetupStatus> create(Ref ref) {
    return setupStatus(ref);
  }
}

String _$setupStatusHash() => r'4f6f8df24e890760cc9220fca2c61b4447c20101';

/// Everything Today and Targets show for [date] (D6), derived by
/// [TargetsTimeline.day] from the stored rows, the earlier days of [date]'s
/// week (totals and day marks), the week start and [bodyWeightProvider].
/// Null when there is no profile or no version in effect on [date]
/// (Today's eaten mode). Follows every source: a new entry, a day mark, a
/// week-start change, a targets edit.

@ProviderFor(dayTargets)
final dayTargetsProvider = DayTargetsFamily._();

/// Everything Today and Targets show for [date] (D6), derived by
/// [TargetsTimeline.day] from the stored rows, the earlier days of [date]'s
/// week (totals and day marks), the week start and [bodyWeightProvider].
/// Null when there is no profile or no version in effect on [date]
/// (Today's eaten mode). Follows every source: a new entry, a day mark, a
/// week-start change, a targets edit.

final class DayTargetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DayTargets?>,
          DayTargets?,
          FutureOr<DayTargets?>
        >
    with $FutureModifier<DayTargets?>, $FutureProvider<DayTargets?> {
  /// Everything Today and Targets show for [date] (D6), derived by
  /// [TargetsTimeline.day] from the stored rows, the earlier days of [date]'s
  /// week (totals and day marks), the week start and [bodyWeightProvider].
  /// Null when there is no profile or no version in effect on [date]
  /// (Today's eaten mode). Follows every source: a new entry, a day mark, a
  /// week-start change, a targets edit.
  DayTargetsProvider._({
    required DayTargetsFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'dayTargetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayTargetsHash();

  @override
  String toString() {
    return r'dayTargetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DayTargets?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DayTargets?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return dayTargets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DayTargetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayTargetsHash() => r'd88e1fe1fb5f44aa27182b54d91e4e1008751eeb';

/// Everything Today and Targets show for [date] (D6), derived by
/// [TargetsTimeline.day] from the stored rows, the earlier days of [date]'s
/// week (totals and day marks), the week start and [bodyWeightProvider].
/// Null when there is no profile or no version in effect on [date]
/// (Today's eaten mode). Follows every source: a new entry, a day mark, a
/// week-start change, a targets edit.

final class DayTargetsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DayTargets?>, LocalDate> {
  DayTargetsFamily._()
    : super(
        retry: null,
        name: r'dayTargetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everything Today and Targets show for [date] (D6), derived by
  /// [TargetsTimeline.day] from the stored rows, the earlier days of [date]'s
  /// week (totals and day marks), the week start and [bodyWeightProvider].
  /// Null when there is no profile or no version in effect on [date]
  /// (Today's eaten mode). Follows every source: a new entry, a day mark, a
  /// week-start change, a targets edit.

  DayTargetsProvider call(LocalDate date) =>
      DayTargetsProvider._(argument: date, from: this);

  @override
  String toString() => r'dayTargetsProvider';
}

/// The numbers behind the plain-language explanation of the version in
/// effect on [date] (TG-021, D6), or null before setup.

@ProviderFor(targetsExplanation)
final targetsExplanationProvider = TargetsExplanationFamily._();

/// The numbers behind the plain-language explanation of the version in
/// effect on [date] (TG-021, D6), or null before setup.

final class TargetsExplanationProvider
    extends
        $FunctionalProvider<
          AsyncValue<TargetExplanation?>,
          TargetExplanation?,
          FutureOr<TargetExplanation?>
        >
    with
        $FutureModifier<TargetExplanation?>,
        $FutureProvider<TargetExplanation?> {
  /// The numbers behind the plain-language explanation of the version in
  /// effect on [date] (TG-021, D6), or null before setup.
  TargetsExplanationProvider._({
    required TargetsExplanationFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'targetsExplanationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$targetsExplanationHash();

  @override
  String toString() {
    return r'targetsExplanationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TargetExplanation?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TargetExplanation?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return targetsExplanation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TargetsExplanationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$targetsExplanationHash() =>
    r'2b053cf0e66c952d5553167254822153062aee00';

/// The numbers behind the plain-language explanation of the version in
/// effect on [date] (TG-021, D6), or null before setup.

final class TargetsExplanationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TargetExplanation?>, LocalDate> {
  TargetsExplanationFamily._()
    : super(
        retry: null,
        name: r'targetsExplanationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The numbers behind the plain-language explanation of the version in
  /// effect on [date] (TG-021, D6), or null before setup.

  TargetsExplanationProvider call(LocalDate date) =>
      TargetsExplanationProvider._(argument: date, from: this);

  @override
  String toString() => r'targetsExplanationProvider';
}

/// The diary days [from]–[to] (inclusive) as [DayIntake]s: each day with
/// entries or a mark. Days with neither are left out (unknown, TG-032).

@ProviderFor(_weekIntake)
final _weekIntakeProvider = _WeekIntakeFamily._();

/// The diary days [from]–[to] (inclusive) as [DayIntake]s: each day with
/// entries or a mark. Days with neither are left out (unknown, TG-032).

final class _WeekIntakeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DayIntake>>,
          List<DayIntake>,
          FutureOr<List<DayIntake>>
        >
    with $FutureModifier<List<DayIntake>>, $FutureProvider<List<DayIntake>> {
  /// The diary days [from]–[to] (inclusive) as [DayIntake]s: each day with
  /// entries or a mark. Days with neither are left out (unknown, TG-032).
  _WeekIntakeProvider._({
    required _WeekIntakeFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'_weekIntakeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_weekIntakeHash();

  @override
  String toString() {
    return r'_weekIntakeProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<DayIntake>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DayIntake>> create(Ref ref) {
    final argument = this.argument as (LocalDate, LocalDate);
    return _weekIntake(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _WeekIntakeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_weekIntakeHash() => r'0c4eb930d4fd8d4e0be4f5fd5b981b0453ad36cc';

/// The diary days [from]–[to] (inclusive) as [DayIntake]s: each day with
/// entries or a mark. Days with neither are left out (unknown, TG-032).

final class _WeekIntakeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<DayIntake>>,
          (LocalDate, LocalDate)
        > {
  _WeekIntakeFamily._()
    : super(
        retry: null,
        name: r'_weekIntakeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The diary days [from]–[to] (inclusive) as [DayIntake]s: each day with
  /// entries or a mark. Days with neither are left out (unknown, TG-032).

  _WeekIntakeProvider call(LocalDate from, LocalDate to) =>
      _WeekIntakeProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'_weekIntakeProvider';
}

@ProviderFor(_dailyTotals)
final _dailyTotalsProvider = _DailyTotalsFamily._();

final class _DailyTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailyTotals>>,
          List<DailyTotals>,
          Stream<List<DailyTotals>>
        >
    with
        $FutureModifier<List<DailyTotals>>,
        $StreamProvider<List<DailyTotals>> {
  _DailyTotalsProvider._({
    required _DailyTotalsFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'_dailyTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_dailyTotalsHash();

  @override
  String toString() {
    return r'_dailyTotalsProvider'
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
    return _dailyTotals(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _DailyTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_dailyTotalsHash() => r'46a79939892be997fd2acd0047d845e87e5c464e';

final class _DailyTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<DailyTotals>>,
          (LocalDate, LocalDate)
        > {
  _DailyTotalsFamily._()
    : super(
        retry: null,
        name: r'_dailyTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _DailyTotalsProvider call(LocalDate from, LocalDate to) =>
      _DailyTotalsProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'_dailyTotalsProvider';
}

@ProviderFor(_dayMarks)
final _dayMarksProvider = _DayMarksFamily._();

final class _DayMarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DayMark>>,
          List<DayMark>,
          Stream<List<DayMark>>
        >
    with $FutureModifier<List<DayMark>>, $StreamProvider<List<DayMark>> {
  _DayMarksProvider._({
    required _DayMarksFamily super.from,
    required (LocalDate, LocalDate) super.argument,
  }) : super(
         retry: null,
         name: r'_dayMarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_dayMarksHash();

  @override
  String toString() {
    return r'_dayMarksProvider'
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
    return _dayMarks(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is _DayMarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_dayMarksHash() => r'feefc8d3ae0be4bbbbc7dc45c345d25562349ba4';

final class _DayMarksFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<DayMark>>,
          (LocalDate, LocalDate)
        > {
  _DayMarksFamily._()
    : super(
        retry: null,
        name: r'_dayMarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _DayMarksProvider call(LocalDate from, LocalDate to) =>
      _DayMarksProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'_dayMarksProvider';
}
