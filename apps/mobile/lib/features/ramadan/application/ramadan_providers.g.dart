// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ramadan_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's Ramadan decisions (LC-030/031, A41a D3).

@ProviderFor(ramadanSettings)
final ramadanSettingsProvider = RamadanSettingsProvider._();

/// The user's Ramadan decisions (LC-030/031, A41a D3).

final class RamadanSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<RamadanSettings>,
          RamadanSettings,
          Stream<RamadanSettings>
        >
    with $FutureModifier<RamadanSettings>, $StreamProvider<RamadanSettings> {
  /// The user's Ramadan decisions (LC-030/031, A41a D3).
  RamadanSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanSettingsHash();

  @$internal
  @override
  $StreamProviderElement<RamadanSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RamadanSettings> create(Ref ref) {
    return ramadanSettings(ref);
  }
}

String _$ramadanSettingsHash() => r'5efa24deba108b84ae4de8e78a4aa58731924a95';

/// How prayer times are computed (LC-033, A41a D2).

@ProviderFor(prayerMethod)
final prayerMethodProvider = PrayerMethodProvider._();

/// How prayer times are computed (LC-033, A41a D2).

final class PrayerMethodProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrayerMethod>,
          PrayerMethod,
          Stream<PrayerMethod>
        >
    with $FutureModifier<PrayerMethod>, $StreamProvider<PrayerMethod> {
  /// How prayer times are computed (LC-033, A41a D2).
  PrayerMethodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'prayerMethodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prayerMethodHash();

  @$internal
  @override
  $StreamProviderElement<PrayerMethod> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PrayerMethod> create(Ref ref) {
    return prayerMethod(ref);
  }
}

String _$prayerMethodHash() => r'a37ae31979fa221a5281e3d2f1c47326d6d877b6';

/// The days marked not fasting (LC-034) in the Ramadans with the mode on:
/// one per-date setting each (A41a fix round 2).

@ProviderFor(ramadanNotFasting)
final ramadanNotFastingProvider = RamadanNotFastingProvider._();

/// The days marked not fasting (LC-034) in the Ramadans with the mode on:
/// one per-date setting each (A41a fix round 2).

final class RamadanNotFastingProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<LocalDate>>,
          Set<LocalDate>,
          Stream<Set<LocalDate>>
        >
    with $FutureModifier<Set<LocalDate>>, $StreamProvider<Set<LocalDate>> {
  /// The days marked not fasting (LC-034) in the Ramadans with the mode on:
  /// one per-date setting each (A41a fix round 2).
  RamadanNotFastingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanNotFastingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanNotFastingHash();

  @$internal
  @override
  $StreamProviderElement<Set<LocalDate>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<LocalDate>> create(Ref ref) {
    return ramadanNotFasting(ref);
  }
}

String _$ramadanNotFastingHash() => r'dc5c9a59c70437de5cef9111d1d00d7f382ebc5c';

/// The Ramadan calendar over the stored decisions (A41a D1).

@ProviderFor(ramadanCalendar)
final ramadanCalendarProvider = RamadanCalendarProvider._();

/// The Ramadan calendar over the stored decisions (A41a D1).

final class RamadanCalendarProvider
    extends
        $FunctionalProvider<
          AsyncValue<RamadanCalendar>,
          RamadanCalendar,
          FutureOr<RamadanCalendar>
        >
    with $FutureModifier<RamadanCalendar>, $FutureProvider<RamadanCalendar> {
  /// The Ramadan calendar over the stored decisions (A41a D1).
  RamadanCalendarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanCalendarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanCalendarHash();

  @$internal
  @override
  $FutureProviderElement<RamadanCalendar> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RamadanCalendar> create(Ref ref) {
    return ramadanCalendar(ref);
  }
}

String _$ramadanCalendarHash() => r'46a7b509129f103a49471116012b63d076f8febb';

/// [LocalPrayerTimes] of the fasting day [date] (the city's calendar date).

@ProviderFor(prayerTimes)
final prayerTimesProvider = PrayerTimesFamily._();

/// [LocalPrayerTimes] of the fasting day [date] (the city's calendar date).

