import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_mappers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../../core/db/support/db_support.dart';

const _corpus =
    '../../contracts/testdata/sync/chat-proposal-validation-vectors.json';

String _rowId(int n) =>
    '019a1b2c-0000-7000-8000-${n.toString().padLeft(12, '0')}';

/// Stands in for a raw payload that isn't JSON at all.
const _notJson = Object();

ChatMessageRow _read(Object? payload, int n, {required bool deleted}) =>
    chatMessageRowOfSync(
      payload,
      id: _rowId(n),
      updatedHlc: hlcAt(1),
      version: 1,
      deviceId: testDevice,
      deletedAtMs: deleted ? 1792843200000 : null,
    );

void main() {
  final vectors =
      jsonDecode(File(_corpus).readAsStringSync()) as Map<String, Object?>;
  final chat = [
    for (final p
        in (vectors['payloads']! as List<Object?>).cast<Map<String, Object?>>())
      if (p['entity'] == 'chatMessage') p,
  ];

  // rule: A22 chat-sync-corpus
  test('A22 chat message row mapper matches the sync corpus in both '
      'directions', () async {
    final db = memoryDatabase();
    var read = 0;
    var stored = 0;
    var rejected = 0;
    for (final (n, p) in chat.indexed) {
      final id = p['id']! as String;
      final accepted = p['serverAccepts']! as bool;
      final deleted = p['deleted']! as bool;
      Object? payload;
      try {
        payload = jsonDecode(p['rawPayload']! as String);
      } on FormatException {
        payload = _notJson;
      }
      if (accepted) expect(p['appReads'], isTrue, reason: id);
      if (p['appReads'] != true) {
        expect(accepted, isFalse, reason: id);
        expect(
          () => _read(payload, n, deleted: deleted),
          throwsA(isA<ChatMessageMappingError>()),
          reason: id,
        );
        rejected++;
        continue;
      }
      final original = payload! as Map<String, Object?>;
      final row = _read(payload, n, deleted: deleted);
      final back = chatMessageSyncPayload(row);
      expect(back.keys.toList(), chatMessageSyncKeys, reason: id);
      // Value-exact (a whole `1.0` comes back as the integer `1`) and
      // UTF-16 exact.
      expect(back, original, reason: id);
      expect(back['createdAtMs'], isA<int>(), reason: id);
      if (back['codecVersion'] != null) {
        expect(back['codecVersion'], isA<int>(), reason: id);
      }
      for (final key in ['text', 'origin', 'language', 'budgetJson']) {
        if (original[key] case final String text) {
          expect((back[key]! as String).codeUnits, text.codeUnits, reason: id);
        }
      }
      // The budget always goes through the codec's sync inverse: a value or
      // a fixed issue, never a throw.
      final budget = ProposalDraftCodec.messageFromSync(row.budgetJson);
      expect((budget.value == null) != (budget.issue == null), isTrue);
      if (accepted) {
        // Everything the server admits is storable here, exactly.
        await runAuthorizedWrite(() => db.into(db.chatMessages).insert(row));
        final again = await (db.select(
          db.chatMessages,
        )..where((t) => t.id.equals(row.id))).getSingle();
        expect(again, row, reason: id);
        expect(chatMessageSyncPayload(again), original, reason: id);
        stored++;
      }
      read++;
    }
    expect(read + rejected, chat.length);
    expect(stored, greaterThan(40));
    expect(rejected, greaterThan(20));

    // The asymmetric list is exactly the readable rows the server rejects.
    final asymmetric = {
      for (final p in chat)
        if (p['serverAccepts'] == false && p['appReads'] == true) p['id'],
    };
    expect(
      (vectors['serverRejectsAppTolerates']! as List<Object?>)
          .where((id) => '$id'.startsWith('chat-'))
          .toSet(),
      asymmetric,
    );

    // Constants and closed codes are the app's own.
    final constants = vectors['constants']! as Map<String, Object?>;
    expect(constants, {
      'json': ChatProposalSyncBounds.json,
      'text': ChatProposalSyncBounds.text,
      'language': ChatProposalSyncBounds.language,
      'kind': ChatProposalSyncBounds.kind,
      'origin': ChatProposalSyncBounds.origin,
      'codecVersionMin': ChatProposalSyncBounds.codecVersionMin,
      'codecVersionMax': ChatProposalSyncBounds.codecVersionMax,
    });
    final vocab = vectors['vocabularies']! as Map<String, Object?>;
    expect(vocab['chatMessageRole'], [
      for (final r in ChatMessageRole.values) r.code,
    ]);
    expect(vocab['chatMessageStatus'], [
      for (final s in ChatMessageStatus.values) s.code,
    ]);
    // The table's CHECKs admit exactly those codes.
    for (final (column, code) in [('role', 'system'), ('status', 'sent')]) {
      await expectLater(
        runAuthorizedWrite(
          () => db.customStatement(
            'INSERT INTO chat_messages (id, created_at, updated_hlc, version, '
            'device_id, origin, edited_by_user, role, message_text, status) '
            "VALUES (?, 0, ?, 1, ?, 'system', 0, ?, '', ?)",
            [
              _rowId(9999),
              hlcAt(1),
              testDevice,
              if (column == 'role') code else 'user',
              if (column == 'status') code else 'done',
            ],
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    }
  });
}
