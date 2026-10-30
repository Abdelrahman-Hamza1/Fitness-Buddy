import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/target_tables.dart';
import 'package:fb_mobile/features/targets/data/target_mappers.dart';

/// Turns [TargetsOp]s into profile, goal phase and target settings writes
/// (A13 D4, TD-089), in the applier's transaction. Every rejection throws
/// [ChangeRejected] before any write, with codes only (no body values):
///
/// 1. `TargetRules.wire` always → `InvalidOp('invalid')`;
/// 2. `TargetRules.input` on the fields that differ from the stored row,
///    or for a new settings version from the version it supersedes (a
///    synced outlier never blocks an unrelated edit) → `InvalidOp('invalid')`;
/// 3. a newly acknowledged manual value (SF-012) unless the change set's
///    origin is direct → `InvalidOp('acknowledgement')`;
/// 4. timelines: the write is refused only when it adds a conflict pair
///    (`phaseOverlap` / `duplicateDate`); conflicts that arrived by sync
///    never block (PA2).
///
/// Row ops (PA9): phases and versions are created with [InsertRow] (a
/// duplicate ID fails); the profile is [UpsertRow]ed only when absent or a
/// tombstone (a live row → [VersionConflict] with expected 0); every
/// revision is an [UpdateRow] at the expected version. Undo inverses come
/// from the applier. Emits [TargetsChanged], also on undo.
final class TargetsOpHandler extends ChangeOpHandler<TargetsOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// The profile's database.
  final AppDatabase db;

  @override
  String get family => TargetsOp.familyName;

  @override
  Future<OpPlan> plan(TargetsOp op, TxReader tx, ApplyContext context) async {
    final rows = switch (op) {
      PutProfile() => await _profile(op, tx, context.today),
      PutGoalPhase() => await _goalPhase(op, tx, context.today),
      PutTargetSettings() => await _settings(op, tx, context.origin),
      ExpectCurrentSettings() => await _expectCurrent(op, tx, context.today),
    };
    if (rows.isEmpty) return OpPlan(const []);
    final changed = [
      TargetsChanged({op.part}),
    ];
    return OpPlan(rows, events: changed, revertEvents: changed);
  }

  /// A38 review 1: the version in effect [today], read in the transaction.
  Future<List<RowOp>> _expectCurrent(
    ExpectCurrentSettings op,
    TxReader tx,
    LocalDate today,
  ) async {
    final current = TargetsTimeline.versionOn([
      for (final row in await _live(tx, db.targetSettingsRows))
        ?targetSettingsOf(row),
    ], today);
    if (current == null ||
        current.id != op.versionId ||
        current.revision != op.revision ||
        (op.generatedOnly && current.manual)) {
      throw const ChangeRejected(InvalidOp('targetsChanged'));
    }
    return const [];
  }

  Future<List<RowOp>> _profile(
    PutProfile op,
    TxReader tx,
    LocalDate today,
  ) async {
    final record = op.record;
    _checkWire(TargetRules.wire.profile(record.toWire()));
    final row = await tx.row(db.profiles, profileRowId);
    final live = row != null && row.deletedAt == null ? row : null;
    final expected = op.expectedVersion;
    if (expected == null) {
      if (live != null) _conflict(profileEntity, profileRowId, 0, live.version);
      _checkInput(TargetRules.input.profile(record, today: today));
      return [UpsertRow(db.profiles, profileColumns(record))];
    }
    _checkVersion(profileEntity, profileRowId, live?.version, expected);
    final before = profileOf(live!);
    if (before == record) return const [];
    _checkInput(
      TargetRules.input.profile(record, today: today, before: before),
    );
    return [
      UpdateRow(
        db.profiles,
        profileRowId,
        profileColumns(record).copyWith(id: const Value.absent()),
        expectedVersion: expected,
      ),
    ];
  }

  Future<List<RowOp>> _goalPhase(
    PutGoalPhase op,
    TxReader tx,
    LocalDate today,
  ) async {
    final record = op.record;
    _checkWire(TargetRules.wire.goalPhase(record.toWire()));
    final expected = op.expectedVersion;
    GoalPhaseRecord? before;
    if (expected != null) {
      final live = await tx.liveRow(db.goalPhases, record.id);
      _checkVersion(goalPhaseEntity, record.id, live?.version, expected);
      before = goalPhaseOf(live!);
      if (before == record) return const [];
    }
    _checkInput(
      TargetRules.input.goalPhase(record, today: today, before: before),
    );
    final others = [
      for (final row in await _live(tx, db.goalPhases))
        if (row.id != record.id) ?goalPhaseOf(row)?.toPhase(),
    ];
    final added = GoalHistory.conflicts([...others, record.toPhase()])
        .difference(GoalHistory.conflicts([...others, ?before?.toPhase()]));
    if (added.isNotEmpty) {
      throw const ChangeRejected(InvalidOp('phaseOverlap'));
    }
    final columns = goalPhaseColumns(record);
    return [
      if (expected == null)
        InsertRow(db.goalPhases, columns)
      else
        UpdateRow(
          db.goalPhases,
          record.id,
          columns.copyWith(id: const Value.absent()),
          expectedVersion: expected,
        ),
    ];
  }

  Future<List<RowOp>> _settings(
    PutTargetSettings op,
    TxReader tx,
    Origin origin,
  ) async {
    final record = op.record;
    _checkWire(TargetRules.wire.targetSettings(record.toWire()));
    final expected = op.expectedVersion;
    TargetSettingsRecord? before;
    if (expected != null) {
      final live = await tx.liveRow(db.targetSettingsRows, record.id);
      _checkVersion(targetSettingsEntity, record.id, live?.version, expected);
      before = targetSettingsOf(live!);
      if (before == record) return const [];
    }
    final others = [
      for (final row in await _live(tx, db.targetSettingsRows))
        if (row.id != record.id) ?targetSettingsOf(row),
    ];
    // PA6: a new version is compared with the one it supersedes (in effect
    // the day before it starts), whose fields the D5 revision rule copied;
    // only a first version is checked in full.
    final supersedes =
        before ??
        TargetsTimeline.versionOn(others, record.effectiveFrom.plusDays(-1));
    _checkInput(TargetRules.input.targetSettings(record, before: supersedes));
    // SF-012: only the user, directly, acknowledges a below-floor value; a
    // proposal (A38) can carry an existing acknowledgement but never add one.
    final keepsAcknowledgement =
        supersedes != null &&
        supersedes.manual &&
        supersedes.acknowledged &&
        supersedes.baseKcal == record.baseKcal;
    if (record.acknowledged &&
        !keepsAcknowledgement &&
        origin is! OriginDirect) {
      throw const ChangeRejected(InvalidOp('acknowledgement'));
    }
    final keys = [for (final other in others) other.key];
    final added = TargetSettingsHistory.conflicts([...keys, record.key])
        .difference(TargetSettingsHistory.conflicts([...keys, ?before?.key]));
    if (added.isNotEmpty) {
      throw const ChangeRejected(InvalidOp('duplicateDate'));
    }
    final columns = targetSettingsColumns(record);
    return [
      if (expected == null)
        InsertRow(db.targetSettingsRows, columns)
      else
        UpdateRow(
          db.targetSettingsRows,
          record.id,
          columns.copyWith(id: const Value.absent()),
          expectedVersion: expected,
        ),
    ];
  }

  /// The live rows of [table] in the transaction (earlier ops included).
  Future<List<D>> _live<T extends Table, D>(
    TxReader tx,
    TableInfo<T, D> table,
  ) =>
      (tx.db.select(table)..where(
            (_) => (table.columnsByName['deleted_at']! as GeneratedColumn<int>)
                .isNull(),
          ))
          .get();

  /// Rejects a missing live row ([actual] null) or one not at [expected].
  static void _checkVersion(
    String entity,
    String id,
    int? actual,
    int expected,
  ) {
    if (actual == null) {
      throw ChangeRejected(RowNotFound(entity: entity, id: id));
    }
    if (actual != expected) _conflict(entity, id, expected, actual);
  }

  static Never _conflict(String entity, String id, int expected, int actual) =>
      throw ChangeRejected(
        VersionConflict(
          entity: entity,
          id: id,
          expected: expected,
          actual: actual,
        ),
      );

  static void _checkWire(Set<TargetRuleViolation> violations) {
    if (violations.isNotEmpty) {
      throw const ChangeRejected(InvalidOp('invalid'));
    }
  }

  static void _checkInput(Set<TargetRuleViolation> violations) =>
      _checkWire(violations);
}