final class PrayerTimesProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalPrayerTimes?>,
          LocalPrayerTimes?,
          FutureOr<LocalPrayerTimes?>
        >
    with
        $FutureModifier<LocalPrayerTimes?>,
        $FutureProvider<LocalPrayerTimes?> {
  /// [LocalPrayerTimes] of the fasting day [date] (the city's calendar date).
  PrayerTimesProvider._({
    required PrayerTimesFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'prayerTimesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$prayerTimesHash();

  @override
  String toString() {
    return r'prayerTimesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LocalPrayerTimes?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LocalPrayerTimes?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return prayerTimes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PrayerTimesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$prayerTimesHash() => r'01f03fb7d084b3e134bd0796728efca5728cd455';

/// [LocalPrayerTimes] of the fasting day [date] (the city's calendar date).

final class PrayerTimesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LocalPrayerTimes?>, LocalDate> {
  PrayerTimesFamily._()
    : super(
        retry: null,
        name: r'prayerTimesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [LocalPrayerTimes] of the fasting day [date] (the city's calendar date).

  PrayerTimesProvider call(LocalDate date) =>
      PrayerTimesProvider._(argument: date, from: this);

  @override
  String toString() => r'prayerTimesProvider';
}

/// The Ramadan to propose switching on for today (LC-031, A41a D4), or
/// null.

@ProviderFor(ramadanProposal)
final ramadanProposalProvider = RamadanProposalProvider._();

/// The Ramadan to propose switching on for today (LC-031, A41a D4), or
/// null.

final class RamadanProposalProvider
    extends
        $FunctionalProvider<
          AsyncValue<RamadanPeriod?>,
          RamadanPeriod?,
          FutureOr<RamadanPeriod?>
        >
    with $FutureModifier<RamadanPeriod?>, $FutureProvider<RamadanPeriod?> {
  /// The Ramadan to propose switching on for today (LC-031, A41a D4), or
  /// null.
  RamadanProposalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanProposalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanProposalHash();

  @$internal
  @override
  $FutureProviderElement<RamadanPeriod?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RamadanPeriod?> create(Ref ref) {
    return ramadanProposal(ref);
  }
}

String _$ramadanProposalHash() => r'57235111658be40119df7a355f78b0dfd02cb288';

/// [RamadanStatus] on today.

@ProviderFor(ramadanStatus)
final ramadanStatusProvider = RamadanStatusProvider._();

/// [RamadanStatus] on today.

final class RamadanStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<RamadanStatus?>,
          RamadanStatus?,
          FutureOr<RamadanStatus?>
        >
    with $FutureModifier<RamadanStatus?>, $FutureProvider<RamadanStatus?> {
  /// [RamadanStatus] on today.
  RamadanStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanStatusHash();

  @$internal
  @override
  $FutureProviderElement<RamadanStatus?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RamadanStatus?> create(Ref ref) {
    return ramadanStatus(ref);
  }
}

String _$ramadanStatusHash() => r'0c83875c4ec8458429a70384ef66708cc4e1cae2';

/// The Ramadan periods whose mode is on, for chart shading (WB-021).

@ProviderFor(ramadanOnPeriods)
final ramadanOnPeriodsProvider = RamadanOnPeriodsProvider._();

/// The Ramadan periods whose mode is on, for chart shading (WB-021).

final class RamadanOnPeriodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RamadanPeriod>>,
          List<RamadanPeriod>,
          FutureOr<List<RamadanPeriod>>
        >
    with
        $FutureModifier<List<RamadanPeriod>>,
        $FutureProvider<List<RamadanPeriod>> {
  /// The Ramadan periods whose mode is on, for chart shading (WB-021).
  RamadanOnPeriodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanOnPeriodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanOnPeriodsHash();

  @$internal
  @override
  $FutureProviderElement<List<RamadanPeriod>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RamadanPeriod>> create(Ref ref) {
    return ramadanOnPeriods(ref);
  }
}

String _$ramadanOnPeriodsHash() => r'c9881bb0668f57408e02f807bcbcbf23a1738645';

/// The Ramadan targets offer (TG-060, A41a D8) due today in the weekly
/// summary: the season, when it is due and the targets are generated (a
/// manual target is the user's own number and "maintain" leaves it as is).

@ProviderFor(ramadanTargetsOffer)
final ramadanTargetsOfferProvider = RamadanTargetsOfferProvider._();

/// The Ramadan targets offer (TG-060, A41a D8) due today in the weekly
/// summary: the season, when it is due and the targets are generated (a
/// manual target is the user's own number and "maintain" leaves it as is).

final class RamadanTargetsOfferProvider
    extends
        $FunctionalProvider<
          AsyncValue<RamadanSeason?>,
          RamadanSeason?,
          FutureOr<RamadanSeason?>
        >
    with $FutureModifier<RamadanSeason?>, $FutureProvider<RamadanSeason?> {
  /// The Ramadan targets offer (TG-060, A41a D8) due today in the weekly
  /// summary: the season, when it is due and the targets are generated (a
  /// manual target is the user's own number and "maintain" leaves it as is).
  RamadanTargetsOfferProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ramadanTargetsOfferProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ramadanTargetsOfferHash();

  @$internal
  @override
  $FutureProviderElement<RamadanSeason?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RamadanSeason?> create(Ref ref) {
    return ramadanTargetsOffer(ref);
  }
}

String _$ramadanTargetsOfferHash() =>
    r'0a3e7aa785639eef132091cc30964d1d35946ce9';

/// [RamadanDay] of [date].

@ProviderFor(ramadanDay)
final ramadanDayProvider = RamadanDayFamily._();

/// [RamadanDay] of [date].

final class RamadanDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<RamadanDay?>,
          RamadanDay?,
          FutureOr<RamadanDay?>
        >
    with $FutureModifier<RamadanDay?>, $FutureProvider<RamadanDay?> {
  /// [RamadanDay] of [date].
  RamadanDayProvider._({
    required RamadanDayFamily super.from,
    required LocalDate super.argument,
  }) : super(
         retry: null,
         name: r'ramadanDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ramadanDayHash();

  @override
  String toString() {
    return r'ramadanDayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RamadanDay?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RamadanDay?> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return ramadanDay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RamadanDayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ramadanDayHash() => r'ad09435b6f0bf9aaea73476c436b02d276427243';

/// [RamadanDay] of [date].

final class RamadanDayFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RamadanDay?>, LocalDate> {
  RamadanDayFamily._()
    : super(
        retry: null,
        name: r'ramadanDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [RamadanDay] of [date].

  RamadanDayProvider call(LocalDate date) =>
      RamadanDayProvider._(argument: date, from: this);

  @override
  String toString() => r'ramadanDayProvider';
}
