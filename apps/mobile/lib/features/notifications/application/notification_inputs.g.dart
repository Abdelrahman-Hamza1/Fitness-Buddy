// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [NotificationInputs] now: the settings and the local data the rules
/// need. Follows every source, so a logged meal, a weigh-in, a session, a
/// resolved card or a settings change re-plans (A40 D6). Today comes from
/// the clock (the coordinator invalidates this on resume, so a new day or
/// time zone is read). With the master switch off nothing else is read.

@ProviderFor(notificationInputs)
final notificationInputsProvider = NotificationInputsProvider._();

/// The [NotificationInputs] now: the settings and the local data the rules
/// need. Follows every source, so a logged meal, a weigh-in, a session, a
/// resolved card or a settings change re-plans (A40 D6). Today comes from
/// the clock (the coordinator invalidates this on resume, so a new day or
/// time zone is read). With the master switch off nothing else is read.

final class NotificationInputsProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationInputs>,
          NotificationInputs,
          FutureOr<NotificationInputs>
        >
    with
        $FutureModifier<NotificationInputs>,
        $FutureProvider<NotificationInputs> {
  /// The [NotificationInputs] now: the settings and the local data the rules
  /// need. Follows every source, so a logged meal, a weigh-in, a session, a
  /// resolved card or a settings change re-plans (A40 D6). Today comes from
  /// the clock (the coordinator invalidates this on resume, so a new day or
  /// time zone is read). With the master switch off nothing else is read.
  NotificationInputsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationInputsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationInputsHash();

  @$internal
  @override
  $FutureProviderElement<NotificationInputs> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationInputs> create(Ref ref) {
    return notificationInputs(ref);
  }
}

String _$notificationInputsHash() =>
    r'a5d0ea8c34d5b7d1f8f6a07eb9b1fa72b3cafda6';

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
    required LocalDate super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<DayMark>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DayMark>> create(Ref ref) {
    final argument = this.argument as LocalDate;
    return _marks(ref, argument);
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

String _$_marksHash() => r'0e7b8cfa1732a7844b0c40ef3ed8dc3d0583199b';

final class _MarksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<DayMark>>, LocalDate> {
  _MarksFamily._()
    : super(
        retry: null,
        name: r'_marksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _MarksProvider call(LocalDate date) =>
      _MarksProvider._(argument: date, from: this);

  @override
  String toString() => r'_marksProvider';
}

/// Buddy's pending meal cards (NT-002); the weekly check-in is announced
/// with the summary (NT-004), not as a pending card.

@ProviderFor(_pendingCards)
final _pendingCardsProvider = _PendingCardsProvider._();

/// Buddy's pending meal cards (NT-002); the weekly check-in is announced
/// with the summary (NT-004), not as a pending card.

final class _PendingCardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProposalRecord>>,
          List<ProposalRecord>,
          Stream<List<ProposalRecord>>
        >
    with
        $FutureModifier<List<ProposalRecord>>,
        $StreamProvider<List<ProposalRecord>> {
  /// Buddy's pending meal cards (NT-002); the weekly check-in is announced
  /// with the summary (NT-004), not as a pending card.
  _PendingCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_pendingCardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_pendingCardsHash();

  @$internal
  @override
  $StreamProviderElement<List<ProposalRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProposalRecord>> create(Ref ref) {
    return _pendingCards(ref);
  }
}

String _$_pendingCardsHash() => r'f48ea76e7e63e5b7cf6319f39293906e2de9ac60';
