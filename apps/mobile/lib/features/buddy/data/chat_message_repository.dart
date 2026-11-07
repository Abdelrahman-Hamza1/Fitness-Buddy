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

  /// The newest [limit] live messages, in display order (A66 history).
  Future<List<ChatMessage>> recent(int limit) async {
    final rows =
        await (_db.select(_db.chatMessages)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.desc(t.createdAt),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(limit))
            .get();
    return _read(rows.reversed.toList());
  }

  /// The local turn checkpoint of live user message [id] (A66 D4), or
  /// `null`. User content: never log it.
  Future<String?> checkpointOf(String id) async {
    final query = _db.selectOnly(_db.chatMessages)
      ..addColumns([_db.chatMessages.requestJson])
      ..where(
        _db.chatMessages.id.equals(id) & _db.chatMessages.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    return row?.read(_db.chatMessages.requestJson);
  }

  /// How many user messages wait to be processed (offline or Buddy
  /// unavailable, AI-047), re-emitted on every change.
  Stream<int> watchWaiting() {
    final count = _db.chatMessages.id.count();
    final query = _db.selectOnly(_db.chatMessages)
      ..addColumns([count])
      ..where(
        _db.chatMessages.deletedAt.isNull() &
            _db.chatMessages.role.equals(ChatMessageRole.user.code) &
            _db.chatMessages.status.equals(
              ChatMessageStatus.pendingOffline.code,
            ),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  /// This install's user messages still waiting to be processed (`queued`,
  /// `processing` or `pending_offline`), oldest first, with the device
  /// that wrote them (A66 D12: only own rows are dispatched here).
  Future<List<(ChatMessage, String)>> waiting() async {
    final rows =
        await (_db.select(_db.chatMessages)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.role.equals(ChatMessageRole.user.code) &
                    t.status.isIn([
                      ChatMessageStatus.queued.code,
                      ChatMessageStatus.processing.code,
                      ChatMessageStatus.pendingOffline.code,
                    ]),
              )
              ..orderBy([
                (t) => OrderingTerm(expression: t.createdAt),
                (t) => OrderingTerm(expression: t.id),
              ]))
            .get();
    return [
      for (final row in rows)
        if (_read([row]).firstOrNull case final m?) (m, row.deviceId),
    ];
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
