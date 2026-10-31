import 'package:fb_domain/src/changes/origin.dart';

/// Something that happened to user data, emitted by the app's
/// `DomainEventBus` after a change set commits, in op order, and never on
/// rollback (A01 D4). Features react to each other only through these
/// (`03` §4).
///
/// Features add their own subclasses next to their op family. Events are
/// immutable values and carry IDs and keys, never user content.
abstract class DomainEvent {
  /// An event.
  const new();
}

/// A change set was committed. Emitted after the events of its ops.
final class ChangeSetApplied extends DomainEvent {
  /// The change set [changeSetId] from [origin] wrote rows of [entities].
  new({
    required this.changeSetId,
    required this.origin,
    required Iterable<String> entities,
  }) : entities = Set.unmodifiable(entities);

  /// The ID the applier gave the change set; an undo refers to it.
  final String changeSetId;

  /// Who caused the change.
  final Origin origin;

  /// The entity wire names of the rows written (`setting`, …). Unmodifiable.
  final Set<String> entities;

  @override
  bool operator ==(Object other) =>
      other is ChangeSetApplied &&
      other.changeSetId == changeSetId &&
      other.origin == origin &&
      other.entities.length == entities.length &&
      other.entities.containsAll(entities);

  @override
  int get hashCode =>
      Object.hash(changeSetId, origin, Object.hashAllUnordered(entities));

  @override
  String toString() => 'ChangeSetApplied($changeSetId, $origin, $entities)';
}

/// Sync applied rows pulled from the account (A34 D17): emitted by the app's
/// sync engine after a pull page commits. Not a [ChangeSetApplied]: nothing
/// local was confirmed, so it never schedules a push and has no undo.
final class RemoteChangesApplied extends DomainEvent {
  /// Rows of [entities] (wire names) were written from the server.
  new(Iterable<String> entities) : entities = Set.unmodifiable(entities);

  /// The entity wire names of the rows written. Unmodifiable.
  final Set<String> entities;

  @override
  bool operator ==(Object other) =>
      other is RemoteChangesApplied &&
      other.entities.length == entities.length &&
      other.entities.containsAll(entities);

  @override
  int get hashCode => Object.hashAllUnordered(entities);

  @override
  String toString() => 'RemoteChangesApplied($entities)';
}
