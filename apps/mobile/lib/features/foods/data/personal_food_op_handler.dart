import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/food_tables.dart';
import 'package:fb_mobile/features/foods/data/personal_food_mappers.dart';
import 'package:fb_text/fb_text.dart';

/// Plans only food-table rows, within the applier's transaction (A09 D4).
final class PersonalFoodOpHandler extends ChangeOpHandler<PersonalFoodOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// Profile database.
  final AppDatabase db;
  @override
  String get family => PersonalFoodOp.familyName;
  @override
  Future<OpPlan> plan(
    PersonalFoodOp op,
    TxReader tx,
    ApplyContext context,
  ) async {
    final wanted = switch (op) {
      CreatePersonalFood() => <VersionedId>[],
      UpdatePersonalFood(:final id, :final expectedVersion) => [
        VersionedId(id, expectedVersion),
      ],
      DeletePersonalFood(:final food) ||
      RequirePersonalFood(:final food) => [food],
      MergePersonalFoods(:final survivor, :final merged) => [survivor, merged],
    };
    if (op is MergePersonalFoods && op.survivor.id == op.merged.id) {
      throw const ChangeRejected(InvalidOp('sameFood'));
    }
    final rows = wanted.isEmpty
        ? <PersonalFoodRow>[]
        : await (tx.db.select(db.personalFoods)..where(
                (t) =>
                    t.id.isIn(wanted.map((v) => v.id)) & t.deletedAt.isNull(),
              ))
              .get();
    final byId = {for (final row in rows) row.id: row};
    for (final v in wanted) {
      final row = byId[v.id];
      if (row == null) {
        throw ChangeRejected(RowNotFound(entity: personalFoodEntity, id: v.id));
      }
      if (row.version != v.expectedVersion) {
        throw ChangeRejected(
          VersionConflict(
            entity: personalFoodEntity,
            id: v.id,
            expected: v.expectedVersion,
            actual: row.version,
          ),
        );
      }
    }
    PersonalFood food(String id) {
      try {
        return personalFoodOf(byId[id]!);
      } on PersonalFoodMappingError {
        throw const ChangeRejected(InvalidOp('invalidDraft'));
      }
    }

    PersonalFoodsCompanion columns(
      PersonalFoodDraft draft, {
      PersonalFoodRow? previous,
      bool newValues = true,
    }) {
      if ((newValues ? draft.validate() : draft.validateWire()) != null) {
        throw const ChangeRejected(InvalidOp('invalidDraft'));
      }
      try {
        return personalFoodColumns(draft, previous: previous);
      } on PersonalFoodMappingError {
        throw const ChangeRejected(InvalidOp('invalidDraft'));
      }
    }

    return switch (op) {
      CreatePersonalFood(:final id, :final draft) => OpPlan([
        InsertRow(db.personalFoods, columns(draft).copyWith(id: Value(id))),
      ]),
      RequirePersonalFood() => OpPlan(const []),
      DeletePersonalFood(:final food) => OpPlan([
        TombstoneRow(
          db.personalFoods,
          food.id,
          expectedVersion: food.expectedVersion,
        ),
      ]),
      UpdatePersonalFood(:final id, :final expectedVersion, :final draft) =>
        food(id).draft == draft
            ? OpPlan(const [])
            : OpPlan([
                UpdateRow(
                  db.personalFoods,
                  id,
                  columns(
                    draft,
                    previous: byId[id],
                    newValues:
                        draft.per100 != food(id).per100 ||
                        draft.basis != food(id).basis,
                  ),
                  expectedVersion: expectedVersion,
                ),
              ]),
      MergePersonalFoods() => _merge(
        op,
        food(op.survivor.id),
        food(op.merged.id),
        (draft) =>
            columns(draft, previous: byId[op.survivor.id], newValues: false),
      ),
    };
  }

  OpPlan _merge(
    MergePersonalFoods op,
    PersonalFood a,
    PersonalFood b,
    PersonalFoodsCompanion Function(PersonalFoodDraft) columns,
  ) {
    if (a.draft.basis != b.draft.basis) {
      throw const ChangeRejected(InvalidOp('basisMismatch'));
    }
    final merged = PersonalFoodMerge.combine(a, b, keyOf: normalizeKey);
    if (merged is! PersonalFoodDraft) {
      throw const ChangeRejected(InvalidOp('tooMany'));
    }
    return OpPlan([
      UpdateRow(
        db.personalFoods,
        a.id,
        columns(merged),
        expectedVersion: op.survivor.expectedVersion,
      ),
      TombstoneRow(
        db.personalFoods,
        b.id,
        expectedVersion: op.merged.expectedVersion,
      ),
    ]);
  }
}
