import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/db/support/db_support.dart';
import '../diary/support/diary_fixtures.dart';

/// Monday 9 November 2026 (UTC, offset 0); weeks start on Saturday, so
/// this week's check-in is the week of 7 November and its window is
/// 10 October – 6 November.
final LocalDate _today = LocalDate(2026, 11, 9);
final LocalDate _weekStart = LocalDate(2026, 11, 7);
final LocalDate _windowStart = LocalDate(2026, 10, 10);

/// Male, born 1990, 180 cm, sedentary.
const ProfileRecord _profile = ProfileRecord(
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  heightInputUnit: HeightInputUnit.centimeter,
  activity: ActivityLevel.sedentary,
);

final class _Harness {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [
        SettingsOpHandler(db.settingsKv),
        TargetsOpHandler(db),
        WeighInOpHandler(db),
        DiaryOpHandler(db),
        ProposalOpHandler(db),
      ],
      clock: clock,
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
    undo = UndoStack(revert: applier.revert, clock: clock);
    settings = SettingsStore(db: db, applier: applier);
    actions = AdaptiveActions(
      apply: (set) => (hook ?? applier.apply)(set),
      undoStack: undo,
      ids: ids,
      clock: clock,
      readTargets: TargetsRepository(db).read,
      diary: DiaryRepository(db),
      proposals: ProposalRepository(db),
      readWeighIns: () => WeighInRepository(db).readLive(),
      settings: settings,
    );
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  final ManualClock clock = ManualClock(DateTime.utc(2026, 11, 9, 12));
  final SequenceIdGenerator ids = SequenceIdGenerator();
  late final ChangeSetApplier<AppDatabase> applier;
  late final UndoStack undo;
  late final SettingsStore settings;
  late final AdaptiveActions actions;
  var _entry = 0;

  /// Replaces the single writer for the actions (interleaving tests).
  Future<ApplyResult> Function(ChangeSet)? hook;

  final String versionId = '0199e3c2-5b1a-7000-8000-00000000a001';

