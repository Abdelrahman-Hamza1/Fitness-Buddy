import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/diary/meal_slot_rules.dart';

/// Meal editor commands; diagnostic strings never contain meal names.
sealed class MealSlotOp implements ChangeOp {
  const new();

  /// Stable handler family.
  static const String familyName = 'mealSlot';
  @override
  String get family => familyName;
}

/// Add a custom meal with a caller-generated identity, to the normal set
/// or (A41a, DY-012 "customizable separately") the Ramadan set.
final class AddMealSlot extends MealSlotOp {
  /// Names are normalized before validation.
  new(this.id, String name, {this.window, this.mode = SlotMode.normal})
    : name = MealSlotRules.normalizeName(name) {
    checkUuid(id, 'id');
    if (!MealSlotRules.validName(this.name)) throw ArgumentError('nameInvalid');
  }

  /// New identity.
  final String id;

  /// Private display name.
  final String name;

  /// Optional assignment window.
  final TimeWindow? window;

  /// The set the meal joins.
  final SlotMode mode;
  @override
  bool operator ==(Object other) =>
      other is AddMealSlot &&
      id == other.id &&
      name == other.name &&
      window == other.window &&
      mode == other.mode;
  @override
  int get hashCode => Object.hash(id, name, window, mode);
  @override
  String toString() => 'AddMealSlot($id)';
}

/// Explicit set/clear fields distinguish clearing from leaving unchanged.
final class MealSlotPatch {
  /// At least one field must be requested. Null name/window means clear.
  new({String? name, this.setName = false, this.window, this.setWindow = false})
    : name = name == null ? null : MealSlotRules.normalizeName(name) {
    if (!setName && !setWindow) throw ArgumentError('emptyPatch');
    if (!setName && name != null || !setWindow && window != null) {
      throw ArgumentError('unsetField');
    }
    if (this.name != null &&
        this.name!.isNotEmpty &&
        !MealSlotRules.validName(this.name!)) {
      throw ArgumentError('nameInvalid');
    }
  }

  /// Name requested, including reset.
  final bool setName;

  /// Private name, or reset.
  final String? name;

  /// Window requested, including clear.
  final bool setWindow;

  /// Window, or clear.
  final TimeWindow? window;
  @override
  bool operator ==(Object other) =>
      other is MealSlotPatch &&
      name == other.name &&
      setName == other.setName &&
      window == other.window &&
      setWindow == other.setWindow;
  @override
  int get hashCode => Object.hash(name, setName, window, setWindow);
  @override
  String toString() => 'MealSlotPatch';
}

/// Edit the exact rendered slot version.
final class UpdateMealSlot extends MealSlotOp {
  /// Identity, observed version and requested fields.
  new(this.id, this.expectedVersion, this.patch) {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion);
  }

  /// Slot identity.
  final String id;

  /// Rendered version.
  final int expectedVersion;

  /// Requested changes.
  final MealSlotPatch patch;
  @override
  bool operator ==(Object other) =>
      other is UpdateMealSlot &&
      id == other.id &&
      expectedVersion == other.expectedVersion &&
      patch == other.patch;
  @override
  int get hashCode => Object.hash(id, expectedVersion, patch);
  @override
  String toString() => 'UpdateMealSlot($id@$expectedVersion)';
}

/// Full observed active set of one mode, in the requested order.
final class ReorderMealSlots extends MealSlotOp {
  /// Nonempty, distinct versioned identities.
  new(Iterable<VersionedId> order) : order = List.unmodifiable(order) {
    _unique(this.order);
    if (this.order.isEmpty) throw ArgumentError('emptyOrder');
  }

  /// Immutable order.
  final List<VersionedId> order;
  @override
  bool operator ==(Object other) =>
      other is ReorderMealSlots && _equal(order, other.order);
  @override
  int get hashCode => Object.hashAll(order);
  @override
  String toString() => 'ReorderMealSlots(${order.length})';
}

/// All live rows shown by the removal sheet; dates support its day count.
final class SlotContents {
  /// Membership and versions, immutable and distinct per table.
  new({
    Iterable<VersionedId> entries = const [],
    Iterable<VersionedId> groups = const [],
    Iterable<String> dates = const [],
  }) : entries = List.unmodifiable(entries),
       groups = List.unmodifiable(groups),
       dates = Set.unmodifiable(dates) {
    _unique(this.entries);
    _unique(this.groups);
  }

  /// No observed rows.
  static final SlotContents empty = SlotContents();

  /// Observed entry identities.
  final List<VersionedId> entries;

  /// Observed group identities, including empty groups.
  final List<VersionedId> groups;

  /// Distinct stored diary dates.
  final Set<String> dates;

  /// Whether no rows need moving.
  bool get isEmpty => entries.isEmpty && groups.isEmpty;
  @override
  bool operator ==(Object other) =>
      other is SlotContents &&
      _equal(entries, other.entries) &&
      _equal(groups, other.groups) &&
      dates.length == other.dates.length &&
      dates.containsAll(other.dates);
  @override
  int get hashCode => Object.hash(
    Object.hashAll(entries),
    Object.hashAll(groups),
    Object.hashAllUnordered(dates),
  );
  @override
  String toString() =>
      'SlotContents(${entries.length} entries, ${groups.length} groups, '
      '${dates.length} days)';
}

/// Deactivate and optionally move the exact observed contents atomically.
final class RemoveMealSlot extends MealSlotOp {
  /// Source and destination both carry the versions actually rendered.
  new(this.id, this.expectedVersion, {required this.expected, this.moveTo}) {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion);
  }

  /// Source identity.
  final String id;

  /// Source version.
  final int expectedVersion;

  /// Exact shown contents.
  final SlotContents expected;

  /// Destination as shown, if any.
  final VersionedId? moveTo;
  @override
  bool operator ==(Object other) =>
      other is RemoveMealSlot &&
      id == other.id &&
      expectedVersion == other.expectedVersion &&
      expected == other.expected &&
      moveTo == other.moveTo;
  @override
  int get hashCode => Object.hash(id, expectedVersion, expected, moveTo);
  @override
  String toString() => 'RemoveMealSlot($id, $expected)';
}

void _unique(List<VersionedId> ids) {
  if (ids.map((v) => v.id).toSet().length != ids.length) {
    throw ArgumentError('duplicateId');
  }
}

bool _equal<T>(List<T> a, List<T> b) =>
    a.length == b.length && a.indexed.every((pair) => pair.$2 == b[pair.$1]);
