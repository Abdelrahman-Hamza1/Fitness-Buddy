import 'package:fb_api_client/fb_api_client.dart';

/// The identity of one immutable synced version: `(entity, id, hlc)`
/// (`05` §5.4). Ids and HLCs aren't user content, but [toString] still
/// names only the entity.
final class SyncVersion {
  /// The version [hlc] of row [id] of [entity].
  const new(this.entity, this.id, this.hlc);

  /// The version a change or document carries.
  new ofChange(SyncChange change) : this(change.entity, change.id, change.hlc);

  /// The version a pulled document carries.
  new ofDocument(SyncDocument document)
    : this(document.entity, document.id, document.hlc);

  /// The entity wire name.
  final String entity;

  /// The row id.
  final String id;

  /// The version's HLC text (TD-049).
  final String hlc;

  /// The row this version belongs to, as `entity/id`.
  String get rowKey => '$entity/$id';

  @override
  bool operator ==(Object other) =>
      other is SyncVersion &&
      other.entity == entity &&
      other.id == id &&
      other.hlc == hlc;

  @override
  int get hashCode => Object.hash(entity, id, hlc);

  @override
  String toString() => 'SyncVersion($entity)';
}

/// A version the store moved out of the outbox because the server (or the
/// app's own encoder) rejected it permanently (A34 D5). [reason] is a fixed
/// code (`unsupported`, `invalidPayload`, `tooLarge`, a codec code, or
/// `unknown`), never a message.
final class ParkedVersion {
  /// [version] parked for [reason].
  const new(this.version, this.reason);

  /// The parked version.
  final SyncVersion version;

  /// The fixed reason code.
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is ParkedVersion &&
      other.version == version &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(version, reason);

  @override
  String toString() => 'ParkedVersion(${version.entity}, $reason)';
}

/// A pulled document stored aside because this app can't apply it yet
/// (A34 D7): an unknown entity, a newer `schemaVersion` or a payload the
/// codec can't read. [reason] is a fixed code.
final class DeferredDocument {
  /// [version] deferred for [reason].
  const new(this.version, this.reason);

  /// The deferred version.
  final SyncVersion version;

  /// `unknownEntity`, `newerSchema` or `unreadable`.
  final String reason;

  @override
  String toString() => 'DeferredDocument(${version.entity}, $reason)';
}

/// The durable pull position (stored with the rows it covers).
final class SyncCheckpoint {
  /// See the fields.
  const new({required this.cursor, this.datasetId, this.resetActive = false});

  /// The last applied `serverSeq` (decimal text; `0` before the first pull).
  final String cursor;

  /// The dataset the cursor belongs to (TD-066); `null` before discovery.
  final String? datasetId;

  /// A dataset reset is in progress (A34 D8): pulling from 0 and pruning
  /// the re-enqueued outbox until an empty page.
  final bool resetActive;

  @override
  String toString() =>
      'SyncCheckpoint(cursor: $cursor, bound: ${datasetId != null}, '
      'reset: $resetActive)';
}

/// What `SyncStore.pending` read: the changes to push, and the versions it
/// parked itself because the app's encoder refused them (reported, never
/// pushed).
final class PendingRead {
  /// See the fields.
  const new(this.changes, {this.parkedNow = const []});

  /// The rows to push, each as it is now (A34 D3).
  final List<SyncChange> changes;

  /// Versions parked while reading (e.g. `tooLarge` from a codec).
  final List<ParkedVersion> parkedNow;
}

/// What one applied pull page changed.
final class PageApplied {
  /// See the fields.
  const new({
    this.applied = 0,
    this.entities = const {},
    this.deferred = const [],
  });

  /// Rows written from the page.
  final int applied;

  /// The entity wire names of the rows written.
  final Set<String> entities;

  /// Documents stored aside (A34 D7).
  final List<DeferredDocument> deferred;
}

/// Why a sync run stopped (A34 D11, D12). Fixed kinds only: no messages,
/// no ids, no payloads (no user content in logs).
enum SyncFailureKind {
  /// No connection, a timeout or a dropped connection: retry later.
  offline,

  /// The account's credentials are gone (401 after the refresh).
  unauthorized,

  /// Not a registered account (403): sync is off.
  forbidden,

  /// The request body was too large (413); the engine splits or parks.
  payloadTooLarge,

  /// Rate limited (429): wait [SyncFailure.retryAfter] if given.
  rateLimited,

  /// The app is too old (426): the update gate takes over.
  upgradeRequired,

  /// The server failed (5xx).
  server,

  /// A response broke the protocol (bad page order, mismatched results).
  protocol,

  /// The server refused a version from the future (`clockDrift`): the
  /// phone clock is ahead.
  clockAhead,

  /// A pulled version is more than 24 h ahead of the phone clock: the
  /// phone clock is behind.
  clockBehind,

  /// The dataset changed again during a reset: retried next run.
  datasetUnstable,
}

/// A sync run or a transport call failed with [kind].
final class SyncFailure implements Exception {
  /// A failure of [kind]; [retryAfter] from a `Retry-After` header.
  const new(this.kind, {this.retryAfter});

  /// What went wrong.
  final SyncFailureKind kind;

  /// How long the server asked to wait, if it did.
  final Duration? retryAfter;

  @override
  String toString() => 'SyncFailure(${kind.name})';
}
