import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/adaptive/application/adaptive_inputs.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'adaptive_actions.g.dart';

/// What a weekly check-in run did (A38 D3).
enum CheckInRun {
  /// Nothing: done this week already, not set up, not ready, or nothing
  /// worth proposing.
  none,

  /// A `targetChange` proposal waits on Progress.
  proposed,

  /// The change was applied automatically (the "ask" setting off).
  applied,
}

/// Why a check-in or suggestion command wrote nothing. Codes only.
enum AdaptiveFailure {
  /// The targets changed since the check-in: only Keep is left.
  stale,

  /// Outside the ±150 kcal cap or below the safety floor (TG-035, SF-010).
  outOfRange,

  /// The row is gone, already answered, or can't be read.
  invalid,

  /// A read or the write failed; nothing was written.
  unavailable,
}

/// The outcome of a check-in or suggestion command. Content-free.
sealed class AdaptiveOutcome {
  const new _();
}

/// Written as one change set; [undoEntryId] undoes it.
final class AdaptiveDone extends AdaptiveOutcome {
  /// The outcome.
  const new(this.undoEntryId) : super._();

  /// The undo entry.
  final String undoEntryId;

  @override
  String toString() => 'AdaptiveDone($undoEntryId)';
}

/// Nothing written, for [reason].
final class AdaptiveFailed extends AdaptiveOutcome {
  /// The outcome.
  const new(this.reason) : super._();

  /// Why.
  final AdaptiveFailure reason;

  @override
  String toString() => 'AdaptiveFailed(${reason.name})';
}

/// Another command is running; nothing written.
final class AdaptivePending extends AdaptiveOutcome {
  /// The outcome.
  const new() : super._();
}

/// The weekly check-in (TG-034, AI-056) and the incomplete-day suggestion
/// (DY-004), A38 D3. Every write is one change set through the single
/// writer; user commands record one undo entry. Local reads only: nothing
/// here touches the network (rule 3).
final class AdaptiveActions {
  /// Dependencies are explicit for deterministic tests.
  new({
    required this.apply,
    required this.undoStack,
    required this.ids,
    required this.clock,
    required this.readTargets,
    required this.diary,
    required this.proposals,
    required this.readWeighIns,
    required this.settings,
    this.defaults = const TargetDefaults(),
  });

  /// The single writer port (`ChangeSetApplier.apply`).
  final Future<ApplyResult> Function(ChangeSet) apply;

  /// Session undo history.
  final UndoStack undoStack;

  /// New proposal and version IDs (UUIDv7).
  final IdGenerator ids;

  /// Today, in the device zone.
  final Clock clock;

  /// A fresh snapshot of the targets tables.
  final Future<TargetsData> Function() readTargets;

  /// The diary's per-day totals and marks.
  final DiaryRepository diary;

  /// The proposal rows.
  final ProposalRepository proposals;

  /// Every live weigh-in.
  final WeighInsReader readWeighIns;

  /// The week start and the check-in mode.
  final SettingsStore settings;

  /// The engine defaults.
  final TargetDefaults defaults;

  bool _busy = false;

  /// Runs this week's check-in once (A38 D3): after the first frame and
  /// when Progress opens. Nothing when a check-in of this week exists (any
  /// status), before setup, before enough data, when today's targets were
  /// set this week (the user's own change wins), or within 50 kcal. Older
  /// pending check-ins are discarded in the same change set. With the
  /// automatic setting, a non-manual target is then changed by a second
  /// change set (no undo entry: Progress offers Change back).
  Future<CheckInRun> runWeeklyCheckIn() async {
    if (_busy) return CheckInRun.none;
    _busy = true;
    try {
      return await _run();
    }
    // A failed read or write leaves nothing half-done (each write is one
    // change set); the next launch tries again.
    on Object {
      return CheckInRun.none;
    } finally {
      _busy = false;
    }
  }

