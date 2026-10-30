import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/body_tables.dart';
import 'package:fb_mobile/features/body/data/measurement_mappers.dart';

/// Turns `MeasurementOp`s into `measurements` / `measurement_types` row
/// writes, inside the applier's transaction (A15b D15). No custom events:
/// `ChangeSetApplied(entities: {'measurement', 'measurementType'})` tells
/// subscribers.
///
/// Rejections: `RowNotFound` / `VersionConflict` for a row that is gone or
/// changed; `InvalidOp('invalidDraft')` for a draft or name outside the
/// local-write rules, `('time')` before 1970, `('future')` more than 5
/// minutes after the apply time, `('unknownType')` for a custom type that
/// is missing, deleted or unreadable, `('duplicateName')` for a name
/// another live type has (ignoring case), `('typeChanged')` for an update
/// that moves an entry to another type, `('sourceChanged')` when a type's
/// measurements differ from the ones a `DeleteMeasurementType` lists.
///
/// **Revert guards (PA1):** undo bypasses the forward checks, so every op
/// adds read-only guards that look at the state **after** the inverse: a
/// type creation can't be undone while a live measurement still uses it
/// (`typeInUse`), a restored custom measurement needs its type live
/// (`unknownType`), and a restored type name must stay unique
/// (`duplicateName`).
final class MeasurementOpHandler extends ChangeOpHandler<MeasurementOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// The profile database.
  final AppDatabase db;

  @override
  String get family => MeasurementOp.familyName;

  @override
  Future<OpPlan> plan(
    MeasurementOp op,
    TxReader tx,
    ApplyContext context,
  ) async => switch (op) {
    CreateMeasurement(:final id, :final draft) => OpPlan([
      InsertRow(
        db.measurements,
        (await _columns(draft, tx, context)).copyWith(id: Value(id)),
      ),
    ]),
    UpdateMeasurement() => await _update(op, tx, context),
    DeleteMeasurement(:final measurement) => OpPlan(
      [
        TombstoneRow(
          db.measurements,
          measurement.id,
          expectedVersion: measurement.expectedVersion,
        ),
      ],
      revertGuards: [_typesLiveAfter],
    ),
    CreateMeasurementType(:final id, :final name) => await _createType(
      id,
      name,
      tx,
    ),
    RenameMeasurementType() => await _renameType(op, tx),
    DeleteMeasurementType() => await _deleteType(op, tx),
  };

  Future<OpPlan> _update(
    UpdateMeasurement op,
    TxReader tx,
    ApplyContext context,
  ) async {
    final row = await tx.liveRow(db.measurements, op.id);
    if (row == null) {
      throw ChangeRejected(RowNotFound(entity: measurementEntity, id: op.id));
    }
    if (row.version != op.expectedVersion) {
      throw ChangeRejected(
        VersionConflict(
          entity: measurementEntity,
          id: op.id,
          expected: op.expectedVersion,
          actual: row.version,
        ),
      );
    }
    if (row.kind != op.draft.type.kind.code ||
        row.customTypeId != op.draft.type.customTypeId) {
      _reject('typeChanged');
    }
    if (_draftOf(row) == op.draft) return OpPlan(const []);
    return OpPlan(
      [
        UpdateRow(
          db.measurements,
          op.id,
          await _columns(op.draft, tx, context),
          expectedVersion: op.expectedVersion,
        ),
      ],
      revertGuards: [_typesLiveAfter],
    );
  }

  Future<OpPlan> _createType(String id, String name, TxReader tx) async {
    _checkName(name);
    if (_hasName(await _liveTypes(tx.db), name)) _reject('duplicateName');
    return OpPlan(
      [
        InsertRow(
          db.measurementTypes,
          measurementTypeColumns(name).copyWith(id: Value(id)),
        ),
      ],
      revertGuards: [_typeNotInUse(id)],
    );
  }

  Future<OpPlan> _renameType(RenameMeasurementType op, TxReader tx) async {
    final row = await _liveType(tx, VersionedId(op.id, op.expectedVersion));
    _checkName(op.name);
    if (row.name == op.name) return OpPlan(const []);
    final others = [
      for (final type in await _liveTypes(tx.db))
        if (type.id != op.id) type,
    ];
    if (_hasName(others, op.name)) _reject('duplicateName');
    return OpPlan(
      [
        UpdateRow(
          db.measurementTypes,
          op.id,
          measurementTypeColumns(op.name),
          expectedVersion: op.expectedVersion,
        ),
      ],
      revertGuards: [_namesUniqueAfter],
    );
  }

  Future<OpPlan> _deleteType(DeleteMeasurementType op, TxReader tx) async {
    await _liveType(tx, op.type);
    final rows =
        await (tx.db.select(db.measurements)..where(
              (t) => t.customTypeId.equals(op.type.id) & t.deletedAt.isNull(),
            ))
            .get();
    // Exactly the rows the user saw (readable ones), at the versions shown;
    // every live row of the type is tombstoned with it.
    final shown = {
      for (final row in rows)
        if (_draftOf(row) != null) VersionedId(row.id, row.version),
    };
    if (shown.length != op.measurements.length ||
        !shown.containsAll(op.measurements)) {
      _reject('sourceChanged');
    }
    return OpPlan(
      [
        for (final row in rows)
          TombstoneRow(db.measurements, row.id, expectedVersion: row.version),
        TombstoneRow(
          db.measurementTypes,
          op.type.id,
          expectedVersion: op.type.expectedVersion,
        ),
      ],
      revertGuards: [_namesUniqueAfter, _typesLiveAfter],
    );
  }

  /// [draft]'s columns, or a rejection for a draft a local write can't
  /// save (including a custom type that isn't live).
  Future<MeasurementsCompanion> _columns(
    MeasurementDraft draft,
    TxReader tx,
    ApplyContext context,
  ) async {
    switch (draft.validate()) {
      case null:
        break;
      case MeasurementIssue.time:
        _reject('time');
      case _:
        _reject('invalidDraft');
    }
    if (draft.isInFuture(context.nowUtc)) _reject('future');
    if (draft.type.customTypeId case final typeId?) {
      // Live and readable: a synced type the lists hide (a blank name)
      // would hide the new entry too (A15b review m2).
      final type = await tx.liveRow(db.measurementTypes, typeId);
      if (type == null || !_readableType(type)) _reject('unknownType');
    }
    return measurementColumns(draft);
  }

  Future<MeasurementTypeRow> _liveType(TxReader tx, VersionedId type) async {
    final row = await tx.liveRow(db.measurementTypes, type.id);
    if (row == null) {
      throw ChangeRejected(
        RowNotFound(entity: measurementTypeEntity, id: type.id),
      );
    }
    if (row.version != type.expectedVersion) {
      throw ChangeRejected(
        VersionConflict(
          entity: measurementTypeEntity,
          id: type.id,
          expected: type.expectedVersion,
          actual: row.version,
        ),
      );
    }
    return row;
  }

  Future<List<MeasurementTypeRow>> _liveTypes(DatabaseConnectionUser q) =>
      (q.select(db.measurementTypes)..where((t) => t.deletedAt.isNull())).get();

  static bool _readableType(MeasurementTypeRow row) {
    try {
      measurementTypeOf(row);
      return true;
    } on MeasurementMappingError {
      return false;
    }
  }

  static void _checkName(String name) {
    if (CustomTypeName.validate(name) != null) _reject('invalidDraft');
  }

  static bool _hasName(Iterable<MeasurementTypeRow> types, String name) =>
      types.any((type) => CustomTypeName.same(type.name, name));

  /// The stored content as a draft, or `null` for a row the domain can't
  /// read (any edit then counts as a change).
  static MeasurementDraft? _draftOf(MeasurementRow row) {
    try {
      return measurementOf(row).draft;
    } on MeasurementMappingError {
      return null;
    }
  }

  // Revert guards: each looks at the state after the inverse, i.e. the live
  // rows now, minus the ones the inverse tombstones or restores to
  // something else, plus the ones it restores live.

  /// Refuses undoing type [id]'s creation while a live measurement would
  /// still point at it afterwards.
  RevertGuard _typeNotInUse(String id) => (q, inverse) async {
    final live = await _liveAfter(
      q,
      inverse,
      'measurements',
      where: 'custom_type_id = ?',
      variables: [Variable.withString(id)],
    );
    if (live.values.any((row) => row['custom_type_id'] == id)) {
      _reject('typeInUse');
    }
  };

  /// Refuses an undo that restores a live custom measurement whose type
  /// won't be live afterwards.
  static Future<void> _typesLiveAfter(
    DatabaseConnectionUser q,
    List<RowOp> inverse,
  ) async {
    final needed = {
      for (final op in inverse)
        if (op is RestoreRow &&
            op.table.actualTableName == 'measurements' &&
            op.snapshot['deleted_at'] == null &&
            op.snapshot['custom_type_id'] != null)
          op.snapshot['custom_type_id']! as String,
    };
    if (needed.isEmpty) return;
    final types = await _liveAfter(q, inverse, 'measurement_types');
    if (!types.keys.toSet().containsAll(needed)) _reject('unknownType');
  }

  /// Refuses an undo that restores a live type whose name another live
  /// type has afterwards (trimmed, ignoring case).
  static Future<void> _namesUniqueAfter(
    DatabaseConnectionUser q,
    List<RowOp> inverse,
  ) async {
    final restored = {
      for (final op in inverse)
        if (op is RestoreRow &&
            op.table.actualTableName == 'measurement_types' &&
            op.snapshot['deleted_at'] == null)
          op.id,
    };
    if (restored.isEmpty) return;
    final types = await _liveAfter(q, inverse, 'measurement_types');
    for (final id in restored) {
      final name = types[id]?['name'];
      if (name is! String) continue;
      final clash = types.entries.any(
        (e) =>
            e.key != id &&
            e.value['name'] is String &&
            CustomTypeName.same(e.value['name']! as String, name),
      );
      if (clash) _reject('duplicateName');
    }
  }

  /// The live rows of [table] (matching [where]) once [inverse] is applied,
  /// by ID: the live rows now, minus the ones [inverse] tombstones or
  /// restores to a tombstone, plus (or replaced by) the ones it restores
  /// live.
  static Future<Map<String, Map<String, Object?>>> _liveAfter(
    DatabaseConnectionUser q,
    List<RowOp> inverse,
    String table, {
    String? where,
    List<Variable> variables = const [],
  }) async {
    final rows = await q
        .customSelect(
          'SELECT * FROM $table WHERE deleted_at IS NULL'
          '${where == null ? '' : ' AND $where'}',
          variables: variables,
        )
        .get();
    final live = {for (final r in rows) r.read<String>('id'): r.data};
    for (final op in inverse) {
      if (op.table.actualTableName != table) continue;
      if (op is TombstoneRow) {
        live.remove(op.id);
      } else if (op is RestoreRow) {
        if (op.snapshot['deleted_at'] == null) {
          live[op.id] = op.snapshot;
        } else {
          live.remove(op.id);
        }
      }
    }
    return live;
  }
}

Never _reject(String code) => throw ChangeRejected(InvalidOp(code));
