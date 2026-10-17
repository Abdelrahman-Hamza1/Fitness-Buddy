import 'package:fb_domain/src/ids/uuid_v7.dart';

/// Who caused a change (`03` §5.3, A01 D5). Stored on every row it writes
/// (`origin`) in its text form ([toText]):
///
/// | Origin | Text |
/// |---|---|
/// | [direct] | `direct` |
/// | [Origin.proposal] | `proposal:<proposal id>` |
/// | [Origin.undo] | `undo:<change set id>` |
/// | [system] | `system` |
///
/// IDs are lowercase canonical UUIDs.
sealed class Origin {
  /// A Buddy proposal [proposalId] the user confirmed.
  factory proposal(String proposalId) = OriginProposal._;

  /// The undo of the change set [changeSetId].
  factory undo(String changeSetId) = OriginUndo._;

  const new _();

  /// A direct user action (it gets an undo).
  static const Origin direct = OriginDirect._();

  /// The app itself: seeds, migrations, maintenance.
  static const Origin system = OriginSystem._();

  /// Parses the text form exactly. Throws a `FormatException` otherwise.
  static Origin parse(String text) =>
      tryParse(text) ?? (throw FormatException('not an origin', text));

  /// Like [parse], but `null` instead of throwing.
  static Origin? tryParse(String text) {
    switch (text) {
      case 'direct':
        return direct;
      case 'system':
        return system;
    }
    final colon = text.indexOf(':');
    if (colon < 0) return null;
    final id = text.substring(colon + 1);
    if (!isUuid(id)) return null;
    return switch (text.substring(0, colon)) {
      'proposal' => OriginProposal._(id),
      'undo' => OriginUndo._(id),
      _ => null,
    };
  }

  /// The stored text form (see the class comment).
  String toText() => switch (this) {
    OriginDirect() => 'direct',
    OriginSystem() => 'system',
    OriginProposal(:final proposalId) => 'proposal:$proposalId',
    OriginUndo(:final changeSetId) => 'undo:$changeSetId',
  };

  @override
  String toString() => toText();
}

/// See [Origin.direct].
final class OriginDirect extends Origin {
  const new _() : super._();
}

/// See [Origin.system].
final class OriginSystem extends Origin {
  const new _() : super._();
}

/// See [Origin.proposal].
final class OriginProposal extends Origin {
  new _(this.proposalId) : super._() {
    _checkId(proposalId, 'proposalId');
  }

  /// The confirmed proposal.
  final String proposalId;

  @override
  bool operator ==(Object other) =>
      other is OriginProposal && other.proposalId == proposalId;

  @override
  int get hashCode => Object.hash(OriginProposal, proposalId);
}

/// See [Origin.undo].
final class OriginUndo extends Origin {
  new _(this.changeSetId) : super._() {
    _checkId(changeSetId, 'changeSetId');
  }

  /// The change set this undoes.
  final String changeSetId;

  @override
  bool operator ==(Object other) =>
      other is OriginUndo && other.changeSetId == changeSetId;

  @override
  int get hashCode => Object.hash(OriginUndo, changeSetId);
}

void _checkId(String id, String name) {
  if (!isUuid(id)) {
    throw ArgumentError.value(id, name, 'must be a lowercase canonical UUID');
  }
}