  Future<CheckInRun> _run() async {
    final today = EntryTime.now(clock).localDate;
    final calendar = WeekCalendar(
      weekStart: await settings.read(AppSettings.weekStart),
    );
    final weekStart = calendar.weekStartOf(today);
    final end = weekStart.plusDays(-1);
    final rows = await proposals.byKind(targetChangeKind);
    if (checkInOfWeek(rows, weekStart) != null) return CheckInRun.none;
    final data = await readTargets();
    final profile = data.profile?.value;
    final current = _current(data, today);
    if (profile == null || current == null) return CheckInRun.none;
    if (current.value.effectiveFrom.isAfter(end)) return CheckInRun.none;
    final from = end.plusDays(1 - adaptiveWindowDays);
    final days = await _intake(from, end);
    final weighIns = await readWeighIns();
    final trend = TrendWeight().compute(weighIns);
    // TG-037 (#232): weigh-ins in a Ramadan with the mode on count half.
    final ramadan = RamadanCalendar(
      await settings.read(AppSettings.ramadanSeasons),
    );
    final estimate = adaptiveResultFor(
      end: end,
      data: data,
      days: days,
      weighIns: weighIns,
      trend: trend,
      isRamadan: ramadan.isOn,
      defaults: defaults,
    )?.estimate;
    if (estimate == null) return CheckInRun.none;
    final weight = _weight(trend, today, current.value);
    final decision = AdaptiveCheckIn.decide(
      today: today,
      expenditureKcal: estimate.kcal,
      settings: [for (final s in data.settings) s.value],
      profile: profile,
      goals: [for (final g in data.phases) g.value],
      weightKg: weight,
      defaults: defaults,
    );
    if (!decision.proposes) return CheckInRun.none;
    final automatic =
        await settings.read(AppSettings.checkInMode) == CheckInMode.automatic;
    final draft = TargetChangeDraft(
      weekStart: weekStart,
      versionId: current.value.id,
      versionRevision: current.value.revision,
      fromKcal: decision.currentKcal!,
      toKcal: decision.proposedKcal!,
      recommendedKcal: decision.recommendedKcal!,
      expenditureKcal: estimate.kcal,
      confidence: estimate.confidence,
      fromManual: current.value.manual,
      fromAcknowledged: current.value.acknowledged,
      anomalyDates: estimate.anomalyDates,
      // The automatic setting waits for the user while some days look like
      // errors or the estimate is unsure (A38 review round 2); the card says
      // why.
      hold: !automatic || current.value.manual
          ? null
          : estimate.anomalyDates.isNotEmpty
          ? CheckInHold.anomaly
          : estimate.confidence == ExpenditureConfidence.low
          ? CheckInHold.lowConfidence
          : null,
    );
    final id = ids.next();
    final created = await apply(
      ChangeSet([
        CreateProposal(
          id,
          ProposalRowDraft(
            kind: targetChangeKind,
            codecVersion: adaptiveDraftCodecVersion,
            draftJson: draft.toJson(),
          ),
        ),
        for (final old in rows)
          if (old.isPending) _discard(old),
      ], origin: Origin.system),
    );
    if (created is! Applied) return CheckInRun.none;
    if (!automatic || current.value.manual || draft.hold != null) {
      return CheckInRun.proposed;
    }
    final record = await proposals.byId(id);
    if (record == null) return CheckInRun.proposed;
    // Fresh reads: a sync may have landed since the estimate. The change
    // set rechecks the version and the setting in its transaction too.
    final fresh = await readTargets();
    final plan = _acceptPlan(
      record,
      draft.copyWith(automatic: true),
      data: fresh,
      today: today,
      weight: _weight(
        TrendWeight().compute(await readWeighIns()),
        today,
        current.value,
      ),
      automatic: true,
    );
    if (plan is! _Write) return CheckInRun.proposed;
    try {
      final applied = await apply(
        ChangeSet(plan.ops, origin: Origin.proposal(id)),
      );
      return applied is Applied ? CheckInRun.applied : CheckInRun.proposed;
    }
    // Refused in the transaction (targets or the setting changed): the
    // proposal stays for the user to answer.
    on ChangeRejected {
      return CheckInRun.proposed;
    }
  }

  /// Accepts check-in [proposalId], at [kcal] when the user adjusted it
  /// (within ±150 of the base it was made against, never below today's
  /// floor): today's version is revised to it (D5 rule, a generated base)
  /// and the row resolved, in one change set with Undo. Refused as
  /// [AdaptiveFailure.stale] when the targets changed since.
  Future<AdaptiveOutcome> accept(String proposalId, {double? kcal}) =>
      _command('checkInAccepted', (today) async {
        final record = await proposals.byId(proposalId);
        final draft = record == null
            ? null
            : TargetChangeDraft.tryParse(record.draftJson);
        if (record == null || draft == null || !record.isPending) {
          return const _Refuse(AdaptiveFailure.invalid);
        }
        final data = await readTargets();
        final current = _current(data, today);
        if (current == null) return const _Refuse(AdaptiveFailure.stale);
        final trend = TrendWeight().compute(await readWeighIns());
        return _acceptPlan(
          record,
          kcal == null ? draft : draft.copyWith(toKcal: kcal),
          data: data,
          today: today,
          weight: _weight(trend, today, current.value),
        );
      });

