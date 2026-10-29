import 'package:fb_domain/src/body/weigh_in.dart';
import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// The op family of weigh-ins (A14 D5). The app's `WeighInOpHandler` turns
/// each op into row writes, validates drafts inside the transaction and
/// rejects future or pre-1970 times. `toString` never shows a value or a
/// note.
sealed class WeighInOp implements ChangeOp {
  const new _();

  /// The [family] of every weigh-in op.
  static const String familyName = 'weighIn';

  @override
  String get family => familyName;
}

/// Log a weigh-in (WB-001). The [id] is assigned when the op is built, so a
/// recomputed proposal keeps it and a second confirm fails as a duplicate.
final class CreateWeighIn extends WeighInOp {
  /// The new row [id] with [draft]. Throws an `ArgumentError` for an
  /// invalid ID.
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  /// The new row's ID.
  final String id;

  /// What is saved.
  final WeighInDraft draft;

  @override
  bool operator ==(Object other) =>
      other is CreateWeighIn && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(CreateWeighIn, id, draft);

  @override
  String toString() => 'CreateWeighIn($id)';
}

/// Replace a weigh-in's content (value, unit, time, note). An identical
/// draft writes nothing. A move to another day clears its trend preference
/// (A14 D3).
final class UpdateWeighIn extends WeighInOp {
  /// The row [id] at [expectedVersion] gets [draft]. Throws an
  /// `ArgumentError` for an invalid ID or version.
  new(this.id, this.expectedVersion, this.draft) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
  }

  /// The row.
  final String id;

  /// The version it must have.
  final int expectedVersion;

  /// The new content.
  final WeighInDraft draft;

  @override
  bool operator ==(Object other) =>
      other is UpdateWeighIn &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.draft == draft;

  @override
  int get hashCode => Object.hash(UpdateWeighIn, id, expectedVersion, draft);

  @override
  String toString() => 'UpdateWeighIn($id@v$expectedVersion)';
}

/// Delete a weigh-in (a tombstone; undo revives it).
final class DeleteWeighIn extends WeighInOp {
  /// Delete [weighIn] at its shown version.
  const new(this.weighIn) : super._();

  /// The row and the version it must have.
  final VersionedId weighIn;

  @override
  bool operator ==(Object other) =>
      other is DeleteWeighIn && other.weighIn == weighIn;

  @override
  int get hashCode => Object.hash(DeleteWeighIn, weighIn);

  @override
  String toString() => 'DeleteWeighIn($weighIn)';
}

/// Pick the weigh-in a day contributes to the trend (WB-003, A14 D3).
///
/// Sets the preference on [chosen] and clears it on every other weigh-in
/// of [day]; `null` goes back to the earliest and clears every preference.
/// [dayWeighIns] must be **exactly** the day's live weigh-ins at the
/// versions shown, else the handler rejects the change set.
final class ChooseTrendWeighIn extends WeighInOp {
  /// Throws an `ArgumentError` when [dayWeighIns] is empty, has a duplicate
  /// ID, or doesn't contain [chosen] at the same version.
  new(
    this.day, {
    required this.chosen,
    required Iterable<VersionedId> dayWeighIns,
  }) : dayWeighIns = List.unmodifiable(dayWeighIns),
       super._() {
    if (this.dayWeighIns.isEmpty) {
      throw ArgumentError.value(
        this.dayWeighIns,
        'dayWeighIns',
        'must not be empty',
      );
    }
    if (this.dayWeighIns.map((v) => v.id).toSet().length !=
        this.dayWeighIns.length) {
      throw ArgumentError.value(
        this.dayWeighIns,
        'dayWeighIns',
        'has duplicate IDs',
      );
    }
    if (chosen case final pick? when !this.dayWeighIns.contains(pick)) {
      throw ArgumentError.value(pick, 'chosen', 'must be one of dayWeighIns');
    }
  }

  /// The day.
  final LocalDate day;

  /// The weigh-in to use for the trend, or `null` for the earliest.
  final VersionedId? chosen;

  /// Every live weigh-in of [day], as shown. Unmodifiable; the order
  /// doesn't matter.
  final List<VersionedId> dayWeighIns;

  @override
  bool operator ==(Object other) =>
      other is ChooseTrendWeighIn &&
      other.day == day &&
      other.chosen == chosen &&
      other.dayWeighIns.length == dayWeighIns.length &&
      other.dayWeighIns.toSet().containsAll(dayWeighIns);

  @override
  int get hashCode => Object.hash(
    ChooseTrendWeighIn,
    day,
    chosen,
    Object.hashAllUnordered(dayWeighIns),
  );

  @override
  String toString() =>
      'ChooseTrendWeighIn($day, ${chosen ?? 'earliest'}, '
      '${dayWeighIns.length} weigh-ins)';
}
