import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// Why a stored row or a synced payload isn't a usable `proposal` (A23 D16).
/// Fixed codes: never echoes the value (it holds user content).
enum ProposalMappingError implements Exception {
  /// An unknown `status` or `outcome` code.
  code,

  /// A payload that doesn't have the contract's fields, types or bounds.
  payload,

  /// A row whose JSON the server can't admit (over 32768 UTF-16 units or
  /// outside the generic nested limits): kept local, parked by sync, never
  /// pushed or acknowledged (A23 D15).
  tooLarge,

  /// A tombstone whose content isn't scrubbed: the delete op owns
  /// scrubbing, so the mapper refuses it rather than leak or fix it (A23
  /// D16, PA10).
  unscrubbedTombstone;

  @override
  String toString() => 'ProposalMappingError.$name';
}

/// The `proposal` v1 payload keys (`contracts/openapi/sync-entities.json`),
/// in contract order: the explicit allowlist both sync directions use.
const proposalSyncKeys = [
  'createdAtMs',
  'origin',
  'editedByUser',
  'kind',
  'status',
  'outcome',
  'resolvedAtMs',
  'originMessageId',
  'budgetMessageId',
  'codecVersion',
  'interpretationJson',
  'draftJson',
];

/// The scrubbed tombstone draft (B18 handoff).
const scrubbedProposalDraft = '{}';