  /// Keeps the current target: check-in [proposalId] is resolved as
  /// discarded, with Undo.
  Future<AdaptiveOutcome> keep(String proposalId) =>
      _command('checkInKept', (today) async {
        final record = await proposals.byId(proposalId);
        if (record == null || !record.isPending) {
          return const _Refuse(AdaptiveFailure.invalid);
        }
        return _Write([_discard(record)], origin: Origin.proposal(proposalId));
      });

  /// Restores the target an automatic check-in [proposalId] replaced, as a
  /// direct revision with Undo. Refused as stale when today's target is no
  /// longer the applied one.
  Future<AdaptiveOutcome> changeBack(String proposalId) =>
      _command('checkInChangedBack', (today) async {
        final record = await proposals.byId(proposalId);
        final draft = record == null
            ? null
            : TargetChangeDraft.tryParse(record.draftJson);
        if (record == null ||
            draft == null ||
            record.status != ProposalStatus.confirmed) {
          return const _Refuse(AdaptiveFailure.invalid);
        }
        final data = await readTargets();
        final current = _current(data, today);
        // The applied version itself, still in effect (A38 review 6).
        if (!draft.automatic ||
            current == null ||
            current.value.manual ||
            current.value.id != draft.appliedVersionId ||
            current.value.revision != draft.appliedRevision) {
          return const _Refuse(AdaptiveFailure.stale);
        }
        final next = TargetSettingsRevision.next(
          current: current.value,
          currentVersion: current.version,
          today: today,
          newId: ids.next(),
          change: (r) => r.copyWith(
            baseKcal: draft.fromKcal,
            manual: draft.fromManual,
            acknowledged: draft.fromAcknowledged,
          ),
        );
        return _Write([
          ExpectCurrentSettings(
            current.value.id,
            current.value.revision,
            generatedOnly: true,
          ),
          PutTargetSettings(next.record, expectedVersion: next.expectedVersion),
          _save(record, draft.copyWith(seen: true)),
        ], origin: Origin.direct);
      });

  /// Hides the "Targets updated" note of automatic check-in [proposalId]
  /// (bookkeeping, no undo entry).
  Future<void> dismissNote(String proposalId) async {
    try {
      final record = await proposals.byId(proposalId);
      final draft = record == null
          ? null
          : TargetChangeDraft.tryParse(record.draftJson);
      if (record == null || draft == null || draft.seen) return;
      await apply(
        ChangeSet([
          _save(record, draft.copyWith(seen: true)),
        ], origin: Origin.system),
      );
    }
    // Optional bookkeeping: the note simply stays.
    on Object {
      return;
    }
  }

  /// Answers the suggestion for [date] "Mark incomplete" (DY-004): the
  /// answered suggestion and the day mark in one change set, with Undo.
  Future<AdaptiveOutcome> markIncomplete(LocalDate date) => _command(
    'dayMarkedIncomplete',
    (today) async {
      if (!date.isBefore(today)) return const _Refuse(AdaptiveFailure.invalid);
      final id = ids.next();
      return _Write([
        ..._answered(id, date, confirmed: true),
        MarkDay(date, incomplete: true),
      ], origin: Origin.proposal(id));
    },
  );

  /// Answers the suggestion for [date] "It was complete": the answered
  /// suggestion only (the day keeps counting), with Undo.
  Future<AdaptiveOutcome> confirmComplete(LocalDate date) => _command(
    'dayConfirmedComplete',
    (today) async {
      if (!date.isBefore(today)) return const _Refuse(AdaptiveFailure.invalid);
      final id = ids.next();
      return _Write(
        _answered(id, date, confirmed: false),
        origin: Origin.proposal(id),
      );
    },
  );

  /// The user says the flagged [dates] are right (their intake is real):
  /// answered suggestions for each, so they count as confirmed and stop
  /// being anomalies (A38 review round 2), with Undo.
  Future<AdaptiveOutcome> confirmDays(List<LocalDate> dates) =>
      _command('daysConfirmed', (today) async {
        final past = [
          for (final d in dates.toSet())
            if (d.isBefore(today)) d,
        ];
        if (past.isEmpty) return const _Refuse(AdaptiveFailure.invalid);
        final first = ids.next();
        return _Write([
          ..._answered(first, past.first, confirmed: false),
          for (final d in past.skip(1))
            ..._answered(ids.next(), d, confirmed: false),
        ], origin: Origin.proposal(first));
      });

