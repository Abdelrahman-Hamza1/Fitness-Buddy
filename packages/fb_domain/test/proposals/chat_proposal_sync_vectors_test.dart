import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../../tool/generate_chat_proposal_vectors.dart';
import 'proposal_fixtures.dart';

const _corpus = 'contracts/testdata/sync/chat-proposal-validation-vectors.json';
const _contract = 'contracts/openapi/sync-entities.json';

File _repoFile(String path) {
  final local = File(path);
  return local.existsSync() ? local : File('../../$path');
}

Map<String, Object?> _object(Object? value) => value! as Map<String, Object?>;

final Map<String, Object?> _vectors = _object(
  jsonDecode(_repoFile(_corpus).readAsStringSync()),
);
final List<Map<String, Object?>> _payloads = [
  for (final p in _vectors['payloads']! as List<Object?>) _object(p),
];
final Map<String, Map<String, Object?>> _byId = {
  for (final p in _payloads) p['id']! as String: p,
};

Map<String, Object?> _raw(String id) =>
    _object(jsonDecode(_byId[id]!['rawPayload']! as String));

final Map<String, Object?> _contractEntities = _object(
  _object(jsonDecode(_repoFile(_contract).readAsStringSync()))['entities'],
);

Map<String, Map<String, Object?>> _schema(String entity) =>
    _object(_object(_object(_contractEntities[entity])['1'])['properties'])
        .map((k, v) => MapEntry(k, _object(v)));

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// What a Dart reader of the v1 sync fields accepts: the contract's field
/// set, types, UTF-16 bounds, ranges and UUID shape, the closed codes through
/// the fb_domain enums, and JSON fields that decode. The generic nested pass
/// (surrogates, U+0000, depth, width, duplicate keys, decimal numbers) is
/// server-only, which is exactly the asymmetry the corpus lists.
bool _dartReads(String entity, String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return false;
  }
  if (decoded is! Map<String, Object?>) return false;
  final schema = _schema(entity);
  if (decoded.length != schema.length ||
      !schema.keys.every(decoded.containsKey)) {
    return false;
  }
  for (final MapEntry(key: field, value: rule) in schema.entries) {
    final value = decoded[field];
    final types = rule['type'] is List ? rule['type']! as List : [rule['type']];
    if (value == null) {
      if (!types.contains('null')) return false;
      continue;
    }
    switch (value) {
      case bool() when types.contains('boolean'):
        break;
      case num() when types.contains('integer') && value == value.truncate():
        final min = rule['minimum'] as num?;
        final max = rule['maximum'] as num?;
        if (min != null && value < min || max != null && value > max) {
          return false;
        }
      case String() when types.contains('string'):
        final max = rule['maxLength'] as int?;
        if (max != null && value.length > max) return false;
        if (rule['format'] == 'uuid' && !_uuid.hasMatch(value)) return false;
        final closed = switch ((entity, field)) {
          ('chatMessage', 'role') => ChatMessageRole.fromCode(value) != null,
          ('chatMessage', 'status') =>
            ChatMessageStatus.fromCode(value) != null,
          ('proposal', 'status') => ProposalStatus.fromCode(value) != null,
          ('proposal', 'outcome') => ProposalOutcome.fromCode(value) != null,
          _ => true,
        };
        if (!closed) return false;
        if (field.endsWith('Json')) {
          try {
            jsonDecode(value);
          } on FormatException {
            return false;
          }
        }
      default:
        return false;
    }
  }
  return true;
}

/// Restore through the sync inverse only, as A23's mapper will.
ProposalBuildResult _restore(Map<String, Object?> scenario) {
  final message = ProposalDraftCodec.messageFromSync(
    _raw(scenario['messagePayloadId']! as String)['budgetJson'] as String?,
  );
  if (message.issue case final issue?) return ProposalResult.failure(issue);
  final cards = <Map<String, Object?>>[];
  for (final id in scenario['cardPayloadIds']! as List<Object?>) {
    final row = _raw(id! as String);
    final card = ProposalDraftCodec.cardFromSync(
      interpretationJson: row['interpretationJson'] as String?,
      draftJson: row['draftJson']! as String,
    );
    if (card.issue case final issue?) return ProposalResult.failure(issue);
    cards.add(card.value!);
  }
  return ProposalDraftCodec.restore(
    message.value!,
    cards,
    context: context(),
    trustedFacts: trustedRows(cards, ctx: context()),
  );
}

