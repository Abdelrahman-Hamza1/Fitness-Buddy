import 'dart:convert' show jsonDecode;

import 'package:fb_domain/src/chat/chat_language.dart';
import 'package:fb_domain/src/chat/chat_text.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/proposals/proposal_sync_codes.dart';

/// Why a chat message isn't admissible (A22 D5). Codes only, never values:
/// the text is user content.
enum InvalidChatMessage {
  /// The row ID isn't a UUIDv7 (chat rows are random, never UUIDv5).
  id('chatMessageId'),

  /// Text over 8192 UTF-16 units, with U+0000 or an unpaired surrogate.
  text('chatMessageText'),

  /// `replyToMessageId` isn't a lowercase canonical UUID.
  replyTo('chatMessageReplyTo'),

  /// `codecVersion` outside 1…2147483647, or without its `budgetJson`.
  codecVersion('chatMessageCodecVersion'),

  /// `budgetJson` over 32768 UTF-16 units, not JSON, with U+0000 or an
  /// unpaired surrogate, or without its `codecVersion`.
  budget('chatMessageBudget'),

  /// A user row with a budget: only the assistant row carries it.
  userBudget('chatMessageUserBudget'),

  /// The local interpret answer (A23 D14) on a user row, or not a
  /// well-formed JSON object within the local input bound.
  answer('chatMessageAnswer');

  new(this.code);

  /// The rejection code (the app's `InvalidOp.code`).
  final String code;
}

/// The content of one chat message (`chatMessage` v1 without the sync
/// metadata), as written through `ChangeSetApplier`.
///
/// Values aren't checked on construction; [validateWire] says whether the
/// server admits them, and the op handler rejects any draft that fails it.
final class ChatMessageDraft {
  /// A message by [role] with [text] in [status].
  const new({
    required this.role,
    required this.text,
    required this.status,
    this.language,
    this.replyToMessageId,
    this.codecVersion,
    this.budgetJson,
  });

  /// Who wrote it.
  final ChatMessageRole role;

  /// What was written. User content: never logged.
  final String text;

  /// Processing state.
  final ChatMessageStatus status;

  /// The language the user wrote in (user rows) or the reply language
  /// (assistant rows); `null` when unknown or mixed.
  final ChatLanguage? language;

  /// The user message an assistant row answers.
  final String? replyToMessageId;

  /// Version of [budgetJson]'s engine format; set exactly when it is.
  final int? codecVersion;

  /// The shared question budget (`ProposalDraftCodec.encodeMessageBudget`),
  /// on the assistant row only.
  final String? budgetJson;

  /// The first wire rule this draft breaks, or `null` if the server admits
  /// it (`contracts/README.md` §chatMessage and proposal admission, plus the
  /// app conventions: the budget pair is both-or-neither and never on a
  /// user row).
  InvalidChatMessage? validateWire() {
    if (!ChatText.admits(text)) return InvalidChatMessage.text;
    if (replyToMessageId case final reply? when !isUuid(reply)) {
      return InvalidChatMessage.replyTo;
    }
    final codec = codecVersion;
    final budget = budgetJson;
    if (role == ChatMessageRole.user && (codec != null || budget != null)) {
      return InvalidChatMessage.userBudget;
    }
    if (codec != null &&
        (budget == null ||
            codec < ChatProposalSyncBounds.codecVersionMin ||
            codec > ChatProposalSyncBounds.codecVersionMax)) {
      return InvalidChatMessage.codecVersion;
    }
    if (budget != null) {
      if (codec == null ||
          !ChatText.admits(budget, limit: ChatProposalSyncBounds.json)) {
        return InvalidChatMessage.budget;
      }
      try {
        jsonDecode(budget);
      } on FormatException {
        return InvalidChatMessage.budget;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ChatMessageDraft &&
      other.role == role &&
      other.text == text &&
      other.status == status &&
      other.language == language &&
      other.replyToMessageId == replyToMessageId &&
      other.codecVersion == codecVersion &&
      other.budgetJson == budgetJson;

  @override
  int get hashCode => Object.hash(
    role,
    text,
    status,
    language,
    replyToMessageId,
    codecVersion,
    budgetJson,
  );

  @override
  String toString() => 'ChatMessageDraft(${role.code}, ${status.code})';
}

/// A stored chat message: identity, version, when it was written and its
/// content. Display order is [createdAt], then [id].
final class ChatMessage {
  /// Row [id] at [version], first written at [createdAt] (UTC).
  new({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.draft,
  }) {
    checkUuid(id, 'id');
    checkRowVersion(version);
    if (!createdAt.isUtc) {
      throw ArgumentError.value(createdAt, 'createdAt', 'must be UTC');
    }
  }

  /// Row ID.
  final String id;

  /// Observed version.
  final int version;

  /// When the row was first written, UTC.
  final DateTime createdAt;

  /// The content.
  final ChatMessageDraft draft;

  /// Who wrote it.
  ChatMessageRole get role => draft.role;

  /// What was written.
  String get text => draft.text;

  /// Processing state.
  ChatMessageStatus get status => draft.status;

  /// The tag from the fixed app list, or `null`.
  ChatLanguage? get language => draft.language;

  /// The answered user message.
  String? get replyToMessageId => draft.replyToMessageId;

  /// Budget format version.
  int? get codecVersion => draft.codecVersion;

  /// The shared question budget.
  String? get budgetJson => draft.budgetJson;

  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      other.id == id &&
      other.version == version &&
      other.createdAt == createdAt &&
      other.draft == draft;

  @override
  int get hashCode => Object.hash(id, version, createdAt, draft);

  @override
  String toString() => 'ChatMessage($id@v$version, $draft)';
}