  // ---------------------------------------------------------------------

  /// The acceptance of [record] with [draft] (its `toKcal` the base to
  /// set), against the live targets: invalid unless a `targetChange` row
  /// of the supported codec; stale unless today's version is the one it
  /// was made against and the draft's baseline is today's base (raised to
  /// the floor); out of range beyond ±150 of that base or below today's
  /// floor (A38 review 2). The change set first rechecks, in its
  /// transaction, that the version is still in effect (and, [automatic],
  /// still generated and the setting still automatic; review 1).
  _Plan _acceptPlan(
    ProposalRecord record,
    TargetChangeDraft draft, {
    required TargetsData data,
    required LocalDate today,
    required double weight,
    bool automatic = false,
  }) {
    if (record.kind != targetChangeKind ||
        record.codecVersion != adaptiveDraftCodecVersion) {
      return const _Refuse(AdaptiveFailure.invalid);
    }
    final current = _current(data, today);
    final profile = data.profile?.value;
    if (current == null ||
        profile == null ||
        current.value.id != draft.versionId ||
        current.value.revision != draft.versionRevision ||
        (automatic && current.value.manual)) {
      return const _Refuse(AdaptiveFailure.stale);
    }
    final double floor;
    try {
      floor = TargetCalculator.floor(
        profile.toProfile(weight),
        today,
        defaults: defaults,
      );
    }
    // The engine's content-free signal for impossible input (PA3).
    // ignore: avoid_catching_errors
    on ArgumentError {
      return const _Refuse(AdaptiveFailure.invalid);
    }
    final base = current.value.toPlan(floor).baseKcal;
    if (base < floor - .5) return const _Refuse(AdaptiveFailure.invalid);
    if ((draft.fromKcal - base).abs() > .5) {
      return const _Refuse(AdaptiveFailure.stale);
    }
    final to = draft.toKcal;
    if (!to.isFinite ||
        to < floor - .5 ||
        (to - base).abs() > defaults.checkInMaxChangeKcal + .5) {
      return const _Refuse(AdaptiveFailure.outOfRange);
    }
    final next = TargetSettingsRevision.next(
      current: current.value,
      currentVersion: current.version,
      today: today,
      newId: ids.next(),
      change: (r) => r.copyWith(
        baseKcal: to,
        basisWeightKg: TargetRules.input.weight(weight) ? weight : null,
        manual: false,
        acknowledged: false,
      ),
    );
    final original = TargetChangeDraft.tryParse(record.draftJson);
    final mode = AppSettings.checkInMode;
    return _Write([
      ExpectCurrentSettings(
        current.value.id,
        current.value.revision,
        generatedOnly: automatic,
      ),
      if (automatic)
        SettingsOp.expect(mode.name, mode.codec.encode(CheckInMode.automatic)),
      PutTargetSettings(next.record, expectedVersion: next.expectedVersion),
      ResolveProposal(
        record.id,
        expectedBudgetMessageId: record.budgetMessageId,
        to: ProposalStatus.confirmed,
        outcome: original != null && (original.toKcal - to).abs() < .5
            ? ProposalOutcome.unchanged
            : ProposalOutcome.adjusted,
        codecVersion: record.codecVersion,
        interpretationJson: record.interpretationJson,
        draftJson: draft
            .copyWith(
              appliedVersionId: next.record.id,
              appliedRevision: next.record.revision,
            )
            .toJson(),
      ),
    ], origin: Origin.proposal(record.id));
  }

  ResolveProposal _discard(ProposalRecord record) => ResolveProposal(
    record.id,
    expectedBudgetMessageId: record.budgetMessageId,
    to: ProposalStatus.discarded,
    outcome: ProposalOutcome.discarded,
    codecVersion: record.codecVersion,
    interpretationJson: record.interpretationJson,
    draftJson: record.draftJson,
  );

  SaveProposalDraft _save(ProposalRecord record, TargetChangeDraft draft) =>
      SaveProposalDraft(
        record.id,
        expectedBudgetMessageId: record.budgetMessageId,
        budgetMessageId: record.budgetMessageId,
        codecVersion: record.codecVersion,
        interpretationJson: record.interpretationJson,
        draftJson: draft.toJson(),
      );