final List<Map<String, Object?>> _scenarios = [
  for (final s in _vectors['restoreScenarios']! as List<Object?>) _object(s),
];

void main() {
  // rule: B18 corpus-drift
  test('B18 generated vectors match committed bytes', () {
    expect(
      _repoFile(_corpus).readAsBytesSync(),
      utf8.encode(generateChatProposalVectors()),
    );
    expect(_byId.length, _payloads.length);
    expect(_payloads.length, greaterThan(200));
  });

  // rule: B18 app-to-server
  test('AI-045 codec projections become accepted proposal and assistant '
      'message payloads', () {
    final sessions = chatProposalSessions();
    final rejects = (_vectors['codecServerRejects']! as List).toSet();
    expect(rejects, {
      'codec-worst-choices-129-card-1',
      'codec-worst-tiny-amount-card-1',
    });
    var cards = 0;
    for (final MapEntry(key: name, value: s) in sessions.entries) {
      for (final (i, card) in s.cards.indexed) {
        final id = 'codec-$name-card-${i + 1}';
        final row = _raw(id);
        final live = ProposalDraftCodec.syncProjection(s, card.id).value!;
        expect(row['draftJson'], live.draft, reason: id);
        expect(row['interpretationJson'], live.interpretation, reason: id);
        expect(row['originMessageId'], card.originMessageId, reason: id);
        expect(row['budgetMessageId'], card.budgetMessageId, reason: id);
        expect(
          row['status'],
          ProposalStatus.ofLifecycle(card.lifecycle).code,
          reason: id,
        );
        expect(
          row['codecVersion'],
          _object(jsonDecode(live.draft))['codecVersion'],
        );
        expect(_raw('codec-$name-message')['budgetJson'], live.messageBudget);
        expect(_byId[id]!['source'], 'codec');
        expect(_byId[id]!['appReads'], isTrue, reason: id);
        expect(_byId[id]!['serverAccepts'], !rejects.contains(id), reason: id);
        cards++;
      }
      expect(_byId['codec-$name-message']!['serverAccepts'], isTrue);
    }
    expect(cards, 11);
    // Realistic shapes fit every bound; the follow-up keeps its origin.
    final followUp = _raw('codec-follow-up-m2-card-1');
    expect(followUp['originMessageId'], isNot(followUp['budgetMessageId']));
    for (final p in _payloads.where((p) => p['source'] == 'codec')) {
      final row = _raw(p['id']! as String);
      for (final field in ['budgetJson', 'interpretationJson', 'draftJson']) {
        if (row[field] case final String text) {
          expect(ProposalDraftCodec.fitsSyncString(text), isTrue);
        }
      }
    }
    // The 128th tap is the last one the generic nested pass admits.
    String choices(String id) => _raw(id)['draftJson']! as String;
    expect(
      (_object(
                jsonDecode(choices('codec-worst-choices-128-card-1')),
              )['choices']!
              as Map)
          .length,
      128,
    );
    expect(
      (_object(
                jsonDecode(choices('codec-worst-choices-129-card-1')),
              )['choices']!
              as Map)
          .length,
      129,
    );
  });

  // rule: B18 server-to-app
  test('AI-045 codec rows restore from synced fields by budgetMessageId', () {
    final sessions = chatProposalSessions();
    final expected = {
      'six-item': sessions['six-item'],
      'multi-card': sessions['multi-card'],
      'follow-up-m2-carried-card': sessions['follow-up-m2'],
      'confirmed': sessions['confirmed'],
      'discarded': sessions['discarded'],
    };
    for (final MapEntry(key: id, value: session) in expected.entries) {
      final scenario = _scenarios.singleWhere((s) => s['id'] == id);
      expect(scenario['expect'], 'ok');
      final restored = _restore(scenario);
      expect(restored.issue, isNull, reason: id);
      expect(restored.value, session, reason: id);
    }
    final carried = _restore(
      _scenarios.singleWhere((s) => s['id'] == 'follow-up-m2-carried-card'),
    ).value!.cards.single;
    final origin = sessions['follow-up-m1']!.cards.single;
    expect(carried.id, origin.id);
    expect(carried.originMessageId, origin.originMessageId);
    expect(carried.budgetMessageId, isNot(origin.budgetMessageId));
    final m1 = _restore(
      _scenarios.singleWhere((s) => s['id'] == 'follow-up-m1-after-move'),
    );
    expect(m1.issue, isNull);
    expect(m1.value!.cards, isEmpty);
    // Pending cards survive a reinstall and stay out of confirmed totals.
    final pending = _restore(
      _scenarios.singleWhere((s) => s['id'] == 'multi-card'),
    ).value!;
    expect(pending.cards.where((c) => c.canConfirm), hasLength(3));
  });

  // rule: B18 server-to-app
  test('B18 accepted closed codes decode and rejected unknown codes stay '
      'unknown in Dart', () {
    final vocab = _object(_vectors['vocabularies']);
    expect(vocab['chatMessageRole'], [
      for (final v in ChatMessageRole.values) v.code,
    ]);
    expect(vocab['chatMessageStatus'], [
      for (final v in ChatMessageStatus.values) v.code,
    ]);
    expect(vocab['proposalStatus'], [
      for (final v in ProposalStatus.values) v.code,
    ]);
    expect(vocab['proposalOutcome'], [
      for (final v in ProposalOutcome.values) v.code,
    ]);
    final constants = _object(_vectors['constants']);
    expect(constants, {
      'json': ChatProposalSyncBounds.json,
      'text': ChatProposalSyncBounds.text,
      'language': ChatProposalSyncBounds.language,
      'kind': ChatProposalSyncBounds.kind,
      'origin': ChatProposalSyncBounds.origin,
      'codecVersionMin': ChatProposalSyncBounds.codecVersionMin,
      'codecVersionMax': ChatProposalSyncBounds.codecVersionMax,
    });
    Object? decode(String entity, String field, String code) =>
        switch ((entity, field)) {
          ('chatMessage', 'role') => ChatMessageRole.fromCode(code),
          ('chatMessage', 'status') => ChatMessageStatus.fromCode(code),
          ('proposal', 'status') => ProposalStatus.fromCode(code),
          _ => ProposalOutcome.fromCode(code),
        };
    var unknown = 0;
    for (final p in _payloads) {
      final id = p['id']! as String;
      final Map<String, Object?> row;
      try {
        row = _raw(id);
      } on Object {
        continue; // Malformed or non-object rows carry no codes.
      }
      final entity = p['entity']! as String;
      final closed = entity == 'chatMessage'
          ? ['role', 'status']
          : ['status', 'outcome'];
      for (final field in closed) {
        if (row[field] case final String code) {
          if (p['serverAccepts'] == true) {
            expect(decode(entity, field, code), isNotNull, reason: id);
          }
          if (RegExp('-(role|status|outcome)-unknown-').hasMatch(id)) {
            expect(p['serverAccepts'], isFalse, reason: id);
            if (decode(entity, field, code) == null) unknown++;
          }
        }
      }
    }
    expect(unknown, 14);
  });

  // rule: B18 no-cross-row
  test('B18 row admission does not require related message or card rows', () {
    // Every synthetic proposal references messages that are not in the
    // corpus, and the server still admits it.
    for (final id in [
      'proposal-base',
      'proposal-not-from-chat',
      'proposal-foodlog-null-refs',
      'chat-budget-foreign-card',
      'proposal-draft-unknown-version',
    ]) {
      expect(_byId[id]!['serverAccepts'], isTrue, reason: id);
    }
    for (final (id, issue) in [
      ('missing-card', ProposalIssue.sessionIncomplete),
      ('card-bound-to-another-message', ProposalIssue.budgetConflict),
      ('budget-names-foreign-card', ProposalIssue.budgetConflict),
      ('empty-budget', ProposalIssue.sessionIncomplete),
    ]) {
      final scenario = _scenarios.singleWhere((s) => s['id'] == id);
      expect(scenario['expect'], issue.name);
      expect(_restore(scenario).issue, issue, reason: id);
    }
  });

  // rule: B18 server-to-app
  test('B18 opaque engine JSON restores to a fixed issue without throwing', () {
    var fixed = 0;
    for (final scenario in _scenarios) {
      final id = scenario['id']! as String;
      final result = _restore(scenario);
      expect(result.issue?.name ?? 'ok', scenario['expect'], reason: id);
      if (result.issue != null) fixed++;
    }
    expect(fixed, 16);
    // A failure's toString stays content-free even when the input carries
    // user text (A22/A23 may log only the issue, never the result).
    const canary = 'CANARY-B18-DART-PRIVATE';
    for (final failed in [
      ProposalDraftCodec.messageFromSync('{"$canary":'),
      ProposalDraftCodec.messageFromSync('"$canary"'),
      ProposalDraftCodec.cardFromSync(
        interpretationJson: '[{"text":"$canary"}]',
        draftJson: '["$canary"]',
      ),
      ProposalDraftCodec.cardFromSync(
        interpretationJson: '{"$canary"',
        draftJson: '{"note":"$canary"}',
      ),
    ]) {
      expect(failed.issue, isNotNull);
      expect(failed.toString(), isNot(contains(canary)));
    }
    // Every accepted opaque value goes through the inverse without throwing.
    var decoded = 0;
    for (final p in _payloads.where((p) => p['appReads'] == true)) {
      final row = _raw(p['id']! as String);
      if (p['entity'] == 'chatMessage') {
        ProposalDraftCodec.messageFromSync(row['budgetJson'] as String?);
      } else if (row['draftJson'] case final String draft) {
        ProposalDraftCodec.cardFromSync(
          interpretationJson: row['interpretationJson'] as String?,
          draftJson: draft,
        );
      }
      decoded++;
    }
    expect(decoded, greaterThan(150));
  });

  // rule: B18 utf16-bounds
  test('B18 JSON string limit counts UTF-16 units including supplementary '
      'characters', () {
    final constants = _object(_vectors['constants']);
    final bounds = {
      'text': constants['text'],
      'language': constants['language'],
      'origin': constants['origin'],
      'kind': constants['kind'],
      'budgetJson': constants['json'],
      'interpretationJson': constants['json'],
      'draftJson': constants['json'],
    };
    var probes = 0;
    for (final p in _payloads.where((p) => p['probe'] != null)) {
      final id = p['id']! as String;
      final field = p['probe']! as String;
      final value = _raw(id)[field]! as String;
      final units = int.parse(id.split('-').last);
      expect(value.length, units, reason: id);
      expect(units <= (bounds[field]! as int), p['serverAccepts'], reason: id);
      if (id.contains('supplementary')) {
        // One code point fewer than units: a code-point count would differ.
        expect(value.runes.length, units - 1, reason: id);
      }
      if (field.endsWith('Json')) {
        expect(
          ProposalDraftCodec.fitsSyncString(value),
          p['serverAccepts'],
          reason: id,
        );
      }
      probes++;
    }
    expect(probes, 35);
  });

  // rule: B18 asymmetry
  test(
    'B18 asymmetric list is exactly server-rejected rows Dart tolerates',
    () {
      for (final p in _payloads) {
        expect(
          _dartReads(p['entity']! as String, p['rawPayload']! as String),
          p['appReads'],
          reason: p['id']! as String,
        );
      }
      final asymmetric = [
        for (final p in _payloads)
          if (p['serverAccepts'] == false && p['appReads'] == true) p['id'],
      ];
      expect(_vectors['serverRejectsAppTolerates'], asymmetric);
      // Every unpaired surrogate the server rejects is one Dart tolerates.
      final lone = asymmetric.where((id) => '$id'.contains('lone')).toList();
      expect(lone, hasLength(9));
      for (final id in lone) {
        final raw = _byId[id]!['rawPayload']! as String;
        expect(raw, matches(RegExp(r'\\{1,2}ud[89abc]')), reason: '$id');
      }
    },
  );
}