/// The domain record of [row]. Throws [ProposalMappingError.code] for an
/// unknown status or outcome.
ProposalRecord proposalRecordOf(ProposalRow row) {
  final status = ProposalStatus.fromCode(row.status);
  final outcome = row.outcome == null
      ? null
      : ProposalOutcome.fromCode(row.outcome);
  if (status == null || (row.outcome != null && outcome == null)) {
    throw ProposalMappingError.code;
  }
  DateTime utc(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  try {
    return ProposalRecord(
      id: row.id,
      version: row.version,
      createdAt: utc(row.createdAt),
      kind: row.kind,
      status: status,
      outcome: outcome,
      resolvedAt: row.resolvedAt == null ? null : utc(row.resolvedAt!),
      originMessageId: row.originMessageId,
      budgetMessageId: row.budgetMessageId,
      codecVersion: row.codecVersion,
      interpretationJson: row.interpretationJson,
      draftJson: row.draftJson,
    );
    // Domain constructors reject invalid stored values with ArgumentError.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    throw ProposalMappingError.payload;
  }
}

/// The content columns of a new `pending` row [id] with [draft]; the applier
/// stamps the sync metadata.
ProposalsCompanion proposalColumns(String id, ProposalRowDraft draft) =>
    ProposalsCompanion(
      id: Value(id),
      kind: Value(draft.kind),
      status: Value(ProposalStatus.pending.code),
      outcome: const Value(null),
      resolvedAt: const Value(null),
      originMessageId: Value(draft.originMessageId),
      budgetMessageId: Value(draft.budgetMessageId),
      codecVersion: Value(draft.codecVersion),
      interpretationJson: Value(draft.interpretationJson),
      draftJson: Value(draft.draftJson),
    );

/// The `proposal` v1 payload of [row] as stored: exactly [proposalSyncKeys]
/// (PA10: the mapper never scrubs). Throws [ProposalMappingError.code] for
/// an unknown code, [ProposalMappingError.unscrubbedTombstone] for a
/// tombstone that still holds content, and [ProposalMappingError.tooLarge]
/// when a JSON field doesn't fit the server's bounds (A23 D15: the row stays
/// local and pending). Holds user content: never log it.
Map<String, Object?> proposalToSync(ProposalRow row) {
  if (ProposalStatus.fromCode(row.status) == null ||
      (row.outcome != null && ProposalOutcome.fromCode(row.outcome) == null)) {
    throw ProposalMappingError.code;
  }
  if (row.deletedAt != null &&
      (row.draftJson != scrubbedProposalDraft ||
          row.interpretationJson != null)) {
    throw ProposalMappingError.unscrubbedTombstone;
  }
  for (final json in [row.interpretationJson, row.draftJson]) {
    if (json != null && !ProposalDraftCodec.fitsSync(json)) {
      throw ProposalMappingError.tooLarge;
    }
  }
  return {
    'createdAtMs': row.createdAt,
    'origin': row.origin,
    'editedByUser': row.editedByUser,
    'kind': row.kind,
    'status': row.status,
    'outcome': row.outcome,
    'resolvedAtMs': row.resolvedAt,
    'originMessageId': row.originMessageId,
    'budgetMessageId': row.budgetMessageId,
    'codecVersion': row.codecVersion,
    'interpretationJson': row.interpretationJson,
    'draftJson': row.draftJson,
  };
}

/// Whether [row] can't sync because its JSON is too large or out of the
/// server's shape (A23 D15): the card shows "Too large to sync".
bool proposalTooLargeToSync(ProposalRecord row) => [
  row.interpretationJson,
  row.draftJson,
].any((json) => json != null && !ProposalDraftCodec.fitsSync(json));

/// Reads a synced `proposal` v1 [payload] into row [id] with the given sync
/// metadata. Throws [ProposalMappingError.code] for an unknown status or
/// outcome, and [ProposalMappingError.payload] unless [payload] has exactly
/// the contract's fields with their types, UTF-16 bounds, integer ranges (a
/// whole `1.0` reads as `1`), lowercase canonical UUIDs and JSON fields that
/// decode. The server's generic nested pass isn't repeated: those rows are
/// the corpus's `serverRejectsAppTolerates`.
ProposalRow proposalRowOfSync(
  Object? payload, {
  required String id,
  required String updatedHlc,
  required int version,
  required String deviceId,
  int? deletedAtMs,
}) {
  if (payload is! Map<String, Object?> ||
      payload.length != proposalSyncKeys.length ||
      !proposalSyncKeys.every(payload.containsKey)) {
    throw ProposalMappingError.payload;
  }
  String text(String key, int max) {
    final value = payload[key];
    if (value is String && value.length <= max) return value;
    throw ProposalMappingError.payload;
  }

  String? nullableText(String key, int max) =>
      payload[key] == null ? null : text(key, max);

  int integer(String key, int min, int max) {
    final value = payload[key];
    if (value is num && value == value.truncate()) {
      final whole = value.toInt();
      if (whole >= min && whole <= max) return whole;
    }
    throw ProposalMappingError.payload;
  }

  String? ref(String key) {
    final value = nullableText(key, 36);
    if (value != null && !isUuid(value)) throw ProposalMappingError.payload;
    return value;
  }

  String? json(String key) {
    final value = nullableText(key, ChatProposalSyncBounds.json);
    if (value != null) {
      try {
        jsonDecode(value);
      } on FormatException {
        throw ProposalMappingError.payload;
      }
    }
    return value;
  }

  final status = text('status', 16);
  final outcome = nullableText('outcome', 16);
  final editedByUser = payload['editedByUser'];
  final draft = json('draftJson');
  if (editedByUser is! bool || draft == null) {
    throw ProposalMappingError.payload;
  }
  final row = ProposalRow(
    id: id,
    createdAt: integer('createdAtMs', 0, _maxSafeInteger),
    updatedHlc: updatedHlc,
    version: version,
    deletedAt: deletedAtMs,
    deviceId: deviceId,
    origin: text('origin', ChatProposalSyncBounds.origin),
    editedByUser: editedByUser,
    kind: text('kind', ChatProposalSyncBounds.kind),
    status: status,
    outcome: outcome,
    resolvedAt: payload['resolvedAtMs'] == null
        ? null
        : integer('resolvedAtMs', 0, _maxSafeInteger),
    originMessageId: ref('originMessageId'),
    budgetMessageId: ref('budgetMessageId'),
    codecVersion: integer(
      'codecVersion',
      ChatProposalSyncBounds.codecVersionMin,
      ChatProposalSyncBounds.codecVersionMax,
    ),
    interpretationJson: json('interpretationJson'),
    draftJson: draft,
  );
  if (ProposalStatus.fromCode(status) == null ||
      (outcome != null && ProposalOutcome.fromCode(outcome) == null)) {
    throw ProposalMappingError.code;
  }
  return row;
}

/// The card map `ProposalDraftCodec.restore` takes for [record] (A23 D12;
/// a kind other than `foodLog` is `invalidInput`):
/// `cardFromSync` over its synced fields, with the authoritative top-level
/// `id`, `status`, message refs and `codecVersion` overwriting the copies in
/// the draft. A fixed issue, never a throw; the result is never logged.
ProposalResult<Map<String, Object?>> proposalRestoreCard(
  ProposalRecord record,
) {
  // Only a meal card decodes into a food session; any other kind (an open
  // vocabulary) is "not restorable" (B18 handoff, A23 D13).
  if (record.kind != foodLogKind) {
    return const ProposalResult.failure(ProposalIssue.invalidInput);
  }
  final card = _restoreFields(record);
  if (card.issue case final issue?) return ProposalResult.failure(issue);
  return ProposalResult.success({
    ...card.value!,
    'id': record.id,
    'status': record.status.code,
    'originMessageId': record.originMessageId,
    'budgetMessageId': record.budgetMessageId,
    'codecVersion': record.codecVersion,
  });
}

/// [ProposalDraftCodec.cardFromSync] for a row that fits the wire; a local
/// row over it (A23 D15) is read the same way within the local input bound.
ProposalResult<Map<String, Object?>> _restoreFields(ProposalRecord record) {
  final interpretation = record.interpretationJson;
  final fits =
      ProposalDraftCodec.fitsSyncString(record.draftJson) &&
      (interpretation == null ||
          ProposalDraftCodec.fitsSyncString(interpretation));
  if (fits || interpretation == null) {
    return ProposalDraftCodec.cardFromSync(
      interpretationJson: interpretation,
      draftJson: record.draftJson,
    );
  }
  const limit = ProposalPolicyConstants.maxInputBytes;
  if (record.draftJson.length > limit || interpretation.length > limit) {
    return const ProposalResult.failure(ProposalIssue.inputTooLarge);
  }
  try {
    final draft = jsonDecode(record.draftJson);
    if (draft is! Map<String, Object?> || draft.containsKey('interpretation')) {
      return const ProposalResult.failure(ProposalIssue.invalidInput);
    }
    return ProposalResult.success({
      ...draft,
      'interpretation': jsonDecode(interpretation),
    });
  } on FormatException {
    return const ProposalResult.failure(ProposalIssue.invalidInput);
  }
}

const _maxSafeInteger = 9007199254740991;
