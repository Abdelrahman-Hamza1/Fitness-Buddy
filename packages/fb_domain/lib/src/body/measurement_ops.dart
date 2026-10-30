import 'package:fb_domain/src/body/measurement.dart';
import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';

/// The op family of body measurements and custom measurement types (A15b
/// D15). The app's `MeasurementOpHandler` turns each op into row writes,
/// validates drafts and names inside the transaction and guards undo on the
/// state after the inverse. `toString` never shows a value or a name.
sealed class MeasurementOp implements ChangeOp {
  const new _();

  /// The [family] of every measurement op.
  static const String familyName = 'measurement';

  @override
  String get family => familyName;
}

/// Log a measurement (WB-040). The [id] is assigned when the op is built.
final class CreateMeasurement extends MeasurementOp {
  /// The new row [id] with [draft]. Throws an `ArgumentError` for an
  /// invalid ID.
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  /// The new row's ID.
  final String id;

  /// What is saved.
  final MeasurementDraft draft;

  @override
  bool operator ==(Object other) =>
      other is CreateMeasurement && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(CreateMeasurement, id, draft);

  @override
  String toString() => 'CreateMeasurement($id)';
}

/// Replace a measurement's value, unit and time. An identical draft writes
/// nothing. The type can't change (`typeChanged`): moving an entry to
/// another type is a delete plus a create.
final class UpdateMeasurement extends MeasurementOp {
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
  final MeasurementDraft draft;

  @override
  bool operator ==(Object other) =>
      other is UpdateMeasurement &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.draft == draft;

  @override
  int get hashCode =>
      Object.hash(UpdateMeasurement, id, expectedVersion, draft);

  @override
  String toString() => 'UpdateMeasurement($id@v$expectedVersion)';
}

/// Delete a measurement (a tombstone; undo revives it).
final class DeleteMeasurement extends MeasurementOp {
  /// Delete [measurement] at its shown version.
  const new(this.measurement) : super._();

  /// The row and the version it must have.
  final VersionedId measurement;

  @override
  bool operator ==(Object other) =>
      other is DeleteMeasurement && other.measurement == measurement;

  @override
  int get hashCode => Object.hash(DeleteMeasurement, measurement);

  @override
  String toString() => 'DeleteMeasurement($measurement)';
}

/// Add a custom measurement type, a length (WB-040). The name is stored
/// trimmed ([CustomTypeName.normalize]); the handler validates it and its
/// live uniqueness ignoring case.
final class CreateMeasurementType extends MeasurementOp {
  /// The new type [id] named [name]. Throws an `ArgumentError` for an
  /// invalid ID.
  new(this.id, String name) : name = CustomTypeName.normalize(name), super._() {
    checkUuid(id, 'id');
  }

  /// The new row's ID.
  final String id;

  /// The name, trimmed. User content.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is CreateMeasurementType && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(CreateMeasurementType, id, name);

  @override
  String toString() => 'CreateMeasurementType($id)';
}

/// Rename a custom measurement type. The same name writes nothing.
final class RenameMeasurementType extends MeasurementOp {
  /// The type [id] at [expectedVersion] gets [name] (trimmed). Throws an
  /// `ArgumentError` for an invalid ID or version.
  new(this.id, this.expectedVersion, String name)
    : name = CustomTypeName.normalize(name),
      super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
  }

  /// The type.
  final String id;

  /// The version it must have.
  final int expectedVersion;

  /// The new name, trimmed. User content.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is RenameMeasurementType &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.name == name;

  @override
  int get hashCode =>
      Object.hash(RenameMeasurementType, id, expectedVersion, name);

  @override
  String toString() => 'RenameMeasurementType($id@v$expectedVersion)';
}

/// Delete a custom type and every live measurement of it, atomically
/// (tombstones; undo revives them all).
///
/// [measurements] must be **exactly** the type's live measurements at the
/// versions shown, else the handler rejects the change set
/// (`sourceChanged`).
final class DeleteMeasurementType extends MeasurementOp {
  /// Throws an `ArgumentError` when [measurements] has a duplicate ID.
  new(this.type, Iterable<VersionedId> measurements)
    : measurements = List.unmodifiable(measurements),
      super._() {
    if (this.measurements.map((v) => v.id).toSet().length !=
        this.measurements.length) {
      throw ArgumentError.value(
        this.measurements.length,
        'measurements',
        'has duplicate IDs',
      );
    }
  }

  /// The type and the version it must have.
  final VersionedId type;

  /// Its live measurements, as shown. Unmodifiable; the order doesn't
  /// matter.
  final List<VersionedId> measurements;

  @override
  bool operator ==(Object other) =>
      other is DeleteMeasurementType &&
      other.type == type &&
      other.measurements.length == measurements.length &&
      other.measurements.toSet().containsAll(measurements);

  @override
  int get hashCode => Object.hash(
    DeleteMeasurementType,
    type,
    Object.hashAllUnordered(measurements),
  );

  @override
  String toString() =>
      'DeleteMeasurementType($type, ${measurements.length} measurements)';
}
