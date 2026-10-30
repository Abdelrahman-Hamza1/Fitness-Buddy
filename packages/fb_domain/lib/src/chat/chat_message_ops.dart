import 'dart:convert' show jsonDecode, utf8;

import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/chat/chat_language.dart';
import 'package:fb_domain/src/chat/chat_message.dart';
import 'package:fb_domain/src/chat/chat_text.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/proposals/proposal_policy_constants.dart';
import 'package:fb_domain/src/proposals/proposal_sync_codes.dart';

/// Chat-message writes (A22 D5). A23 extends this family (budget updates,
/// clearing history) instead of adding a second writer.
///
/// Saving a message is the one user-data write without undo: it is a
/// transcript entry, not diary data, and the user removes it by clearing the
/// chat history (AC-033).
sealed class ChatMessageOp implements ChangeOp {
  const new _();

  /// The stable handler family.
  static const familyName = 'chatMessage';

  @override
  String get family => familyName;
}

/// Saves a new message. The handler checks [validate] in the transaction.
final class CreateChatMessage extends ChatMessageOp {
  /// New row [id] (a random UUIDv7) with [draft]; an assistant row may keep
  /// the raw interpret [answerJson] locally (A23 D14).
  new(this.id, this.draft, {this.answerJson}) : super._() {
    checkUuid(id, 'id');
  }

  /// New row ID.
  final String id;

  /// The content.
  final ChatMessageDraft draft;

  /// The raw interpret answer a card can be rebuilt from offline (A23 D14):
  /// local-only, never synced or logged. Assistant rows only.
  final String? answerJson;

  /// The first wire rule this op breaks ([id] not a UUIDv7, then
  /// [ChatMessageDraft.validateWire], then the local [answerJson]), or
  /// `null`.
  InvalidChatMessage? validate() {
    if (!isUuidV7(id)) return InvalidChatMessage.id;
    if (draft.validateWire() case final invalid?) return invalid;
    if (answerJson case final answer?
        when draft.role != ChatMessageRole.assistant ||
            !isLocalJsonObject(answer)) {
      return InvalidChatMessage.answer;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CreateChatMessage &&
      other.id == id &&
      other.draft == draft &&
      other.answerJson == answerJson;

  @override
  int get hashCode => Object.hash(CreateChatMessage, id, draft, answerJson);

  @override
  String toString() => 'CreateChatMessage($id, $draft)';
}

/// Moves message [id] to [status]; sets its [language] when one is given
/// (a language is learnt from the reply, never cleared). Writes nothing when
/// both already hold.
final class SetChatMessageStatus extends ChatMessageOp {
  /// [id] at [expectedVersion] (the shown version) to [status].
  new(this.id, this.expectedVersion, this.status, {this.language}) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
  }

  /// Row ID.
  final String id;

  /// The version the row must have.
  final int expectedVersion;

  /// The new state.
  final ChatMessageStatus status;

  /// The language to set, or `null` to keep the stored one.
  final ChatLanguage? language;

  @override
  bool operator ==(Object other) =>
      other is SetChatMessageStatus &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.status == status &&
      other.language == language;

  @override
  int get hashCode =>
      Object.hash(SetChatMessageStatus, id, expectedVersion, status, language);

  @override
  String toString() =>
      'SetChatMessageStatus($id@v$expectedVersion, ${status.code})';
}

/// Sets assistant message [id]'s shared question budget (A23 D5, D6): the
/// only producer is the app's proposal session writer. The row must be a
/// live assistant row (`proposalMessageMissing`); a budget whose codec
/// `revision` is lower than the stored one is rejected (`proposalStale`,
/// equal allowed). [clearAnswer] nulls the local interpret answer once no
/// card of the message is pending (A23 D14).
final class SetChatMessageBudget extends ChatMessageOp {
  /// [id]'s budget [budgetJson] at [codecVersion].
  new(this.id, this.codecVersion, this.budgetJson, {this.clearAnswer = false})
    : super._() {
    checkUuid(id, 'id');
  }

  /// Row ID.
  final String id;

  /// Budget format version.
  final int codecVersion;

  /// The budget (`ProposalDraftCodec.encodeMessageBudget`).
  final String budgetJson;

  /// Whether to null the stored interpret answer.
  final bool clearAnswer;

  /// The first wire rule this op breaks, or `null`: [codecVersion] in
  /// 1…2147483647 and [budgetJson] JSON within 32768 UTF-16 units, without
  /// U+0000 or unpaired surrogates.
  InvalidChatMessage? validate() {
    if (codecVersion < ChatProposalSyncBounds.codecVersionMin ||
        codecVersion > ChatProposalSyncBounds.codecVersionMax) {
      return InvalidChatMessage.codecVersion;
    }
    if (!ChatText.admits(budgetJson, limit: ChatProposalSyncBounds.json)) {
      return InvalidChatMessage.budget;
    }
    try {
      jsonDecode(budgetJson);
    } on FormatException {
      return InvalidChatMessage.budget;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is SetChatMessageBudget &&
      other.id == id &&
      other.codecVersion == codecVersion &&
      other.budgetJson == budgetJson &&
      other.clearAnswer == clearAnswer;

  @override
  int get hashCode => Object.hash(
    SetChatMessageBudget,
    id,
    codecVersion,
    budgetJson,
    clearAnswer,
  );

  @override
  String toString() => 'SetChatMessageBudget($id, v$codecVersion)';
}

/// Clears assistant message [id]'s local interpret answer once no live
/// pending card is bound to it any more (A23 D14, TD-102): the handler
/// counts in the transaction, after the change set's earlier ops, so it
/// needs no readable budget. Writes nothing otherwise.
final class ReleaseChatMessageAnswer extends ChatMessageOp {
  /// Release message [id]'s answer when it's settled.
  new(this.id) : super._() {
    checkUuid(id, 'id');
  }

  /// Row ID.
  final String id;

  @override
  bool operator ==(Object other) =>
      other is ReleaseChatMessageAnswer && other.id == id;

  @override
  int get hashCode => Object.hash(ReleaseChatMessageAnswer, id);

  @override
  String toString() => 'ReleaseChatMessageAnswer($id)';
}

/// Whether [json] is a well-formed JSON object within the local input bound
/// ([ProposalPolicyConstants.maxInputBytes] UTF-8 bytes): the rule for the
/// local-only JSON columns (A23 D5).
bool isLocalJsonObject(String json) {
  if (!ChatText.isWellFormed(json) ||
      json.length > ProposalPolicyConstants.maxInputBytes ||
      utf8.encode(json).length > ProposalPolicyConstants.maxInputBytes) {
    return false;
  }
  try {
    return jsonDecode(json) is Map<String, Object?>;
  } on FormatException {
    return false;
  }
}
