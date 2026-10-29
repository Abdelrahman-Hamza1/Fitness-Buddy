import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart' show checkRowVersion;
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/targets/target_events.dart';
import 'package:fb_domain/src/targets/target_records.dart';

/// The `targets` op family (A13 D4): three puts. A null [expectedVersion]
/// creates the row (phases and versions with an insert that fails on a
/// duplicate ID; the profile only when absent or tombstoned); otherwise the
/// row must be at that version (PA9). [toString] shows the op kind only:
/// records carry sensitive body data.
sealed class TargetsOp implements ChangeOp {
  new _(this.expectedVersion) {
    if (expectedVersion case final version?) {
      checkRowVersion(version, 'expectedVersion');
    }
  }

  /// The [family] of every targets op.
  static const String familyName = 'targets';

  /// The stored row version this op revises, or null to create the row.
  final int? expectedVersion;

  /// Which part of the targets data this op writes.
  TargetsPart get part;

  @override
  String get family => familyName;

  String get _kind;

  @override
  String toString() =>
      'TargetsOp.$_kind(${expectedVersion == null ? 'create' : 'update'})';
}

/// Creates or revises the `profile:self` row.
final class PutProfile extends TargetsOp {
  /// Puts [record]; see [TargetsOp.expectedVersion].
  new(this.record, {int? expectedVersion}) : super._(expectedVersion);

  /// The full new content.
  final ProfileRecord record;

  @override
  TargetsPart get part => TargetsPart.profile;

  @override
  String get _kind => 'putProfile';

  @override
  bool operator ==(Object other) =>
      other is PutProfile &&
      other.record == record &&
      other.expectedVersion == expectedVersion;

  @override
  int get hashCode => Object.hash(PutProfile, record, expectedVersion);
}

/// Creates or revises one goal phase row.
final class PutGoalPhase extends TargetsOp {
  /// Puts [record] (its ID must be a UUIDv7); see [TargetsOp.expectedVersion].
  new(this.record, {int? expectedVersion}) : super._(expectedVersion) {
    if (!isUuidV7(record.id)) throw ArgumentError('phase ID must be UUIDv7');
  }

  /// The full new content.
  final GoalPhaseRecord record;

  @override
  TargetsPart get part => TargetsPart.goals;

  @override
  String get _kind => 'putGoalPhase';

  @override
  bool operator ==(Object other) =>
      other is PutGoalPhase &&
      other.record == record &&
      other.expectedVersion == expectedVersion;

  @override
  int get hashCode => Object.hash(PutGoalPhase, record, expectedVersion);
}

/// Creates or revises one target settings version row.
final class PutTargetSettings extends TargetsOp {
  /// Puts [record] (its ID must be a UUIDv7); see [TargetsOp.expectedVersion].
  new(this.record, {int? expectedVersion}) : super._(expectedVersion) {
    if (!isUuidV7(record.id)) {
      throw ArgumentError('settings ID must be UUIDv7');
    }
  }

  /// The full new content.
  final TargetSettingsRecord record;

  @override
  TargetsPart get part => TargetsPart.settings;

  @override
  String get _kind => 'putTargetSettings';

  @override
  bool operator ==(Object other) =>
      other is PutTargetSettings &&
      other.record == record &&
      other.expectedVersion == expectedVersion;

  @override
  int get hashCode => Object.hash(PutTargetSettings, record, expectedVersion);
}
