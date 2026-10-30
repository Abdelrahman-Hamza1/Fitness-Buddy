import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_mappers.dart';
import 'package:fb_mobile/features/buddy/data/proposal_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

const _corpus =
    '../../contracts/testdata/sync/chat-proposal-validation-vectors.json';
const _contract = '../../contracts/openapi/sync-entities.json';
const _deletedAt = 1792843200000;

String _rowId(int n) =>
    '019a1b2c-0000-7000-8000-${n.toString().padLeft(12, '0')}';

/// Stands in for a raw payload that isn't JSON at all.
const _notJson = Object();

ProposalRow _read(Object? payload, int n, {required bool deleted}) =>
    proposalRowOfSync(
      payload,
      id: _rowId(n),
      updatedHlc: hlcAt(1),
      version: 1,
      deviceId: testDevice,
      deletedAtMs: deleted ? _deletedAt : null,
    );

bool _scrubbed(Map<String, Object?> payload) =>
    payload['draftJson'] == scrubbedProposalDraft &&
    payload['interpretationJson'] == null;

void main() {
  final vectors =
      jsonDecode(File(_corpus).readAsStringSync()) as Map<String, Object?>;
  final proposals = [
    for (final p
        in (vectors['payloads']! as List<Object?>).cast<Map<String, Object?>>())
      if (p['entity'] == 'proposal') p,
  ];
  final asymmetric = (vectors['serverRejectsAppTolerates']! as List<Object?>)
      .toSet();

  // rule: A23 proposal-sync-corpus
  test('A23 proposal row mapper matches the sync corpus in both '
      'directions', () async {
    final contract =
        ((jsonDecode(File(_contract).readAsStringSync())
                    as Map<String, Object?>)['entities']!
                as Map<String, Object?>)['proposal']!
            as Map<String, Object?>;
    final schema = contract['1']! as Map<String, Object?>;
    expect(
      (schema['properties']! as Map<String, Object?>).keys.toList(),
      proposalSyncKeys,
    );
    expect(schema['required'], proposalSyncKeys);

    final db = memoryDatabase();
    var stored = 0;
    var rejected = 0;
    var parked = 0;
    var tombstones = 0;
    var restorable = 0;
    for (final (n, p) in proposals.indexed) {
      final id = p['id']! as String;
      final accepted = p['serverAccepts']! as bool;
      final deleted = p['deleted']! as bool;
      Object? payload;
      try {
        payload = jsonDecode(p['rawPayload']! as String);
      } on FormatException {
        payload = _notJson;
      }
      if (p['appReads'] != true) {
        expect(accepted, isFalse, reason: id);
        expect(
          () => _read(payload, n, deleted: deleted),
          throwsA(isA<ProposalMappingError>()),
          reason: id,
        );
        rejected++;
        continue;
      }
      final original = payload! as Map<String, Object?>;
      final row = _read(payload, n, deleted: deleted);
      if (!accepted) {
        // Read, but never pushed back: a typed error.
        expect(asymmetric, contains(id));
        expect(
          () => proposalToSync(row),
          throwsA(isA<ProposalMappingError>()),
          reason: id,
        );
        parked++;
        continue;
      }
      if (deleted && !_scrubbed(original)) {
        expect(
          () => proposalToSync(row),
          throwsA(ProposalMappingError.unscrubbedTombstone),
          reason: id,
        );
        tombstones++;
      } else {
        final back = proposalToSync(row);
        expect(back.keys.toList(), proposalSyncKeys, reason: id);
        // Value-exact (a whole `1.0` comes back as `1`) and UTF-16 exact.
        expect(back, original, reason: id);
        expect(back['createdAtMs'], isA<int>(), reason: id);
        expect(back['codecVersion'], isA<int>(), reason: id);
        for (final key in ['kind', 'origin', 'interpretationJson']) {
          if (original[key] case final String text) {
            expect(
              (back[key]! as String).codeUnits,
              text.codeUnits,
              reason: id,
            );
          }
        }
        expect(
          (back['draftJson']! as String).codeUnits,
          (original['draftJson']! as String).codeUnits,
          reason: id,
        );
      }
      // Everything the server admits is storable here, exactly.
      await runAuthorizedWrite(() => db.into(db.proposals).insert(row));
      final again = await (db.select(
        db.proposals,
      )..where((t) => t.id.equals(row.id))).getSingle();
      expect(again, row, reason: id);
      stored++;
      // Codec rows restore through the sync inverse, with the top-level
      // fields authoritative over the draft's copies.
      if (p['source'] == 'codec' && !deleted) {
        final record = proposalRecordOf(again);
        final card = proposalRestoreCard(record);
        expect(card.issue, isNull, reason: id);
        expect(card.value!['status'], record.status.code, reason: id);
        expect(card.value!['id'], record.id, reason: id);
        expect(card.value!['codecVersion'], ProposalDraftCodec.version);
        expect(card.value!['budgetMessageId'], record.budgetMessageId);
        restorable++;
      }
    }
    expect(stored + rejected + parked, proposals.length);
    expect(stored, greaterThan(40));
    expect(rejected, greaterThan(20));
    expect(parked, greaterThan(10));
    expect(tombstones, 1);
    // The two codecServerRejects cards are parked, never pushed.
    expect(restorable, 9);

    // Constants and closed codes are the app's own.
    expect(vectors['constants'], {
      'json': ChatProposalSyncBounds.json,
      'text': ChatProposalSyncBounds.text,
      'language': ChatProposalSyncBounds.language,
      'kind': ChatProposalSyncBounds.kind,
      'origin': ChatProposalSyncBounds.origin,
      'codecVersionMin': ChatProposalSyncBounds.codecVersionMin,
      'codecVersionMax': ChatProposalSyncBounds.codecVersionMax,
    });
    final vocab = vectors['vocabularies']! as Map<String, Object?>;
    expect(vocab['proposalStatus'], [
      for (final s in ProposalStatus.values) s.code,
    ]);
    expect(vocab['proposalOutcome'], [
      for (final o in ProposalOutcome.values) o.code,
    ]);
    // Mapping errors never echo content.
    for (final error in ProposalMappingError.values) {
      expect('$error', 'ProposalMappingError.${error.name}');
    }
  });

  // rule: A23 tombstone-scrub-owner
  test('A23 mapper refuses an unscrubbed tombstone', () {
    final live = _read(
      jsonDecode(
        proposals.singleWhere((p) => p['id'] == 'proposal-base')['rawPayload']!
            as String,
      ),
      1,
      deleted: false,
    );
    final canary = live.copyWith(draftJson: '{"note":"CANARY-A23-TOMB"}');
    final unscrubbed = [
      canary.copyWith(deletedAt: const Value(_deletedAt)),
      live.copyWith(
        deletedAt: const Value(_deletedAt),
        draftJson: scrubbedProposalDraft,
        interpretationJson: const Value('[]'),
      ),
    ];
    for (final row in unscrubbed) {
      expect(
        () => proposalToSync(row),
        throwsA(
          isA<ProposalMappingError>()
              .having(
                (e) => e,
                'error',
                ProposalMappingError.unscrubbedTombstone,
              )
              .having((e) => '$e', 'text', isNot(contains('CANARY'))),
        ),
      );
    }
    final scrubbed = live.copyWith(
      deletedAt: const Value(_deletedAt),
      draftJson: scrubbedProposalDraft,
      interpretationJson: const Value(null),
    );
    expect(proposalToSync(scrubbed)['draftJson'], '{}');
    expect(proposalToSync(scrubbed)['interpretationJson'], isNull);
    // A live row is projected as stored.
    expect(proposalToSync(canary)['draftJson'], contains('CANARY'));

    // The chat mapper owns the same rule for its tombstones.
    final chat = chatMessageRowOfSync(
      {
        'createdAtMs': 0,
        'origin': 'system',
        'editedByUser': false,
        'role': 'assistant',
        'text': 'CANARY-A23-CHAT',
        'status': 'done',
        'language': 'en',
        'replyToMessageId': null,
        'codecVersion': 1,
        'budgetJson': '{}',
      },
      id: _rowId(2),
      updatedHlc: hlcAt(1),
      version: 1,
      deviceId: testDevice,
      deletedAtMs: _deletedAt,
    );
    expect(
      () => chatMessageSyncPayload(chat),
      throwsA(isA<ChatMessageMappingError>()),
    );
    final cleared = chat.copyWith(
      messageText: '',
      budgetJson: const Value(null),
      codecVersion: const Value(null),
    );
    expect(chatMessageSyncPayload(cleared)['text'], '');
  });
}