  List<ChangeOp> _answered(
    String id,
    LocalDate date, {
    required bool confirmed,
  }) {
    final json = DayIncompleteDraft.toJson(date);
    return [
      CreateProposal(
        id,
        ProposalRowDraft(
          kind: dayIncompleteKind,
          codecVersion: adaptiveDraftCodecVersion,
          draftJson: json,
        ),
      ),
      ResolveProposal(
        id,
        expectedBudgetMessageId: null,
        to: confirmed ? ProposalStatus.confirmed : ProposalStatus.discarded,
        outcome: confirmed
            ? ProposalOutcome.unchanged
            : ProposalOutcome.discarded,
        codecVersion: adaptiveDraftCodecVersion,
        interpretationJson: null,
        draftJson: json,
      ),
    ];
  }

  Future<List<IntakeDay>> _intake(LocalDate from, LocalDate to) async {
    final (totals, marks, answers) = await (
      diary.watchDailyTotals(from, to).first,
      diary.watchDayMarks(from, to).first,
      proposals.byKind(dayIncompleteKind),
    ).wait;
    return intakeDaysOf(
      totals: totals,
      marks: marks,
      confirmed: confirmedDatesOf(answers),
    );
  }

  /// The trend on [today], else [current]'s basis weight (A13 D8).
  static double _weight(
    WeightTrend trend,
    LocalDate today,
    TargetSettingsRecord current,
  ) {
    final kg = trend.trendOn(today);
    return kg != null && TargetRules.input.weight(kg)
        ? kg
        : current.basisWeightKg;
  }

  /// The version in effect on [today] with its row version, or null.
  static Versioned<TargetSettingsRecord>? _current(
    TargetsData data,
    LocalDate today,
  ) {
    final current = TargetsTimeline.versionOn([
      for (final s in data.settings) s.value,
    ], today);
    if (current == null) return null;
    return data.settings.where((s) => s.value.id == current.id).firstOrNull;
  }

  Future<AdaptiveOutcome> _command(
    String label,
    Future<_Plan> Function(LocalDate today) build,
  ) async {
    if (_busy) return const AdaptivePending();
    _busy = true;
    try {
      final today = EntryTime.now(clock).localDate;
      final _Plan plan;
      try {
        plan = await build(today);
      }
      // A failed read: nothing was written.
      on Object {
        return const AdaptiveFailed(AdaptiveFailure.unavailable);
      }
      if (plan case _Refuse(:final reason)) return AdaptiveFailed(reason);
      final write = plan as _Write;
      final ApplyResult result;
      try {
        result = await apply(ChangeSet(write.ops, origin: write.origin));
      } on ChangeRejected catch (rejection) {
        return AdaptiveFailed(_failure(rejection.failure));
      }
      // The single writer rolled back: nothing was written.
      on Object {
        return const AdaptiveFailed(AdaptiveFailure.unavailable);
      }
      if (result is Rejected) return AdaptiveFailed(_failure(result.failure));
      final applied = result as Applied;
      return AdaptiveDone(undoStack.record(applied, UndoLabel(label)).id);
    } finally {
      _busy = false;
    }
  }

  static AdaptiveFailure _failure(ChangeFailure failure) => switch (failure) {
    VersionConflict() ||
    InvalidOp(
      code: 'targetsChanged' || 'settingChanged',
    ) => AdaptiveFailure.stale,
    _ => AdaptiveFailure.invalid,
  };
}

sealed class _Plan {
  const new();
}

final class _Refuse extends _Plan {
  const new(this.reason);

  final AdaptiveFailure reason;
}

final class _Write extends _Plan {
  const new(this.ops, {required this.origin});

  final List<ChangeOp> ops;
  final Origin origin;
}

/// Session-owned: the check-in runs outside any screen.
@Riverpod(keepAlive: true)
AdaptiveActions adaptiveActions(Ref ref) => AdaptiveActions(
  apply: ref.watch(changeSetApplierProvider).apply,
  undoStack: ref.watch(undoStackProvider),
  ids: ref.watch(idGeneratorProvider),
  clock: ref.watch(clockProvider),
  readTargets: ref.watch(targetsRepositoryProvider).read,
  diary: ref.watch(diaryRepositoryProvider),
  proposals: ref.watch(proposalRepositoryProvider),
  readWeighIns: ref.watch(weighInsReaderProvider),
  settings: ref.watch(settingsStoreProvider),
);

/// Runs this week's check-in while Progress shows (A38 D4), again when the
/// day changes (a new week may have started). Local only; the result is
/// informational.
@riverpod
Future<CheckInRun> weeklyCheckIn(Ref ref) async {
  await ref.watch(todayProvider.future);
  return await ref.read(adaptiveActionsProvider).runWeeklyCheckIn();
}