  Future<Applied> apply(List<ChangeOp> ops) async {
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  /// A generated 2,600 kcal target since 1 September (maintain: no goal).
  Future<void> targets({double base = 2600, bool manual = false}) => apply([
    PutProfile(_profile),
    PutTargetSettings(
      TargetSettingsRecord(
        id: versionId,
        revision: 1,
        effectiveFrom: LocalDate(2026, 9, 1),
        baseKcal: base,
        basisWeightKg: 80,
        manual: manual,
      ),
    ),
  ]);

  /// [days] days of 2,000 kcal in two meals ending 6 November, and daily
  /// weigh-ins losing 500/7,700 kg a day (a true expenditure of 2,500).
  Future<void> history({int days = 28, bool weigh = true}) async {
    final from = _windowStart.plusDays(28 - days);
    await insertEntries(db, [
      for (var d = 0; d < days; d++)
        for (final slot in ['breakfast', 'dinner'])
          entryRow(
            ++_entry,
            date: '${from.plusDays(d)}',
            slotId: slot,
            kcal: 1000,
          ),
    ]);
    if (!weigh) return;
    await apply([
      for (var d = 0; d < days; d++)
        CreateWeighIn(
          ids.next(),
          WeighInDraft(
            time: EntryTime.local(LocalDateTime(from.plusDays(d), hour: 7), 0),
            input: WeighInInput(
              ((80 - 500 / 7700 * (d + 28 - days)) * 10).roundToDouble() / 10,
              MassUnit.kilogram,
            ),
          ),
        ),
    ]);
  }

  Future<TargetsData> data() => TargetsRepository(db).read();

  Future<TargetSettingsRecord> current() async => TargetsTimeline.versionOn([
    for (final s in (await data()).settings) s.value,
  ], _today)!;

  Future<List<ProposalRecord>> rows(String kind) =>
      ProposalRepository(db).byKind(kind);

  Future<ProposalRecord> checkIn() async =>
      (await rows(targetChangeKind)).single;

  TargetChangeDraft draftOf(ProposalRecord r) =>
      TargetChangeDraft.tryParse(r.draftJson)!;

  ProviderContainer container({LocalDate? today}) {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        changeSetApplierProvider.overrideWithValue(applier),
        clockProvider.overrideWithValue(clock),
        idGeneratorProvider.overrideWithValue(ids),
        todayProvider.overrideWith((ref) => Stream.value(today ?? _today)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }
}

void main() {
  test("TG-034 TG-035 AI-056 the week's check-in proposes a capped change "
      'once, as a pending targetChange row; targets are untouched', () async {
    final h = _Harness();
    await h.targets();
    await h.history();
    expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
    final row = await h.checkIn();
    expect(row.isPending, isTrue);
    expect(row.budgetMessageId, isNull);
    final draft = h.draftOf(row);
    expect(draft.weekStart, _weekStart);
    expect(draft.versionId, h.versionId);
    expect(draft.fromKcal, 2600);
    // The estimate (~2,450–2,500) is under 2,600: down, by at most 150.
    expect(draft.toKcal, lessThan(2600));
    expect(2600 - draft.toKcal, lessThanOrEqualTo(150));
    expect(draft.toKcal % 10, 0);
    expect(draft.expenditureKcal, inInclusiveRange(2350, 2550));
    expect(draft.confidence, ExpenditureConfidence.high);
    expect(draft.automatic, isFalse);
    expect((await h.current()).baseKcal, 2600);
    // Idempotent for the week.
    expect(await h.actions.runWeeklyCheckIn(), CheckInRun.none);
    expect(await h.rows(targetChangeKind), hasLength(1));
  });

  test("TG-034 accept revises today's version through the applier and "
      'resolves the row in one change set; Undo restores both', () async {
    final h = _Harness();
    await h.targets();
    await h.history();
    await h.actions.runWeeklyCheckIn();
    final row = await h.checkIn();
    final draft = h.draftOf(row);
    final outcome = await h.actions.accept(row.id);
    expect(outcome, isA<AdaptiveDone>());
    final now = await h.current();
    expect(now.baseKcal, draft.toKcal);
    expect(now.effectiveFrom, _today);
    expect(now.manual, isFalse);
    final resolved = await h.checkIn();
    expect(resolved.status, ProposalStatus.confirmed);
    expect(resolved.outcome, ProposalOutcome.unchanged);
    expect(h.draftOf(resolved).appliedVersionId, now.id);
    // Me › Targets reads "Adjusted to your results" for it.
    final c = h.container()..listen(targetsViewProvider, (_, _) {});
    expect((await c.read(targetsViewProvider.future))!.adapted, isTrue);
    expect(
      await h.undo.undo((outcome as AdaptiveDone).undoEntryId),
      UndoOutcome.undone,
    );
    expect((await h.current()).baseKcal, 2600);
    expect((await h.checkIn()).isPending, isTrue);
    await pumpEventQueue();
    expect((await c.read(targetsViewProvider.future))!.adapted, isFalse);
  });

  test('TG-034 TG-035 SF-010 an adjusted accept stays within ±150 of the '
      'base and above the floor', () async {
    final h = _Harness();
    await h.targets();
    await h.history();
    await h.actions.runWeeklyCheckIn();
    final row = await h.checkIn();
    for (final kcal in [2300.0, 2800.0, 1500.0]) {
      expect(
        await h.actions.accept(row.id, kcal: kcal),
        isA<AdaptiveFailed>().having(
          (f) => f.reason,
          'reason',
          AdaptiveFailure.outOfRange,
        ),
        reason: '$kcal',
      );
    }
    expect(await h.actions.accept(row.id, kcal: 2550), isA<AdaptiveDone>());
    expect((await h.current()).baseKcal, 2550);
    final resolved = await h.checkIn();
    expect(resolved.outcome, ProposalOutcome.adjusted);
    expect(h.draftOf(resolved).toKcal, 2550);
  });

  test('TG-034 keep discards the proposal, with Undo; a resolved one '
      "can't be answered again", () async {
    final h = _Harness();
    await h.targets();
    await h.history();
    await h.actions.runWeeklyCheckIn();
    final row = await h.checkIn();
    final kept = await h.actions.keep(row.id);
    expect(kept, isA<AdaptiveDone>());
    expect((await h.checkIn()).status, ProposalStatus.discarded);
    expect((await h.current()).baseKcal, 2600);
    expect(
      await h.actions.accept(row.id),
      isA<AdaptiveFailed>().having(
        (f) => f.reason,
        'reason',
        AdaptiveFailure.invalid,
      ),
    );
    await h.undo.undo((kept as AdaptiveDone).undoEntryId);
    expect((await h.checkIn()).isPending, isTrue);
  });

  test('a check-in made against targets the user changed since is stale: '
      'nothing is written', () async {
    final h = _Harness();
    await h.targets();
    await h.history();
    await h.actions.runWeeklyCheckIn();
    final row = await h.checkIn();
    final data = await h.data();
    final stored = data.settings.single;
    await h.apply([
      PutTargetSettings(
        stored.value.copyWith(revision: 2, baseKcal: 2500),
        expectedVersion: stored.version,
      ),
    ]);
    expect(
      await h.actions.accept(row.id),
      isA<AdaptiveFailed>().having(
        (f) => f.reason,
        'reason',
        AdaptiveFailure.stale,
      ),
    );
    expect((await h.current()).baseKcal, 2500);
    expect((await h.checkIn()).isPending, isTrue);
    final c = h.container()..listen(checkInCardProvider, (_, _) {});
    final card = await c.read(checkInCardProvider.future);
    expect(card!.kind, CheckInCardKind.stale);
  });

  test('TG-034 automatic: applied through the applier (no prompt), shown '
      'with Change back, which restores the target with Undo', () async {
    final h = _Harness();
    await h.targets();
    await h.history();
    await h.settings.put(
      AppSettings.checkInMode,
      CheckInMode.automatic,
      origin: Origin.direct,
    );
    expect(await h.actions.runWeeklyCheckIn(), CheckInRun.applied);
    final row = await h.checkIn();
    final draft = h.draftOf(row);
    expect(row.status, ProposalStatus.confirmed);
    expect(draft.automatic, isTrue);
    expect((await h.current()).baseKcal, draft.toKcal);
    expect(h.undo.latest, isNull, reason: 'not a direct action');

    final c = h.container()..listen(appliedCheckInCardProvider, (_, _) {});
    expect(
      (await c.read(appliedCheckInCardProvider.future))!.kind,
      CheckInCardKind.applied,
    );

    final back = await h.actions.changeBack(row.id);
    expect(back, isA<AdaptiveDone>());
    final restored = await h.current();
    expect(restored.baseKcal, 2600);
    expect(restored.manual, isFalse);
    expect(h.draftOf(await h.checkIn()).seen, isTrue);
    expect(
      await h.actions.changeBack(row.id),
      isA<AdaptiveFailed>().having(
        (f) => f.reason,
        'reason',
        AdaptiveFailure.stale,
      ),
    );
    await h.undo.undo((back as AdaptiveDone).undoEntryId);
    expect((await h.current()).baseKcal, draft.toKcal);
  });

  test('TG-034 automatic never changes a target the user set themselves: '
      'it is proposed instead', () async {
    final h = _Harness();
    await h.targets(manual: true);
    await h.history();
    await h.settings.put(
      AppSettings.checkInMode,
      CheckInMode.automatic,
      origin: Origin.direct,
    );
    expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
    expect((await h.checkIn()).isPending, isTrue);
    expect((await h.current()).baseKcal, 2600);
  });

  test('TG-031 no check-in before enough data, before setup, or in a week '
      'whose targets the user already changed', () async {
    final h = _Harness();
    expect(await h.actions.runWeeklyCheckIn(), CheckInRun.none);
    await h.targets();
    await h.history(days: 12);
    expect(await h.actions.runWeeklyCheckIn(), CheckInRun.none);
    expect(await h.rows(targetChangeKind), isEmpty);

    final fresh = _Harness();
    await fresh.targets();
    await fresh.history();
    final stored = (await fresh.data()).settings.single;
    await fresh.apply([
      PutTargetSettings(
        stored.value.copyWith(
          id: '0199e3c2-5b1a-7000-8000-00000000a002',
          revision: 1,
          effectiveFrom: _weekStart,
          baseKcal: 2580,
        ),
      ),
    ]);
    expect(await fresh.actions.runWeeklyCheckIn(), CheckInRun.none);
  });

  test(
    "a new week's check-in discards the last week's unanswered one",
    () async {
      final h = _Harness();
      await h.targets();
      await h.history();
      await h.actions.runWeeklyCheckIn();
      final first = await h.checkIn();
      h.clock.advance(const Duration(days: 7));
      // Keep the data current for the new window.
      await insertEntries(h.db, [
        for (var d = 0; d < 7; d++)
          for (final slot in ['breakfast', 'dinner'])
            entryRow(
              900 + d * 2 + (slot == 'dinner' ? 1 : 0),
              date: '${_weekStart.plusDays(d)}',
              slotId: slot,
              kcal: 1000,
            ),
      ]);
      expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
      final all = await h.rows(targetChangeKind);
      expect(all, hasLength(2));
      expect(
        all.singleWhere((r) => r.id == first.id).status,
        ProposalStatus.discarded,
      );
      expect(all.where((r) => r.isPending), hasLength(1));
    },
  );

  group('DY-004 incomplete-day suggestion', () {
    Future<_Harness> withLightDay() async {
      final h = _Harness();
      await h.targets();
      await h.history();
      // 5 November: one 600 kcal entry, in one meal (< 50 % of 2,600).
      await runAuthorizedWrite(() async {
        await h.db.customStatement(
          'UPDATE diary_entries SET deleted_at = 9 WHERE '
          "local_date = '2026-11-05' AND slot_id = 'dinner'",
        );
        await h.db.customStatement(
          'UPDATE diary_entries SET kcal = 600 WHERE '
          "local_date = '2026-11-05'",
        );
      });
      return h;
    }

    test('suggested only on the rule; Mark incomplete writes the mark and '
        'the answer in one change set, with Undo', () async {
      final h = await withLightDay();
      final c = h.container()
        ..listen(incompleteDaySuggestionProvider, (_, _) {});
      final suggestion = await c.read(incompleteDaySuggestionProvider.future);
      expect(suggestion!.date, LocalDate(2026, 11, 5));
      expect(suggestion.mealCount, 1);
      expect(suggestion.kcal, 600);

      final done = await h.actions.markIncomplete(suggestion.date);
      expect(done, isA<AdaptiveDone>());
      final marks = await DiaryRepository(h.db)
          .watchDayMarks(suggestion.date, suggestion.date)
          .first;
      expect(marks.single.incomplete, isTrue);
      final answer = (await h.rows(dayIncompleteKind)).single;
      expect(answer.status, ProposalStatus.confirmed);
      expect(DayIncompleteDraft.dateOf(answer.draftJson), suggestion.date);
      await pumpEventQueue();
      expect(await c.read(incompleteDaySuggestionProvider.future), isNull);

      await h.undo.undo((done as AdaptiveDone).undoEntryId);
      expect(await h.rows(dayIncompleteKind), isEmpty);
      final after = await DiaryRepository(h.db)
          .watchDayMarks(suggestion.date, suggestion.date)
          .first;
      expect(after.where((m) => m.incomplete), isEmpty);
    });

    test('"It was complete" keeps the day counting and the suggestion '
        'away; never today, never automatic', () async {
      final h = await withLightDay();
      final day = LocalDate(2026, 11, 5);
      expect(
        await h.actions.confirmComplete(_today),
        isA<AdaptiveFailed>(),
        reason: 'only past days',
      );
      expect(await h.actions.confirmComplete(day), isA<AdaptiveDone>());
      final answer = (await h.rows(dayIncompleteKind)).single;
      expect(answer.status, ProposalStatus.discarded);
      final c = h.container()
        ..listen(incompleteDaySuggestionProvider, (_, _) {});
      expect(await c.read(incompleteDaySuggestionProvider.future), isNull);
      // The estimate counts the day as complete now.
      final days = intakeDaysOf(
        totals: await DiaryRepository(h.db).watchDailyTotals(day, day).first,
        marks: const [],
        confirmed: confirmedDatesOf([answer]),
      );
      expect(days.single.confirmed, isTrue);
      // Nothing was marked.
      final marks = await DiaryRepository(h.db).watchDayMarks(day, day).first;
      expect(marks, isEmpty);
    });

    test('a day with two meals, or a normal day, is never suggested', () async {
      final h = _Harness();
      await h.targets();
      await h.history();
      await runAuthorizedWrite(
        () => h.db.customStatement(
          'UPDATE diary_entries SET kcal = 300 WHERE '
          "local_date = '2026-11-05'",
        ),
      );
      final c = h.container()
        ..listen(incompleteDaySuggestionProvider, (_, _) {});
      expect(await c.read(incompleteDaySuggestionProvider.future), isNull);
    });
  });

  test('IN-005 TG-031 the expenditure view: readiness before enough data, '
      'then weekly points with confidence', () async {
    final h = _Harness();
    await h.targets();
    await h.history(days: 12);
    final c = h.container()..listen(expenditureViewProvider, (_, _) {});
    final early = (await c.read(expenditureViewProvider.future))!;
    expect(early.latest, isNull);
    expect(early.readiness.isReady, isFalse);
    expect(early.readiness.daysToLog, greaterThan(0));
    expect(early.mode, CheckInMode.ask);

    final ready = _Harness();
    await ready.targets();
    await ready.history();
    final c2 = ready.container()..listen(expenditureViewProvider, (_, _) {});
    final view = (await c2.read(expenditureViewProvider.future))!;
    expect(view.latest, isNotNull);
    expect(view.points, isNotEmpty);
    expect(view.points.last, same(view.latest));
    expect(view.latest!.kcal, inInclusiveRange(2300, 2600));
  });

  group('review round 1', () {
    Future<_Harness> automatic() async {
      final h = _Harness();
      await h.targets();
      await h.history();
      await h.settings.put(
        AppSettings.checkInMode,
        CheckInMode.automatic,
        origin: Origin.direct,
      );
      return h;
    }

    test('1 a manual target that arrives by sync between the estimate and '
        'the automatic change is never overridden', () async {
      final h = await automatic();
      const synced = '0199e3c2-5b1a-7000-8000-00000000a0ff';
      h.hook = (set) async {
        if (set.ops.any((op) => op is PutTargetSettings)) {
          // Sync lands first: the user's own target from yesterday.
          final stored = (await h.data()).settings.single.value;
          await h.applier.apply(
            ChangeSet([
              PutTargetSettings(
                stored.copyWith(
                  id: synced,
                  revision: 1,
                  effectiveFrom: _today.plusDays(-1),
                  baseKcal: 2300,
                  manual: true,
                ),
              ),
            ], origin: Origin.system),
          );
        }
        return await h.applier.apply(set);
      };
      expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
      final now = await h.current();
      expect(now.id, synced);
      expect(now.baseKcal, 2300);
      expect((await h.checkIn()).isPending, isTrue);
    });

    test('1 the automatic setting turned off meanwhile: proposed, not '
        'applied', () async {
      final h = await automatic();
      h.hook = (set) async {
        if (set.ops.any((op) => op is PutTargetSettings)) {
          await h.settings.put(
            AppSettings.checkInMode,
            CheckInMode.ask,
            origin: Origin.direct,
          );
        }
        return await h.applier.apply(set);
      };
      expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
      expect((await h.current()).baseKcal, 2600);
    });

    test("2 a malformed persisted draft can't move the target: its baseline "
        "must be today's base, its kind and codec supported", () async {
      final h = _Harness();
      await h.targets();
      Future<String> row(String kind, int codec, TargetChangeDraft d) async {
        final id = h.ids.next();
        await h.applier.apply(
          ChangeSet([
            CreateProposal(
              id,
              ProposalRowDraft(
                kind: kind,
                codecVersion: codec,
                draftJson: d.toJson(),
              ),
            ),
          ], origin: Origin.system),
        );
        return id;
      }

      final forged = TargetChangeDraft(
        weekStart: _weekStart,
        versionId: h.versionId,
        versionRevision: 1,
        fromKcal: 5000,
        toKcal: 4850,
        recommendedKcal: 4000,
        expenditureKcal: 4000,
        confidence: ExpenditureConfidence.high,
      );
      expect(
        await h.actions.accept(await row(targetChangeKind, 1, forged)),
        isA<AdaptiveFailed>().having(
          (f) => f.reason,
          'reason',
          AdaptiveFailure.stale,
        ),
      );
      final honest = forged.copyWith(toKcal: 2500);
      final valid = TargetChangeDraft.tryParse(
        honest.toJson().replaceFirst('"fromKcal":5000.0', '"fromKcal":2600.0'),
      )!;
      expect(
        await h.actions.accept(
          await row(targetChangeKind, 1, valid),
          kcal: 2900,
        ),
        isA<AdaptiveFailed>().having(
          (f) => f.reason,
          'reason',
          AdaptiveFailure.outOfRange,
        ),
      );
      for (final (kind, codec) in [('other', 1), (targetChangeKind, 2)]) {
        expect(
          await h.actions.accept(await row(kind, codec, valid)),
          isA<AdaptiveFailed>().having(
            (f) => f.reason,
            'reason',
            AdaptiveFailure.invalid,
          ),
        );
      }
      expect((await h.current()).baseKcal, 2600);
    });

    test('5 an unseen automatic change keeps Change back after the week '
        'ends and a restart, until OK', () async {
      final h = await automatic();
      await h.actions.runWeeklyCheckIn();
      h.clock.advance(const Duration(days: 9));
      final c = h.container(today: _today.plusDays(9))
        ..listen(appliedCheckInCardProvider, (_, _) {});
      final card = await c.read(appliedCheckInCardProvider.future);
      expect(card!.kind, CheckInCardKind.applied);
      await h.actions.dismissNote(card.record.id);
      final c2 = h.container(today: _today.plusDays(9))
        ..listen(appliedCheckInCardProvider, (_, _) {});
      expect(await c2.read(appliedCheckInCardProvider.future), isNull);
    });

    test('6 Change back and the note follow the applied version, not the '
        'calories', () async {
      final h = await automatic();
      await h.actions.runWeeklyCheckIn();
      final row = await h.checkIn();
      // Another revision with the same calories (rebalancing off).
      final stored = (await h.data()).settings.singleWhere(
        (s) => s.value.effectiveFrom == _today,
      );
      await h.apply([
        PutTargetSettings(
          stored.value.copyWith(
            revision: stored.value.revision + 1,
            rebalancing: false,
          ),
          expectedVersion: stored.version,
        ),
      ]);
      expect(
        await h.actions.changeBack(row.id),
        isA<AdaptiveFailed>().having(
          (f) => f.reason,
          'reason',
          AdaptiveFailure.stale,
        ),
      );
      final c = h.container()..listen(appliedCheckInCardProvider, (_, _) {});
      expect(await c.read(appliedCheckInCardProvider.future), isNull);
    });

    test('7 the check-in provider reruns when invalidated (Progress opens) '
        'and stays once a week', () async {
      final h = _Harness();
      await h.targets();
      final c = h.container()..listen(weeklyCheckInProvider, (_, _) {});
      expect(await c.read(weeklyCheckInProvider.future), CheckInRun.none);
      await h.history();
      c.invalidate(weeklyCheckInProvider);
      expect(await c.read(weeklyCheckInProvider.future), CheckInRun.proposed);
      c.invalidate(weeklyCheckInProvider);
      expect(await c.read(weeklyCheckInProvider.future), CheckInRun.none);
      expect(await h.rows(targetChangeKind), hasLength(1));
    });
  });

  group('review round 2', () {
    Future<_Harness> automatic() async {
      final h = _Harness();
      await h.targets();
      await h.history();
      await h.settings.put(
        AppSettings.checkInMode,
        CheckInMode.automatic,
        origin: Origin.direct,
      );
      return h;
    }

    test('an unresolved anomaly day holds the automatic change: proposed, '
        'the card says why; "They\'re right" confirms the day', () async {
      final h = await automatic();
      final day = LocalDate(2026, 10, 30);
      await runAuthorizedWrite(
        () => h.db.customStatement(
          'UPDATE diary_entries SET kcal = 19000 WHERE '
          "local_date = '2026-10-30' AND slot_id = 'dinner'",
        ),
      );
      expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
      final row = await h.checkIn();
      final draft = h.draftOf(row);
      expect(row.isPending, isTrue);
      expect(draft.hold, CheckInHold.anomaly);
      expect(draft.anomalyDates, [day]);
      expect(draft.confidence, isNot(ExpenditureConfidence.high));
      expect((await h.current()).baseKcal, 2600);

      final done = await h.actions.confirmDays(draft.anomalyDates);
      expect(done, isA<AdaptiveDone>());
      final answers = await h.rows(dayIncompleteKind);
      expect(confirmedDatesOf(answers), {day});
      final c = h.container()..listen(expenditureViewProvider, (_, _) {});
      final view = (await c.read(expenditureViewProvider.future))!;
      expect(view.latest!.anomalyDates, isEmpty);
    });

    test('low confidence holds the automatic change too', () async {
      final h = _Harness();
      await h.targets();
      await h.history(weigh: false);
      await h.apply([
        for (final (i, d) in [17, 22, 27].indexed)
          CreateWeighIn(
            h.ids.next(),
            WeighInDraft(
              time: EntryTime.local(
                LocalDateTime(_windowStart.plusDays(d), hour: 7),
                0,
              ),
              input: WeighInInput(80 - i * .3, MassUnit.kilogram),
            ),
          ),
      ]);
      await h.settings.put(
        AppSettings.checkInMode,
        CheckInMode.automatic,
        origin: Origin.direct,
      );
      expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
      final draft = h.draftOf(await h.checkIn());
      expect(draft.confidence, ExpenditureConfidence.low);
      expect(draft.hold, CheckInHold.lowConfidence);
    });

    test('5 a newer pending proposal never hides the unseen automatic '
        'change: both cards show', () async {
      final h = await automatic();
      expect(await h.actions.runWeeklyCheckIn(), CheckInRun.applied);
      await h.settings.put(
        AppSettings.checkInMode,
        CheckInMode.ask,
        origin: Origin.direct,
      );
      h.clock.advance(const Duration(days: 7));
      await insertEntries(h.db, [
        for (var d = 0; d < 7; d++)
          for (final slot in ['breakfast', 'dinner'])
            entryRow(
              700 + d * 2 + (slot == 'dinner' ? 1 : 0),
              date: '${_weekStart.plusDays(d)}',
              slotId: slot,
              kcal: 1000,
            ),
      ]);
      expect(await h.actions.runWeeklyCheckIn(), CheckInRun.proposed);
      final c = h.container(today: _today.plusDays(7))
        ..listen(checkInCardProvider, (_, _) {})
        ..listen(appliedCheckInCardProvider, (_, _) {});
      expect(
        (await c.read(checkInCardProvider.future))!.kind,
        CheckInCardKind.pending,
      );
      expect(
        (await c.read(appliedCheckInCardProvider.future))!.kind,
        CheckInCardKind.applied,
      );
    });
  });
}
