import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/chat/chat_language.dart';
import 'package:fb_domain/src/chat/chat_message.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
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
  /// New row [id] (a random UUIDv7) with [draft].
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  /// New row ID.
  final String id;

  /// The content.
  final ChatMessageDraft draft;

  /// The first wire rule this op breaks ([id] not a UUIDv7, then
  /// [ChatMessageDraft.validateWire]), or `null`.
  InvalidChatMessage? validate() =>
      isUuidV7(id) ? draft.validateWire() : InvalidChatMessage.id;

  @override
  bool operator ==(Object other) =>
      other is CreateChatMessage && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(CreateChatMessage, id, draft);

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
