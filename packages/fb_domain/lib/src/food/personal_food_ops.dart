import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/food/personal_food.dart';

/// Personal-food writes and source guards (A09 D4/D19).
sealed class PersonalFoodOp implements ChangeOp {
  const new _();

  /// Stable handler family.
  static const familyName = 'personalFood';
  @override
  String get family => familyName;
  @override
  String toString() => 'PersonalFoodOp';
}

/// Creates one food. The handler validates the draft in the transaction.
final class CreatePersonalFood extends PersonalFoodOp {
  /// New row identity and content.
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  /// New row ID.
  final String id;

  /// Private content.
  final PersonalFoodDraft draft;
  @override
  bool operator ==(Object other) =>
      other is CreatePersonalFood && other.id == id && other.draft == draft;
  @override
  int get hashCode => Object.hash(CreatePersonalFood, id, draft);
}

/// Full definition replacement; identical drafts write nothing.
final class UpdatePersonalFood extends PersonalFoodOp {
  /// The shown version and the edited definition.
  new(this.id, this.expectedVersion, this.draft) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion);
  }

  /// Row ID.
  final String id;

  /// Observed version.
  final int expectedVersion;

  /// Private content.
  final PersonalFoodDraft draft;
  @override
  bool operator ==(Object other) =>
      other is UpdatePersonalFood &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.draft == draft;
  @override
  int get hashCode =>
      Object.hash(UpdatePersonalFood, id, expectedVersion, draft);
}

/// Tombstones only the definition, retaining history snapshots.
final class DeletePersonalFood extends PersonalFoodOp {
  /// The shown food.
  const new(this.food) : super._();

  /// Observed identity and version.
  final VersionedId food;
  @override
  bool operator ==(Object other) =>
      other is DeletePersonalFood && other.food == food;
  @override
  int get hashCode => Object.hash(DeletePersonalFood, food);
}

/// Merges metadata and tombstones the duplicate; pair with RelinkFoodRefs.
final class MergePersonalFoods extends PersonalFoodOp {
  /// Both versions are checked before either write.
  const new({required this.survivor, required this.merged}) : super._();

  /// Food to keep.
  final VersionedId survivor;

  /// Duplicate to remove.
  final VersionedId merged;
  @override
  bool operator ==(Object other) =>
      other is MergePersonalFoods &&
      other.survivor == survivor &&
      other.merged == merged;
  @override
  int get hashCode => Object.hash(MergePersonalFoods, survivor, merged);
}

/// No writes: rejects a food that changed since it was shown.
final class RequirePersonalFood extends PersonalFoodOp {
  /// Observed food.
  const new(this.food) : super._();

  /// Expected identity/version.
  final VersionedId food;
  @override
  bool operator ==(Object other) =>
      other is RequirePersonalFood && other.food == food;
  @override
  int get hashCode => Object.hash(RequirePersonalFood, food);
}
