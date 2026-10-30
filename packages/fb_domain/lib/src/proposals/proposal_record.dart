import 'dart:convert' show jsonDecode, utf8;

import 'package:fb_domain/src/chat/chat_text.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/proposals/proposal_policy_constants.dart';
import 'package:fb_domain/src/proposals/proposal_sync_codes.dart';

/// Why a proposal row isn't admissible (A23 D5). Codes only, never values:
/// the JSON holds user content.
enum InvalidProposal {
  /// The row ID isn't a UUIDv7 (proposal rows are random, never UUIDv5).
  id('proposalId'),

  /// `kind` empty, over 32 UTF-16 units, or not well-formed text.
  kind('proposalKind'),

  /// `originMessageId` or `budgetMessageId` isn't a lowercase canonical
  /// UUID.
  ref('proposalRef'),

  /// `codecVersion` outside 1…2147483647.
  codecVersion('proposalCodecVersion'),

  /// `interpretationJson` isn't well-formed JSON within the local bound.
  interpretation('proposalInterpretation'),

  /// `draftJson` isn't a well-formed JSON object within the local bound.
  draft('proposalDraft'),

  /// A `foodLog` row without both message refs and an interpretation
  /// (TD-083).
  foodLog('proposalFoodLog');

  new(this.code);

  /// The rejection code (the app's `InvalidOp.code`).
  final String code;
}

/// The content of a new proposal row (`proposal` v1 without the sync
/// metadata and the resolution fields), as written through
/// `ChangeSetApplier`. A new row is always `pending`.
///
/// The JSON fields are bounded by the local input ceiling
/// ([ProposalPolicyConstants.maxInputBytes]), not by the 32768-unit sync
/// bound: an oversized card stays a local pending row and is parked by the
/// sync mapper (A23 D15).
final class ProposalRowDraft {
  /// A proposal of [kind] at [codecVersion] with [draftJson].
  const new({
    required this.kind,
    required this.codecVersion,
    required this.draftJson,
    this.originMessageId,
    this.budgetMessageId,
    this.interpretationJson,
  });

  /// The open kind vocabulary (`foodLog` for Buddy meal cards).
  final String kind;

  /// The assistant message that created the card; never changes.
  final String? originMessageId;

  /// The assistant message whose budget the card currently belongs to.
  final String? budgetMessageId;

  /// Version of the engine JSON format.
  final int codecVersion;

  /// Only this card's normalized intents (`foodLog`), or `null`.
  final String? interpretationJson;

  /// The card's compact draft. User content: never logged.
  final String draftJson;

  /// The first rule this draft breaks, or `null`.
  InvalidProposal? validate() {
    if (kind.isEmpty || !ChatText.admits(kind, limit: 32)) {
      return InvalidProposal.kind;
    }
    for (final ref in [originMessageId, budgetMessageId]) {
      if (ref != null && !isUuid(ref)) return InvalidProposal.ref;
    }
    return validateProposalContent(
      kind: kind,
      budgetMessageId: budgetMessageId,
      originMessageId: originMessageId,
      codecVersion: codecVersion,
      interpretationJson: interpretationJson,
      draftJson: draftJson,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProposalRowDraft &&
      other.kind == kind &&
      other.originMessageId == originMessageId &&
      other.budgetMessageId == budgetMessageId &&
      other.codecVersion == codecVersion &&
      other.interpretationJson == interpretationJson &&
      other.draftJson == draftJson;

  @override
  int get hashCode => Object.hash(
    kind,
    originMessageId,
    budgetMessageId,
    codecVersion,
    interpretationJson,
    draftJson,
  );

  @override
  String toString() => 'ProposalRowDraft($kind, v$codecVersion)';
}

/// The content rules every proposal write re-checks (A23 D5): the codec
/// version range, well-formed JSON within the local bound (the draft an
/// object) and the `foodLog` pairing. `null` when admissible.
InvalidProposal? validateProposalContent({
  required String kind,
  required String? originMessageId,
  required String? budgetMessageId,
  required int codecVersion,
  required String? interpretationJson,
  required String draftJson,
}) {
  if (codecVersion < ChatProposalSyncBounds.codecVersionMin ||
      codecVersion > ChatProposalSyncBounds.codecVersionMax) {
    return InvalidProposal.codecVersion;
  }
  if (interpretationJson != null && !_localJson(interpretationJson)) {
    return InvalidProposal.interpretation;
  }
  if (!_localJson(draftJson, object: true)) return InvalidProposal.draft;
  if (kind == foodLogKind &&
      (originMessageId == null ||
          budgetMessageId == null ||
          interpretationJson == null)) {
    return InvalidProposal.foodLog;
  }
  return null;
}

/// The `kind` of a Buddy meal card.
const foodLogKind = 'foodLog';

bool _localJson(String json, {bool object = false}) {
  if (!ChatText.isWellFormed(json) ||
      json.length > ProposalPolicyConstants.maxInputBytes ||
      utf8.encode(json).length > ProposalPolicyConstants.maxInputBytes) {
    return false;
  }
  try {
    final decoded = jsonDecode(json);
    return !object || decoded is Map<String, Object?>;
  } on FormatException {
    return false;
  }
}

/// The codec `revision` stored in an engine JSON object, or `null` when
/// [json] isn't an object with a non-negative integer `revision` (a scrubbed
/// `{}` or another kind's draft): such rows aren't revision-guarded.
int? proposalRevisionOf(String? json) {
  if (json == null) return null;
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, Object?>) {
      final revision = decoded['revision'];
      if (revision is int && revision >= 0) return revision;
    }
  } on FormatException {
    return null;
  }
  return null;
}

