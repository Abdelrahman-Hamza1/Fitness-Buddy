import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

const _id = '019a1b2c-0000-7000-8000-000000000001';
const _reply = '019a1b2c-0000-7000-8000-000000000002';
const _canary = 'CANARY-A22-MAPPER';

Map<String, Object?> _payload([Map<String, Object?> changes = const {}]) => {
  'createdAtMs': 1792843200000,
  'origin': 'system',
  'editedByUser': false,
  'role': 'assistant',
  'text': _canary,
  'status': 'done',
  'language': 'en',
  'replyToMessageId': _reply,
  'codecVersion': 1,
  'budgetJson': '{}',
  ...changes,
};

ChatMessageRow _row(Map<String, Object?> payload) => chatMessageRowOfSync(
  payload,
  id: _id,
  updatedHlc: hlcAt(1),
  version: 3,
  deviceId: testDevice,
);

void main() {
  // rule: A22 chat-sync-allowlist
  test('A22 chatMessage sync omits local attachment paths', () {
    final contract = jsonDecode(
      File('../../contracts/openapi/sync-entities.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final schema =
        ((contract['entities']! as Map<String, Object?>)['chatMessage']!
                as Map<String, Object?>)['1']!
            as Map<String, Object?>;
    expect(
      (schema['properties']! as Map<String, Object?>).keys.toList(),
      chatMessageSyncKeys,
    );
    expect(schema['required'], chatMessageSyncKeys);

    // Outbound: exactly the contract keys, whatever the table holds.
    final payload = chatMessageSyncPayload(_row(_payload()));
    expect(payload.keys.toList(), chatMessageSyncKeys);
    expect(payload, _payload());
    final db = memoryDatabase();
    final local = {
      for (final c in db.chatMessages.$columns)
        if (!syncColumnNames.contains(c.name)) c.name,
    };
    expect(local, {
      'role',
      'message_text',
      'status',
      'language',
      'reply_to_message_id',
      'codec_version',
      'budget_json',
      // Local-only (TD-102, A23): never synced, see the A23 test below.
      'request_json',
      'answer_json',
    });

    // Inbound: attachment fields and other extras are rejected.
    for (final extra in ['attachmentRefs', 'attachmentsJson', 'localPath']) {
      expect(
        () => _row(_payload({extra: '/data/user/0/photo.jpg'})),
        throwsA(isA<ChatMessageMappingError>()),
        reason: extra,
      );
    }
    final missing = _payload()..remove('budgetJson');
    expect(() => _row(missing), throwsA(isA<ChatMessageMappingError>()));

    // Integers read as num → int.
    final whole = _row(_payload({'codecVersion': 1.0, 'createdAtMs': 5.0}));
    expect(whole.codecVersion, 1);
    expect(whole.createdAt, 5);
    expect(chatMessageSyncPayload(whole)['codecVersion'], isA<int>());
    for (final bad in <Map<String, Object?>>[
      {'codecVersion': 1.5},
      {'codecVersion': '1'},
      {'codecVersion': 0},
      {'createdAtMs': -1},
      {'createdAtMs': 9007199254740992},
      {'editedByUser': 0},
      {'role': 'system'},
      {'status': 'pending'},
      {'replyToMessageId': _reply.toUpperCase()},
      {'budgetJson': '{"a":'},
      {'text': 'x' * 8193},
      {'language': 'x' * 17},
      {'origin': null},
    ]) {
      expect(
        () => _row(_payload(bad)),
        throwsA(isA<ChatMessageMappingError>()),
        reason: '$bad',
      );
    }
    expect(() => _row(const {}), throwsA(isA<ChatMessageMappingError>()));
    expect(
      () => chatMessageRowOfSync(
        'not a map',
        id: _id,
        updatedHlc: hlcAt(1),
        version: 1,
        deviceId: testDevice,
      ),
      throwsA(isA<ChatMessageMappingError>()),
    );
  });

  // rule: A22 chat-row-mapper
  test('A22 chat message rows map to domain messages without echoing '
      'content', () {
    final message = chatMessageOf(_row(_payload()));
    expect(message.id, _id);
    expect(message.version, 3);
    expect(message.createdAt, DateTime.utc(2026, 10, 24, 12));
    expect(message.role, ChatMessageRole.assistant);
    expect(message.status, ChatMessageStatus.done);
    expect(message.language, ChatLanguage.english);
    expect(message.replyToMessageId, _reply);
    expect(message.codecVersion, 1);
    expect(message.budgetJson, '{}');
    expect(message.text, _canary);
    // A synced row may hold any short tag; only the app list reads.
    expect(chatMessageOf(_row(_payload({'language': 'fr'}))).language, isNull);
    final row = _row(_payload());
    for (final broken in [
      row.copyWith(role: 'system'),
      row.copyWith(status: 'sent'),
      row.copyWith(id: 'not-a-uuid'),
      row.copyWith(version: 0),
    ]) {
      expect(
        () => chatMessageOf(broken),
        throwsA(
          isA<ChatMessageMappingError>().having(
            (e) => '$e',
            'toString',
            isNot(contains(_canary)),
          ),
        ),
      );
    }
    // Columns for a new row carry the draft and its id only.
    final columns = chatMessageColumns(
      _id,
      const ChatMessageDraft(
        role: ChatMessageRole.user,
        text: _canary,
        status: ChatMessageStatus.queued,
      ),
    );
    expect(columns.id.value, _id);
    expect(columns.role.value, 'user');
    expect(columns.messageText.value, _canary);
    expect(columns.status.value, 'queued');
    expect(columns.language.value, isNull);
    expect(columns.codecVersion.value, isNull);
    expect(columns.budgetJson.value, isNull);
    expect(columns.version.present, isFalse);
    expect(columns.origin.present, isFalse);
  });

  // rule: A23 local-columns
  test('A23 chatMessage sync omits the local request and answer columns', () {
    const request = '{"text":"CANARY-A23-REQUEST"}';
    const answer = '{"intents":["CANARY-A23-ANSWER"]}';
    final row = _row(_payload()).copyWith(
      requestJson: const Value(request),
      answerJson: const Value(answer),
    );
    final payload = chatMessageSyncPayload(row);
    expect(payload.keys.toList(), chatMessageSyncKeys);
    expect(jsonEncode(payload), isNot(contains('CANARY-A23')));
    expect(payload.keys, isNot(contains('requestJson')));
    expect(payload.keys, isNot(contains('answerJson')));
    // Inbound: the local columns aren't wire fields, so a payload naming
    // them is rejected and a pulled row never sets them.
    for (final extra in ['requestJson', 'answerJson']) {
      expect(
        () => _row(_payload({extra: '{}'})),
        throwsA(isA<ChatMessageMappingError>()),
        reason: extra,
      );
    }
    final pulled = _row(_payload());
    expect(pulled.requestJson, isNull);
    expect(pulled.answerJson, isNull);
    // The new-row columns carry the local answer only when given.
    final columns = chatMessageColumns(
      _id,
      chatMessageOf(pulled).draft,
      answerJson: answer,
    );
    expect(columns.answerJson.value, answer);
    expect(columns.requestJson.present, isFalse);
  });
}
