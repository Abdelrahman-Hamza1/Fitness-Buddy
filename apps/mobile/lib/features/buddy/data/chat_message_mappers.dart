import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// A stored row or a synced payload that isn't a readable chat message.
/// Never echoes the value: it can hold user text.
final class ChatMessageMappingError implements Exception {
  /// Fixed, typed failure without the source text.
  const new();

  @override
  String toString() => 'ChatMessageMappingError';
}

/// The `chatMessage` v1 payload keys (`contracts/openapi/sync-entities.json`),
/// in contract order: the explicit allowlist both sync directions use, so a
/// local-only column (`request_json`, `answer_json`, TD-102; attachments,
/// A28/A29) can never leak.
const chatMessageSyncKeys = [
  'createdAtMs',
  'origin',
  'editedByUser',
  'role',
  'text',
  'status',
  'language',
  'replyToMessageId',
  'codecVersion',
  'budgetJson',
];

/// The domain message of [row]. An unknown language tag (a synced row may
/// hold any short string) reads as `null`.
ChatMessage chatMessageOf(ChatMessageRow row) {
  final role = ChatMessageRole.fromCode(row.role);
  final status = ChatMessageStatus.fromCode(row.status);
  if (role == null || status == null) throw const ChatMessageMappingError();
  try {
    return ChatMessage(
      id: row.id,
      version: row.version,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      draft: ChatMessageDraft(
        role: role,
        text: row.messageText,
        status: status,
        language: ChatLanguage.fromCode(row.language),
        replyToMessageId: row.replyToMessageId,
        codecVersion: row.codecVersion,
        budgetJson: row.budgetJson,
      ),
    );
    // Domain constructors reject invalid stored values with ArgumentError.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    throw const ChatMessageMappingError();
  }
}

/// The content columns of [draft] for a new row [id], with the local-only
/// interpret [answerJson] of an assistant row (A23 D14); the applier stamps
/// the sync metadata.
ChatMessagesCompanion chatMessageColumns(
  String id,
  ChatMessageDraft draft, {
  String? answerJson,
}) => ChatMessagesCompanion(
  id: Value(id),
  role: Value(draft.role.code),
  messageText: Value(draft.text),
  status: Value(draft.status.code),
  language: Value(draft.language?.code),
  replyToMessageId: Value(draft.replyToMessageId),
  codecVersion: Value(draft.codecVersion),
  budgetJson: Value(draft.budgetJson),
  answerJson: Value(answerJson),
);

/// The `chatMessage` v1 payload of [row]: exactly [chatMessageSyncKeys],
/// never the local-only columns. Holds user content: never log it.
/// Tombstone scrubbing (`text: ""`, `budgetJson: null`) is the delete op's
/// job (A23 D16, PA10), so the payload mirrors the row, and a tombstone that
/// still holds content is refused with [ChatMessageMappingError] rather than
/// leaked or fixed here.
Map<String, Object?> chatMessageSyncPayload(ChatMessageRow row) {
  if (row.deletedAt != null &&
      (row.messageText.isNotEmpty || row.budgetJson != null)) {
    throw const ChatMessageMappingError();
  }
  return {
    'createdAtMs': row.createdAt,
    'origin': row.origin,
    'editedByUser': row.editedByUser,
    'role': row.role,
    'text': row.messageText,
    'status': row.status,
    'language': row.language,
    'replyToMessageId': row.replyToMessageId,
    'codecVersion': row.codecVersion,
    'budgetJson': row.budgetJson,
  };
}

/// Reads a synced `chatMessage` v1 [payload] into row [id] with the given
/// sync metadata. Throws [ChatMessageMappingError] unless [payload] has
/// exactly the contract's fields with their types, UTF-16 bounds, integer
/// ranges (a whole `1.0` reads as `1`), lowercase canonical UUID, closed
/// codes and a `budgetJson` that is JSON. The server's generic nested pass
/// (surrogates, U+0000, JSON depth/width, decimal numbers) isn't repeated:
/// those rows are the corpus's `serverRejectsAppTolerates`.
ChatMessageRow chatMessageRowOfSync(
  Object? payload, {
  required String id,
  required String updatedHlc,
  required int version,
  required String deviceId,
  int? deletedAtMs,
}) {
  if (payload is! Map<String, Object?> ||
      payload.length != chatMessageSyncKeys.length ||
      !chatMessageSyncKeys.every(payload.containsKey)) {
    throw const ChatMessageMappingError();
  }
  String text(String key, int max) {
    final value = payload[key];
    if (value is String && value.length <= max) return value;
    throw const ChatMessageMappingError();
  }

  String? nullableText(String key, int max) =>
      payload[key] == null ? null : text(key, max);

  int integer(String key, int min, int max) {
    final value = payload[key];
    if (value is num && value == value.truncate()) {
      final whole = value.toInt();
      if (whole >= min && whole <= max) return whole;
    }
    throw const ChatMessageMappingError();
  }

  final role = text('role', 16);
  final status = text('status', 16);
  final reply = nullableText('replyToMessageId', 36);
  final budget = nullableText('budgetJson', ChatProposalSyncBounds.json);
  final editedByUser = payload['editedByUser'];
  if (ChatMessageRole.fromCode(role) == null ||
      ChatMessageStatus.fromCode(status) == null ||
      (reply != null && !isUuid(reply)) ||
      editedByUser is! bool) {
    throw const ChatMessageMappingError();
  }
  if (budget != null) {
    try {
      jsonDecode(budget);
    } on FormatException {
      throw const ChatMessageMappingError();
    }
  }
  return ChatMessageRow(
    id: id,
    createdAt: integer('createdAtMs', 0, 9007199254740991),
    updatedHlc: updatedHlc,
    version: version,
    deletedAt: deletedAtMs,
    deviceId: deviceId,
    origin: text('origin', ChatProposalSyncBounds.origin),
    editedByUser: editedByUser,
    role: role,
    messageText: text('text', ChatProposalSyncBounds.text),
    status: status,
    language: nullableText('language', ChatProposalSyncBounds.language),
    replyToMessageId: reply,
    codecVersion: payload['codecVersion'] == null
        ? null
        : integer(
            'codecVersion',
            ChatProposalSyncBounds.codecVersionMin,
            ChatProposalSyncBounds.codecVersionMax,
          ),
    budgetJson: budget,
  );
}