/// A stored proposal (A23 D9): identity, version, when it was created, its
/// resolution and its content. What `ProposalRepository` returns; never a
/// database row.
final class ProposalRecord {
  /// Row [id] at [version], created at [createdAt] (UTC).
  new({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.kind,
    required this.status,
    required this.codecVersion,
    required this.draftJson,
    this.outcome,
    this.resolvedAt,
    this.originMessageId,
    this.budgetMessageId,
    this.interpretationJson,
  }) {
    checkUuid(id, 'id');
    checkRowVersion(version);
    if (!createdAt.isUtc || (resolvedAt != null && !resolvedAt!.isUtc)) {
      throw ArgumentError('createdAt and resolvedAt must be UTC');
    }
  }

  /// Row ID.
  final String id;

  /// Observed version.
  final int version;

  /// When the row was first written, UTC.
  final DateTime createdAt;

  /// The open kind vocabulary (`foodLog`).
  final String kind;

  /// Stored status (authoritative over the copy inside [draftJson]).
  final ProposalStatus status;

  /// How it ended; `null` while pending.
  final ProposalOutcome? outcome;

  /// When it was resolved, UTC; `null` while pending.
  final DateTime? resolvedAt;

  /// The creating assistant message; immutable.
  final String? originMessageId;

  /// The assistant message whose budget the card belongs to now.
  final String? budgetMessageId;

  /// Engine JSON format version.
  final int codecVersion;

  /// This card's normalized intents. User content: never logged.
  final String? interpretationJson;

  /// The compact draft. User content: never logged.
  final String draftJson;

  /// Whether the user may still confirm or discard it.
  bool get isPending => status == ProposalStatus.pending;

  @override
  bool operator ==(Object other) =>
      other is ProposalRecord &&
      other.id == id &&
      other.version == version &&
      other.createdAt == createdAt &&
      other.kind == kind &&
      other.status == status &&
      other.outcome == outcome &&
      other.resolvedAt == resolvedAt &&
      other.originMessageId == originMessageId &&
      other.budgetMessageId == budgetMessageId &&
      other.codecVersion == codecVersion &&
      other.interpretationJson == interpretationJson &&
      other.draftJson == draftJson;

  @override
  int get hashCode => Object.hash(
    id,
    version,
    createdAt,
    kind,
    status,
    outcome,
    resolvedAt,
    originMessageId,
    budgetMessageId,
    codecVersion,
    interpretationJson,
    draftJson,
  );

  @override
  String toString() =>
      'ProposalRecord($id@v$version, ${status.code}, ${outcome?.code})';
}
