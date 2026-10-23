import 'package:fb_domain/src/diary/food_ref.dart';
import 'package:fb_domain/src/diary/provenance.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// The display name snapshot of a logged food (A06 D4): English, plus
/// Arabic when the food has it. User or catalog content: never logged.
final class FoodNames {
  /// [en] (not blank) and an optional [ar] (not blank when present). Throws
  /// an `ArgumentError` otherwise, without the text.
  new(this.en, {this.ar}) {
    checkNotBlank(en, 'en');
    if (ar case final ar?) checkNotBlank(ar, 'ar');
  }

  /// The English name.
  final String en;

  /// The Arabic name, when there is one.
  final String? ar;

  @override
  bool operator ==(Object other) =>
      other is FoodNames && other.en == en && other.ar == ar;

  @override
  int get hashCode => Object.hash(en, ar);

  /// Without the names.
  @override
  String toString() => 'FoodNames(${ar == null ? 'en' : 'en, ar'})';
}

/// What an entry was logged from, as one unit (A06 D4): the reference, the
/// names, the per-100 values and the provenance. A food change on an entry
/// replaces all four together.
final class EntryFood {
  /// [ref] with [names], [per100] values (per 100 g or ml, see the amount's
  /// basis) and [provenance].
  const new({
    required this.ref,
    required this.names,
    required this.per100,
    required this.provenance,
    this.editedByUser = false,
  });

  /// Whether this chosen snapshot carries a user nutrient override (AI-072).
  final bool editedByUser;

  /// Which food it came from.
  final FoodRef ref;

  /// The names at log time.
  final FoodNames names;

  /// The per-100 values at log time, so amount edits recompute the
  /// snapshot without the food (FD-073).
  final Nutrients per100;

  /// The source badge and estimate details.
  final Provenance provenance;

  @override
  bool operator ==(Object other) =>
      other is EntryFood &&
      other.ref == ref &&
      other.names == names &&
      other.per100 == per100 &&
      other.provenance == provenance &&
      other.editedByUser == editedByUser;

  @override
  int get hashCode => Object.hash(ref, names, per100, provenance, editedByUser);

  /// Without the names, values or assumptions.
  @override
  String toString() => 'EntryFood($ref, ${provenance.source.code})';
}

/// How much was logged (A06 D4): the input as typed, and the canonical
/// amount in grams or millilitres that the snapshot is computed from.
final class EntryAmount {
  /// [input] as typed, resolved to [amount] (finite, not negative) on
  /// [basis]. Throws an `ArgumentError` otherwise.
  new({required this.input, required this.amount, required this.basis}) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be finite and >= 0');
    }
  }

  /// The amount as the user typed it (`input_amount`, `input_unit`).
  final Quantity input;

  /// The canonical amount (`amount`), in grams or ml (see [basis]).
  final double amount;

  /// Whether [amount] is grams or ml (`amount_basis`), also the basis of the
  /// food's per-100 values.
  final NutrientBasis basis;

  @override
  bool operator ==(Object other) =>
      other is EntryAmount &&
      other.input == input &&
      other.amount == amount &&
      other.basis == basis;

  @override
  int get hashCode => Object.hash(input, amount, basis);

  @override
  String toString() => 'EntryAmount(${basis.unitCode})';
}

/// A logged diary entry as read from storage (DY-001/002, A06 D4–D6).
///
/// The entry carries its own names, per-100 values and nutrient snapshot,
/// so nothing outside it can change a logged value (FD-073).
final class DiaryEntry {
  /// The entry [id] at [version]. IDs are lowercase canonical UUIDs and
  /// [version] is ≥ 1. Throws an `ArgumentError` otherwise.
  new({
    required this.id,
    required this.version,
    required this.time,
    required this.localDate,
    required this.slotId,
    required this.food,
    required this.amount,
    required this.snapshot,
    this.dishGroupId,
    this.editedByUser = false,
  }) {
    checkUuid(id, 'id');
    checkRowVersion(version);
    checkUuid(slotId, 'slotId');
    if (dishGroupId case final group?) checkUuid(group, 'dishGroupId');
  }

  /// The entry's ID.
  final String id;

  /// The row version (optimistic concurrency).
  final int version;

  /// When it was eaten, with the offset stored at log time (DY-002).
  final EntryTime time;

