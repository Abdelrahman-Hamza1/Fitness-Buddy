import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptHandler;
import '../../../core/db/support/db_support.dart';

/// The commands' "today": Saturday 2026-10-17 (UTC clock, offset 0), the
/// default week start.
final LocalDate today = LocalDate(2026, 10, 17);

/// A male, born 1990 (36 on [today]), 180 cm, moderate. At 80 kg: resting
/// 1,750 kcal (the floor), expenditure 2,712.5 kcal.
SetupInput setupInput({
  FormulaSex sex = FormulaSex.male,
  int birthYear = 1990,
  Length? height,
  HeightInputUnit heightUnit = HeightInputUnit.centimeter,
  double weight = 80,
  MassUnit weightUnit = MassUnit.kilogram,
  ActivityLevel activity = ActivityLevel.moderate,
  GoalInput? goal,
  String? goalName,
  SetupPreferences preferences = defaultPreferences,
}) => SetupInput(
  sex: sex,
  birthYear: birthYear,
  height: height ?? Length.centimeters(180),
  heightInputUnit: heightUnit,
  weightValue: weight,
  weightUnit: weightUnit,
  activity: activity,
  goal: goal ?? loseHalf,
  goalName: goalName,
  preferences: preferences,
);

/// The stored defaults: no setting row is written for them.
const SetupPreferences defaultPreferences = SetupPreferences(
  unitSystem: UnitSystem.metric,
  weekStart: DayOfWeek.saturday,
  halal: true,
);

/// Lose 0.5 kg a week: 550 kcal a day below expenditure.
final GoalInput loseHalf = GoalInput(
  type: GoalType.lose,
  expression: GoalExpression.weekly(-.5),
);

/// The generated base of [setupInput] defaults: 2,712.5 − 550.
const double setupBase = 2162.5;

/// A database with the real applier and the settings, targets and diary
/// handlers, a manual clock at [today] 12:00 UTC, an undo stack, and
/// [TargetsActions] whose trend weight is [trend] (null: the basis weight).
final class TargetsAppHarness {
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
        const ScriptHandler(),
      ],
      clock: clock,
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
    undo = UndoStack(revert: applier.revert, clock: clock);
    actions = TargetsActions(
      apply: (changes) => (applyHook ?? applier.apply)(changes),
      undoStack: undo,
      ids: ids,
      clock: clock,
      read: TargetsRepository(db).read,
      settings: SettingsStore(db: db, applier: applier),
      bodyWeightKg: (_) async => trend,
    );
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  final ManualClock clock = ManualClock(DateTime.utc(2026, 10, 17, 12));
  final SequenceIdGenerator ids = SequenceIdGenerator();
  late final ChangeSetApplier<AppDatabase> applier;
  late final UndoStack undo;
  late final TargetsActions actions;

  /// The trend weight the commands see (A14's, once wired); null falls back
  /// to the basis weight.
  double? trend;

  /// Replaces the single writer (race and rejection tests).
  Future<ApplyResult> Function(ChangeSet)? applyHook;

  /// Applies [ops] directly (outside the commands).
  Future<Applied> apply(List<ChangeOp> ops) async {
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  /// Completes setup with [input] (defaults: [setupInput]).
  Future<TargetsDone> setUp([SetupInput? input]) async {
    final outcome = await actions.completeSetup(input ?? setupInput());
    if (outcome is! TargetsDone) fail('setup failed: $outcome');
    return outcome;
  }

  /// The clock's local date (moves with [ManualClock.advance]).
  LocalDate get date => EntryTime.now(clock).localDate;

  /// Moves the clock [days] days on.
  void advanceDays(int days) => clock.advance(Duration(days: days));

  /// The stored targets now.
  Future<TargetsData> data() => TargetsRepository(db).read();

  /// The version in effect on [date], as a screen would show it.
  Future<VersionedId> shownVersion() async {
    final d = await data();
    final current = TargetsTimeline.versionOn([
      for (final s in d.settings) s.value,
    ], date)!;
    final row = d.settings.singleWhere((s) => s.value.id == current.id);
    return VersionedId(current.id, row.version);
  }

  /// The version in effect on [date].
  Future<TargetSettingsRecord> currentVersion() async =>
      TargetsTimeline.versionOn([
        for (final s in (await data()).settings) s.value,
      ], date)!;

  /// The live phases.
  Future<List<Versioned<GoalPhaseRecord>>> phases() async =>
      (await data()).phases;

  /// Every row of every synced table, the outbox and sync state (a
  /// "nothing written" comparison).
  Future<String> raw() async {
    final tables = [
      ...db.syncedTables.map((t) => t.sqlName),
      'sync_outbox',
      'sync_state',
    ];
    return jsonEncode({
      for (final table in tables)
        table: [
          for (final r
              in await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
            r.data,
        ],
    });
  }

  /// The A01 D3 comparison: live content rows of every synced table.
  Future<String> state() async {
    const stamped = {
      'created_at',
      'updated_hlc',
      'version',
      'device_id',
      'origin',
    };
    return jsonEncode({
      for (final table in db.syncedTables.map((t) => t.sqlName))
        table: [
          for (final r
              in await db
                  .customSelect(
                    'SELECT * FROM $table WHERE deleted_at IS NULL ORDER BY id',
                  )
                  .get())
            {
              for (final e in r.data.entries)
                if (!stamped.contains(e.key)) e.key: e.value,
            },
        ],
    });
  }

  /// Runs [command] and expects a [T] outcome with nothing written.
  Future<T> expectNoWrite<T extends TargetsOutcome>(
    Future<TargetsOutcome> Function() command,
  ) async {
    final before = await raw();
    final latest = undo.latest;
    final outcome = await command();
    expect(outcome, isA<T>());
    expect(await raw(), before, reason: 'the command wrote something');
    expect(undo.latest, latest, reason: 'the command recorded an undo');
    return outcome as T;
  }

  /// A container over this database whose [bodyWeightProvider] returns
  /// [trend].
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        changeSetApplierProvider.overrideWithValue(applier),
        bodyWeightProvider.overrideWith((ref, date) async => trend),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }
}
