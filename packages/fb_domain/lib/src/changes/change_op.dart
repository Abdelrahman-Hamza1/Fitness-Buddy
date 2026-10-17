import 'package:fb_domain/src/changes/origin.dart';

/// One intended change to user data, as a pure value (A01 D1, `03` §5.2).
///
/// Each feature owns one `sealed` family of ops (`SettingsOp`, `DiaryOp`, …)
/// that implements this. The app's `ChangeSetApplier` hands each op to the
/// handler registered for its [family], which turns it into row writes. Ops
/// carry IDs, expected versions and intent, never SQL, so domain code (the
/// ProposalEngine, `buddy_eval`) can build them.
///
/// Implementations are immutable and have value equality.
abstract interface class ChangeOp {
  /// The name of the op family, the key its handler is registered under.
  String get family;
}

/// Ops applied together, in order, in one transaction: all of them or none
/// (`03` §5.2).
final class ChangeSet {
  /// A change set of [ops] (1 to [maxOps], in apply order) caused by
  /// [origin]. Throws an `ArgumentError` for no ops or too many.
  new(Iterable<ChangeOp> ops, {required this.origin})
    : ops = List.unmodifiable(ops) {
    if (this.ops.isEmpty || this.ops.length > maxOps) {
      throw ArgumentError.value(
        this.ops.length,
        'ops',
        'a change set has 1 to $maxOps ops',
      );
    }
  }

  /// The most ops one change set may hold.
  static const int maxOps = 500;

  /// The ops, in apply order. Unmodifiable.
  final List<ChangeOp> ops;

  /// Who caused the change.
  final Origin origin;

  @override
  bool operator ==(Object other) {
    if (other is! ChangeSet ||
        other.origin != origin ||
        other.ops.length != ops.length) {
      return false;
    }
    for (var i = 0; i < ops.length; i++) {
      if (other.ops[i] != ops[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(origin, Object.hashAll(ops));

  @override
  String toString() => 'ChangeSet($origin, ${ops.length} ops)';
}