  /// The diary day (`local_date`). The ops keep it equal to
  /// `time.localDate` (A06 D6).
  final LocalDate localDate;

  /// The meal slot.
  final String slotId;

  /// The dish group it belongs to, if any. A group and its entries share
  /// the date and the slot (A06 D1).
  final String? dishGroupId;

  /// What was logged.
  final EntryFood food;

  /// How much was logged.
  final EntryAmount amount;

  /// The entry's nutrients at storage precision (the snapshot).
  final Nutrients snapshot;

  /// Whether the user overrode the values (shown as ⓨ, AI-072). Food
  /// replacement takes the chosen snapshot flag; amount edits and copies
  /// retain it.
  final bool editedByUser;

  @override
  bool operator ==(Object other) =>
      other is DiaryEntry &&
      other.id == id &&
      other.version == version &&
      other.time == time &&
      other.localDate == localDate &&
      other.slotId == slotId &&
      other.dishGroupId == dishGroupId &&
      other.food == food &&
      other.amount == amount &&
      other.snapshot == snapshot &&
      other.editedByUser == editedByUser;

  @override
  int get hashCode => Object.hash(
    id,
    version,
    time,
    localDate,
    slotId,
    dishGroupId,
    food,
    amount,
    snapshot,
    editedByUser,
  );

  /// IDs, date and slot only: no names or values.
  @override
  String toString() =>
      'DiaryEntry($id, v$version, $localDate, slot $slotId'
      '${dishGroupId == null ? '' : ', group $dishGroupId'})';
}

/// A dish group (DY-024): entries logged together as one dish, sharing its
/// date and slot (A06 D1).
final class DishGroup {
  /// The group [id] at [version] named [name] (not blank) on [localDate] in
  /// [slotId]. Throws an `ArgumentError` otherwise.
  new({
    required this.id,
    required this.version,
    required this.name,
    required this.localDate,
    required this.slotId,
  }) {
    checkUuid(id, 'id');
    checkRowVersion(version);
    checkNotBlank(name, 'name');
    checkUuid(slotId, 'slotId');
  }

  /// The group's ID.
  final String id;

  /// The row version.
  final int version;

  /// The dish name. User content: never logged.
  final String name;

  /// The diary day.
  final LocalDate localDate;

  /// The meal slot.
  final String slotId;

  @override
  bool operator ==(Object other) =>
      other is DishGroup &&
      other.id == id &&
      other.version == version &&
      other.name == name &&
      other.localDate == localDate &&
      other.slotId == slotId;

  @override
  int get hashCode => Object.hash(id, version, name, localDate, slotId);

  /// Without the name.
  @override
  String toString() => 'DishGroup($id, v$version, $localDate, slot $slotId)';
}

/// The user's marks on a day (DY-004): incomplete, and (A41) not fasting.
final class DayMark {
  /// The marks of [localDate].
  const new({
    required this.localDate,
    required this.incomplete,
    this.notFasting = false,
  });

  /// The day.
  final LocalDate localDate;

  /// Whether the day is marked incomplete (excluded from adaptive targets).
  final bool incomplete;

  /// Whether the user marked a Ramadan day as not fasting (A41).
  final bool notFasting;

  @override
  bool operator ==(Object other) =>
      other is DayMark &&
      other.localDate == localDate &&
      other.incomplete == incomplete &&
      other.notFasting == notFasting;

  @override
  int get hashCode => Object.hash(localDate, incomplete, notFasting);

  @override
  String toString() =>
      'DayMark($localDate, incomplete: $incomplete, notFasting: $notFasting)';
}

/// [id] if it is a lowercase canonical UUID, else an `ArgumentError`.
String checkUuid(String id, String name) {
  if (!isUuid(id)) {
    throw ArgumentError.value(id, name, 'must be a lowercase canonical UUID');
  }
  return id;
}

/// [version] if it is a row version (≥ 1), else an `ArgumentError`.
int checkRowVersion(int version, [String name = 'version']) {
  if (version < 1) throw ArgumentError.value(version, name, 'must be >= 1');
  return version;
}

/// [text] if it is not blank, else an `ArgumentError` that names [name]
/// but not the text (it is user content).
String checkNotBlank(String text, String name) {
  if (text.trim().isEmpty) throw ArgumentError('$name must not be blank');
  return text;
}
