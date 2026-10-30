import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_mappers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_message_repository.g.dart';

/// Read-only chat-message queries (A22 D11). Writes go through
/// `ChangeSetApplier` with `ChatMessageOp`s.
final class ChatMessageRepository {
  /// One profile's database.
  const new(this._db);

  final AppDatabase _db;

  /// The live messages among [ids], in display order (`createdAt`, then
  /// `id`), re-emitted on every change. Rows that can't be read are skipped.
  Stream<List<ChatMessage>> watchByIds(Iterable<String> ids) {
    final wanted = ids.toSet();
    if (wanted.isEmpty) return Stream.value(const []);
    return _byIds(wanted).watch().map(_read);
  }

  /// The live message [id], or `null`.
  Future<ChatMessage?> byId(String id) async =>
      _read(await _byIds({id}).get()).firstOrNull;

  /// The local-only interpret answer of live assistant message [id]
  /// (A23 D14), or `null` once it was cleared or for any other row. User
  /// content: never log it.
  Future<String?> answerOf(String id) async {
    final query = _db.selectOnly(_db.chatMessages)
      ..addColumns([_db.chatMessages.answerJson])
      ..where(
        _db.chatMessages.id.equals(id) & _db.chatMessages.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    return row?.read(_db.chatMessages.answerJson);
  }

  SimpleSelectStatement<$ChatMessagesTable, ChatMessageRow> _byIds(
    Set<String> ids,
  ) => _db.select(_db.chatMessages)
    ..where((t) => t.id.isIn(ids) & t.deletedAt.isNull())
    ..orderBy([
      (t) => OrderingTerm(expression: t.createdAt),
      (t) => OrderingTerm(expression: t.id),
    ]);

  List<ChatMessage> _read(List<ChatMessageRow> rows) {
    final messages = <ChatMessage>[];
    for (final row in rows) {
      try {
        messages.add(chatMessageOf(row));
      } on ChatMessageMappingError {
        // Unreadable rows are skipped; the error is content-free.
      }
    }
    return messages;
  }
}

/// Read-only repository composition stays in data (application-db rule).
@Riverpod(keepAlive: true)
ChatMessageRepository chatMessageRepository(Ref ref) =>
    ChatMessageRepository(ref.watch(appDatabaseProvider));
