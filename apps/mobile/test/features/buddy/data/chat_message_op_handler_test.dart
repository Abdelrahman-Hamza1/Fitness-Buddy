import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

const _canary = 'CANARY-A22-HANDLER حمص 🍎';
const _v5 = '0a1b2c3d-0000-5000-8000-000000000001';

/// The real assistant-row budget `ProposalDraftCodec.encodeMessageBudget`
/// produced for the six-item card (B18 corpus, pinned to the codec by
/// `packages/fb_domain/test/proposals/chat_proposal_sync_vectors_test.dart`).
String _realBudget() {
  final corpus = jsonDecode(
    File(
      '../../contracts/testdata/sync/'
      'chat-proposal-validation-vectors.json',
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  final payload = (corpus['payloads']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .singleWhere((p) => p['id'] == 'codec-six-item-message');
  final row =
      jsonDecode(payload['rawPayload']! as String) as Map<String, Object?>;
  return row['budgetJson']! as String;
}

/// The real applier with only the chat family.
final class ChatHarness {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [ChatMessageOpHandler(db)],
      clock: ManualClock(DateTime.utc(2026, 10, 29, 8, 40)),
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();

  /// Random UUIDv7s, as the app makes them, from a seeded `Random`.
  final UuidV7Generator ids = UuidV7Generator(
    ManualClock(DateTime.utc(2026, 10, 29)),
    Random(7),
  );
  late final ChangeSetApplier<AppDatabase> applier;

  Future<Applied> apply(List<ChangeOp> ops, {Origin? origin}) async {
    final r = await applier.apply(
      ChangeSet(ops, origin: origin ?? Origin.direct),
    );
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  Future<ChangeFailure> reject(List<ChangeOp> ops) async {
    final before = await raw();
    final r = await applier.apply(ChangeSet(ops, origin: Origin.direct));
    expect(await raw(), before, reason: 'rejection changed persisted state');
    if (r is! Rejected) fail('expected Rejected: $r');
    return r.failure;
  }

  Future<ChatMessageRow> row(String id) =>
      (db.select(db.chatMessages)..where((t) => t.id.equals(id))).getSingle();

  Future<String> raw() async => jsonEncode({
    for (final table in ['chat_messages', 'sync_outbox'])
      table: [
        for (final r
            in await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
          r.data,
      ],
  });
}

ChatMessageDraft _user({
  String text = _canary,
  int? codecVersion,
  String? budgetJson,
}) => ChatMessageDraft(
  role: ChatMessageRole.user,
  text: text,
  status: ChatMessageStatus.queued,
  codecVersion: codecVersion,
  budgetJson: budgetJson,
);

ChatMessageDraft _assistant(String replyTo, {String? budgetJson}) =>
    ChatMessageDraft(
      role: ChatMessageRole.assistant,
      text: 'Logged',
      status: ChatMessageStatus.done,
      language: ChatLanguage.english,
      replyToMessageId: replyTo,
      codecVersion: budgetJson == null ? null : 1,
      budgetJson: budgetJson,
    );

void main() {
  // rule: A22 chat-handler-wire-rules
  test('A22 chat message handler rejects invalid wire values without '
      'writing', () async {
    final h = ChatHarness();
    final id = h.ids.next();
    final cases = <ChatMessageOp, String>{
      CreateChatMessage(_v5, _user()): 'chatMessageId',
      CreateChatMessage(id, _user(text: 'x' * 8193)): 'chatMessageText',
      CreateChatMessage(id, _user(text: 'x' * 8191 + '🍎')): 'chatMessageText',
      CreateChatMessage(id, _user(text: 'a\u0000b')): 'chatMessageText',
      CreateChatMessage(id, _user(text: 'a\uD800b')): 'chatMessageText',
      CreateChatMessage(id, _user(text: '\uDC00')): 'chatMessageText',
      CreateChatMessage(id, _user(codecVersion: 1, budgetJson: '{}')):
          'chatMessageUserBudget',
      CreateChatMessage(id, _assistant(id, budgetJson: '"${'x' * 32767}"')):
          'chatMessageBudget',
      CreateChatMessage(
        id,
        const ChatMessageDraft(
          role: ChatMessageRole.assistant,
          text: 'Logged',
          status: ChatMessageStatus.done,
          replyToMessageId: 'NOT-A-UUID',
        ),
      ): 'chatMessageReplyTo',
    };
    for (final MapEntry(key: op, :value) in cases.entries) {
      // Valid first op: the whole change set rolls back.
      final failure = await h.reject([
        CreateChatMessage(h.ids.next(), _user()),
        op,
      ]);
      expect(failure, InvalidOp(value), reason: value);
      expect('$failure', isNot(contains('CANARY')));
    }
    // The 32768-unit budget and 8192-unit text are the largest admitted.
    await h.apply([
      CreateChatMessage(id, _user(text: 'x' * 8190 + '🍎')),
      CreateChatMessage(
        h.ids.next(),
        _assistant(id, budgetJson: '"${'x' * 32766}"'),
      ),
    ]);
    expect((await h.row(id)).messageText, 'x' * 8190 + '🍎');
    // Same ID twice is a duplicate, not an overwrite.
    expect(
      await h.reject([CreateChatMessage(id, _user())]),
      const ConstraintViolation('duplicateId'),
    );
  });

  // rule: A22 assistant-budget-owner
  test(
    'A22 assistant message alone stores the shared question budget',
    () async {
      final h = ChatHarness();
      final user = h.ids.next();
      final assistant = h.ids.next();
      final budget = _realBudget();
      await h.apply([CreateChatMessage(user, _user())]);
      final reply = await h.apply([
        SetChatMessageStatus(
          user,
          1,
          ChatMessageStatus.done,
          language: ChatLanguage.arabizi,
        ),
        CreateChatMessage(assistant, _assistant(user, budgetJson: budget)),
      ], origin: Origin.system);
      expect(reply.events, isNotEmpty);
      final userRow = await h.row(user);
      final assistantRow = await h.row(assistant);
      expect(userRow.codecVersion, isNull);
      expect(userRow.budgetJson, isNull);
      expect(userRow.status, 'done');
      expect(userRow.language, 'ar-Latn');
      expect(userRow.version, 2);
      expect(assistantRow.budgetJson, budget);
      expect(assistantRow.codecVersion, 1);
      expect(assistantRow.replyToMessageId, user);
      expect(assistantRow.language, 'en');
      expect(assistantRow.origin, 'system');
      expect(
        ProposalDraftCodec.messageFromSync(assistantRow.budgetJson).issue,
        isNull,
      );
      // No other copy anywhere in the database.
      final copies = await h.db
          .customSelect(
            'SELECT COUNT(*) AS n FROM chat_messages '
            'WHERE budget_json IS NOT NULL',
          )
          .getSingle();
      expect(copies.read<int>('n'), 1);
      // A user row never takes one.
      expect(
        await h.reject([
          CreateChatMessage(
            h.ids.next(),
            _user(codecVersion: 1, budgetJson: budget),
          ),
        ]),
        const InvalidOp('chatMessageUserBudget'),
      );
    },
  );

  // rule: A22 chat-status
  test('A22 chat message status changes check the version and keep the '
      'language', () async {
    final h = ChatHarness();
    final id = h.ids.next();
    final created = await h.apply([CreateChatMessage(id, _user())]);
    final row = await h.row(id);
    expect(row.messageText, _canary);
    expect(row.role, 'user');
    expect(row.status, 'queued');
    expect(row.language, isNull);
    expect(row.origin, 'direct');
    expect(row.version, 1);
    expect(created.inverse.rows, hasLength(1));
    expect(await outbox(h.db), [('chatMessage', id, row.updatedHlc, false)]);

    // Same status, no language: nothing written.
    final same = await h.apply([
      SetChatMessageStatus(id, 1, ChatMessageStatus.queued),
    ]);
    expect(same.inverse.isEmpty, isTrue);
    expect((await h.row(id)).version, 1);

    await h.apply([
      SetChatMessageStatus(
        id,
        1,
        ChatMessageStatus.done,
        language: ChatLanguage.arabic,
      ),
    ]);
    // A later change without a language keeps the stored one.
    await h.apply([SetChatMessageStatus(id, 2, ChatMessageStatus.failed)]);
    final after = await h.row(id);
    expect(after.status, 'failed');
    expect(after.language, 'ar');
    expect(after.version, 3);
    expect(after.messageText, _canary);

    expect(
      await h.reject([SetChatMessageStatus(id, 1, ChatMessageStatus.done)]),
      VersionConflict(entity: 'chatMessage', id: id, expected: 1, actual: 3),
    );
    final missing = h.ids.next();
    expect(
      await h.reject([
        SetChatMessageStatus(missing, 1, ChatMessageStatus.done),
      ]),
      RowNotFound(entity: 'chatMessage', id: missing),
    );
  });

  // rule: A22 chat-repository
  test('A22 chat message repository watches messages by id in display '
      'order', () async {
    final h = ChatHarness();
    final repo = ChatMessageRepository(h.db);
    expect(await repo.watchByIds(const []).first, isEmpty);
    final first = h.ids.next();
    final second = h.ids.next();
    final stream = repo.watchByIds([second, first]);
    final seen = <List<String>>[];
    final sub = stream.listen((m) => seen.add([for (final x in m) x.id]));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await h.apply([
      CreateChatMessage(first, _user()),
      CreateChatMessage(second, _assistant(first)),
    ]);
    await pumpEventQueue();
    expect(seen.last, [first, second]);
    final message = (await repo.byId(first))!;
    expect(message.text, _canary);
    expect(message.role, ChatMessageRole.user);
    expect(message.createdAt, DateTime.utc(2026, 10, 29, 8, 40));
    expect(await repo.byId(h.ids.next()), isNull);
    // Tombstoned and unreadable rows are left out.
    await runAuthorizedWrite(
      () => h.db.customStatement(
        'UPDATE chat_messages SET deleted_at = 1 WHERE id = ?',
        [second],
      ),
    );
    expect(await repo.byId(second), isNull);
    await runAuthorizedWrite(
      () => h.db.customStatement(
        "UPDATE chat_messages SET id = 'not-a-uuid' WHERE id = ?",
        [first],
      ),
    );
    expect(await repo.byId('not-a-uuid'), isNull);
  });
}
