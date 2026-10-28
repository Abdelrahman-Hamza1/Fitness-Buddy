import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';

import '../test/proposals/proposal_fixtures.dart';

/// B18 shared corpus for the `chatMessage` and `proposal` sync entities
/// (`contracts/testdata/README.md`). `serverAccepts` and `appReads` are
/// declarations: C# checks the first against the embedded registry, the Dart
/// tests check the second against the fb_domain sync surface. Codec payloads
/// are real A21 `syncProjection` output; nothing here copies codec logic.
Map<String, Object?> chatProposalVectors() {
  final payloads = <Map<String, Object?>>[];
  final asymmetric = <String>[];
  final codecRejects = <String>[];
  void add(
    String id,
    String entity,
    Map<String, Object?> payload, {
    bool server = true,
    bool? app,
    bool deleted = false,
    String? raw,
    String source = 'synthetic',
    String? probe,
  }) {
    final reads = app ?? server;
    payloads.add({
      'id': id,
      'entity': entity,
      'rawPayload': raw ?? jsonEncode(payload),
      'deleted': deleted,
      'serverAccepts': server,
      'appReads': reads,
      'source': source,
      'probe': ?probe,
    });
    if (!server && reads) asymmetric.add(id);
    if (!server && source == 'codec') codecRejects.add(id);
  }

  void chat(
    String id,
    Map<String, Object?> changes, {
    bool server = true,
    bool? app,
    bool deleted = false,
    String? raw,
    String? probe,
  }) => add(
    'chat-$id',
    'chatMessage',
    {..._chatBase, ...changes},
    server: server,
    app: app,
    deleted: deleted,
    raw: raw,
    probe: probe,
  );
  void proposal(
    String id,
    Map<String, Object?> changes, {
    bool server = true,
    bool? app,
    bool deleted = false,
    String? raw,
    String? probe,
  }) => add(
    'proposal-$id',
    'proposal',
    {..._proposalBase, ...changes},
    server: server,
    app: app,
    deleted: deleted,
    raw: raw,
    probe: probe,
  );

  // Real codec output: every card of each session plus its assistant row.
  final sessions = chatProposalSessions();
  for (final MapEntry(key: name, value: s) in sessions.entries) {
    final rejected = name.startsWith('worst-') && name != 'worst-choices-128';
    var budget = '';
    for (final (i, card) in s.cards.indexed) {
      final p = ProposalDraftCodec.syncProjection(s, card.id).value!;
      budget = p.messageBudget;
      final status = ProposalStatus.ofLifecycle(card.lifecycle);
      add(
        'codec-$name-card-${i + 1}',
        'proposal',
        {
          ..._proposalBase,
          'status': status.code,
          'outcome': switch (status) {
            .confirmed => ProposalOutcome.unchanged.code,
            .discarded => ProposalOutcome.discarded.code,
            _ => null,
          },
          'resolvedAtMs': status == .pending ? null : _resolvedAtMs,
          'originMessageId': card.originMessageId,
          'budgetMessageId': card.budgetMessageId,
          'interpretationJson': p.interpretation,
          'draftJson': p.draft,
        },
        source: 'codec',
        server: !rejected,
        app: true,
      );
    }
    add('codec-$name-message', 'chatMessage', {
      ..._chatBase,
      'budgetJson': budget,
    }, source: 'codec');
  }
  // M1 keeps its issued history after the follow-up moved its card to M2.
  final m1 = sessions['follow-up-m1']!;
  add('codec-follow-up-m1-moved-message', 'chatMessage', {
    ..._chatBase,
    'budgetJson': jsonEncode(
      ProposalDraftCodec.encodeMessageBudget(
        m1,
        movedCardIds: [m1.cards.single.id],
      ),
    ),
  }, source: 'codec');

  // Base rows, tombstones and attachments (D8).
  chat('base', {});
  proposal('base', {});
  chat('base-tombstone', {}, deleted: true);
  proposal('base-tombstone', {}, deleted: true);
  chat('tombstone-scrubbed', {'text': '', 'budgetJson': null}, deleted: true);
  proposal('tombstone-scrubbed', {
    'draftJson': '{}',
    'interpretationJson': null,
  }, deleted: true);
  chat('tombstone-empty', {}, raw: '{}', deleted: true, server: false);
  proposal('tombstone-empty', {}, raw: '{}', deleted: true, server: false);
  for (final (field, value) in [
    ('attachmentRefs', '["/data/user/0/app/files/x.jpg"]'),
    ('attachmentsJson', '[]'),
    ('localPath', '/storage/emulated/0/x.jpg'),
  ]) {
    chat('extra-$field', {field: value}, server: false);
    chat(
      'extra-$field-tombstone',
      {field: value},
      server: false,
      deleted: true,
    );
  }
  chat('user-row', {
    'role': ChatMessageRole.user.code,
    'status': ChatMessageStatus.queued.code,
    'replyToMessageId': null,
    'codecVersion': null,
    'budgetJson': null,
    'language': null,
  });
  proposal('not-from-chat', {
    'kind': 'targetChange',
    'originMessageId': null,
    'budgetMessageId': null,
    'interpretationJson': null,
  });
  // Accepted: no kind pairing (D6); restore rejects it with a fixed issue.
  proposal('foodlog-null-refs', {
    'originMessageId': null,
    'budgetMessageId': null,
    'interpretationJson': null,
  });
  proposal('draftJson-null', {'draftJson': null}, server: false);

  // Closed vocabularies (D3) and rejected unknown codes.
  for (final v in ChatMessageRole.values) {
    chat('role-${v.code}', {'role': v.code});
  }
  for (final v in ChatMessageStatus.values) {
    chat('status-${v.code}', {'status': v.code});
  }
  for (final v in ProposalStatus.values) {
    proposal('status-${v.code}', {'status': v.code});
  }
  for (final v in ProposalOutcome.values) {
    proposal('outcome-${v.code}', {'outcome': v.code});
  }
  for (final (name, code) in [
    ('system', 'system'),
    ('capitalized', 'User'),
    ('upper', 'ASSISTANT'),
    ('empty', ''),
  ]) {
    chat('role-unknown-$name', {'role': code}, server: false);
  }
  for (final (name, code) in [
    ('sent', 'sent'),
    ('camel-case', 'pendingOffline'),
    ('upper', 'DONE'),
    ('proposal-code', 'pending'),
  ]) {
    chat('status-unknown-$name', {'status': code}, server: false);
  }
  for (final (name, code) in [
    ('engine-active', 'active'),
    ('capitalized', 'Pending'),
    ('resolved', 'resolved'),
  ]) {
    proposal('status-unknown-$name', {'status': code}, server: false);
  }
  for (final (name, code) in [
    ('adjusted-chips', 'adjusted chips'),
    ('capitalized', 'Adjusted'),
    ('status-code', 'confirmed'),
  ]) {
    proposal('outcome-unknown-$name', {'outcome': code}, server: false);
  }

  // UTF-16 bounds at limit-1 / limit / limit+1, ASCII and supplementary.
  void bound(
    void Function(
      String,
      Map<String, Object?>, {
      bool server,
      bool? app,
      bool deleted,
      String? raw,
      String? probe,
    })
    row,
    String field,
    int max,
    String Function(int units, {required bool emoji}) text,
  ) {
    for (final units in [max - 1, max, max + 1]) {
      row(
        '$field-ascii-$units',
        {field: text(units, emoji: false)},
        server: units <= max,
        probe: field,
      );
    }
    for (final units in [max, max + 1]) {
      row(
        '$field-supplementary-$units',
        {field: text(units, emoji: true)},
        server: units <= max,
        probe: field,
      );
    }
  }

  String plain(int units, {required bool emoji}) =>
      emoji ? '${'x' * (units - 2)}$_emoji' : 'x' * units;
  // A JSON string root, so the pair sits right before the closing quote.
  String json(int units, {required bool emoji}) =>
      '"${plain(units - 2, emoji: emoji)}"';
  bound(chat, 'text', ChatProposalSyncBounds.text, plain);
  bound(chat, 'language', ChatProposalSyncBounds.language, plain);
  bound(chat, 'origin', ChatProposalSyncBounds.origin, plain);
  bound(chat, 'budgetJson', ChatProposalSyncBounds.json, json);
  bound(proposal, 'kind', ChatProposalSyncBounds.kind, plain);
  bound(proposal, 'interpretationJson', ChatProposalSyncBounds.json, json);
  bound(proposal, 'draftJson', ChatProposalSyncBounds.json, json);
  chat('text-empty', {'text': ''});
  chat('language-empty', {'language': ''});
  proposal('kind-empty', {'kind': ''});

  // codecVersion (D5, D15) and resolvedAtMs.
  for (final (row, nullable) in [(chat, true), (proposal, false)]) {
    for (final (name, value, accepted) in <(String, Object?, bool)>[
      ('1', 1, true),
      ('2', 2, true),
      ('max', ChatProposalSyncBounds.codecVersionMax, true),
      ('whole-double', 1.0, true),
      ('max-plus-1', ChatProposalSyncBounds.codecVersionMax + 1, false),
      ('0', 0, false),
      ('minus-1', -1, false),
      ('fraction', 1.5, false),
      ('string', '1', false),
      ('null', null, nullable),
    ]) {
      row('codecVersion-$name', {'codecVersion': value}, server: accepted);
    }
  }
  for (final (name, value, accepted) in <(String, Object?, bool)>[
    ('0', 0, true),
    ('max', 9007199254740991, true),
    ('null', null, true),
    ('minus-1', -1, false),
    ('max-plus-1', 9007199254740992, false),
  ]) {
    proposal('resolvedAtMs-$name', {'resolvedAtMs': value}, server: accepted);
  }

  // UUID references: canonical lowercase text of any version.
  for (final (row, field) in [
    (chat, 'replyToMessageId'),
    (proposal, 'originMessageId'),
    (proposal, 'budgetMessageId'),
  ]) {
    row('$field-nil', {field: '00000000-0000-0000-0000-000000000000'});
    row('$field-uppercase', {field: _m1.toUpperCase()}, server: false);
    row('$field-not-uuid', {field: 'not-a-uuid'}, server: false);
    row('$field-braced', {field: '{$_m1}'}, server: false);
  }

  // Opaque engine JSON (D4): any well-formed root is admitted, and the
  // generic nested pass is server-only, so Dart reads what it rejects.
  for (final (row, field) in [
    (chat, 'budgetJson'),
    (proposal, 'interpretationJson'),
    (proposal, 'draftJson'),
  ]) {
    for (final (name, value) in [
      ('object', '{}'),
      ('array', '[]'),
      ('null-literal', 'null'),
      ('number', '1'),
      ('string', '"x"'),
      ('unknown-codec-version', '{"codecVersion":99}'),
      ('engine-invalid-keys', '{"unknown":[1,{"nested":true}]}'),
      ('depth-24', '${'[' * 24}0${']' * 24}'),
      ('members-128', _members(128)),
      ('items-500', '[${List.filled(500, 0).join(',')}]'),
      ('key-256', '{"${'k' * 256}":0}'),
      ('long-double', '{"a":0.30000000000000004}'),
      ('exponent-in-range', '{"a":1e-7}'),
    ]) {
      row('$field-$name', {field: value});
    }
    for (final (name, value) in [
      ('depth-25', '${'[' * 25}0${']' * 25}'),
      ('members-129', _members(129)),
      ('items-501', '[${List.filled(501, 0).join(',')}]'),
      ('key-257', '{"${'k' * 257}":0}'),
      ('duplicate-key', '{"a":1,"a":2}'),
      ('number-below-decimal', '{"a":1e-30}'),
      ('number-above-decimal', '{"a":1e30}'),
      ('nul-in-string', r'{"a":"x\u0000"}'),
      ('nul-in-key', r'{"x\u0000":1}'),
    ]) {
      row('$field-$name', {field: value}, server: false, app: true);
    }
    for (final (name, value) in [
      ('malformed', '{'),
      ('empty-text', ''),
      ('trailing-garbage', '{}x'),
    ]) {
      row('$field-$name', {field: value}, server: false);
    }
  }
  chat('text-nul', {'text': 'x\u0000'}, server: false, app: true);

  // Ill-formed UTF-16 (D7): existing server behaviour; Dart decodes it.
  String lone(
    Map<String, Object?> payload,
    String unit, {
    bool nested = false,
  }) => jsonEncode(payload).replaceAll(_mark, nested ? '\\\\$unit' : '\\$unit');
  for (final (name, unit) in [('high', 'ud800'), ('low', 'udc00')]) {
    chat(
      'text-lone-$name',
      {},
      server: false,
      app: true,
      raw: lone({..._chatBase, 'text': 'x${_mark}x'}, unit),
    );
    chat(
      'budgetJson-raw-lone-$name',
      {},
      server: false,
      app: true,
      raw: lone({..._chatBase, 'budgetJson': '{"a":"$_mark"}'}, unit),
    );
    proposal(
      'draftJson-nested-value-lone-$name',
      {},
      server: false,
      app: true,
      raw: lone(
        {..._proposalBase, 'draftJson': '{"a":"$_mark"}'},
        unit,
        nested: true,
      ),
    );
    proposal(
      'interpretationJson-nested-key-lone-$name',
      {},
      server: false,
      app: true,
      raw: lone(
        {..._proposalBase, 'interpretationJson': '{"$_mark":1}'},
        unit,
        nested: true,
      ),
    );
  }
  chat(
    'text-reversed-pair',
    {},
    server: false,
    app: true,
    raw: jsonEncode({..._chatBase, 'text': _mark})
        .replaceAll(_mark, r'\udc00\ud800'),
  );
  chat(
    'text-lone-high-tombstone',
    {},
    server: false,
    app: true,
    deleted: true,
    raw: lone({..._chatBase, 'text': _mark}, 'ud800'),
  );

  // Restore inputs built from codec rows (synthetic, server-accepted).
  final six = payloads.firstWhere((p) => p['id'] == 'codec-six-item-card-1');
  final sixDraft = jsonDecode(_field(six, 'draftJson')) as Map<String, Object?>;
  final sixMessage = payloads.firstWhere(
    (p) => p['id'] == 'codec-six-item-message',
  );
  final sixBudget =
      jsonDecode(_field(sixMessage, 'budgetJson')) as Map<String, Object?>;
  chat('budget-foreign-card', {
    'budgetJson': jsonEncode({
      ...sixBudget,
      'cards': ['019a1b2c-0000-7000-8000-00000000f0f0'],
    }),
  });
  chat('budget-unknown-version', {
    'budgetJson': jsonEncode({...sixBudget, 'codecVersion': 2}),
  });
  proposal('draft-unknown-version', {
    'interpretationJson': _field(six, 'interpretationJson'),
    'draftJson': jsonEncode({...sixDraft, 'codecVersion': 2}),
  });
  proposal('draft-deep-object', {'draftJson': '${'{"a":' * 23}{}${'}' * 23}'});

  return {
    'version': 1,
    'constants': {
      'json': ChatProposalSyncBounds.json,
      'text': ChatProposalSyncBounds.text,
      'language': ChatProposalSyncBounds.language,
      'kind': ChatProposalSyncBounds.kind,
      'origin': ChatProposalSyncBounds.origin,
      'codecVersionMin': ChatProposalSyncBounds.codecVersionMin,
      'codecVersionMax': ChatProposalSyncBounds.codecVersionMax,
    },
    'vocabularies': {
      'chatMessageRole': [for (final v in ChatMessageRole.values) v.code],
      'chatMessageStatus': [for (final v in ChatMessageStatus.values) v.code],
      'proposalStatus': [for (final v in ProposalStatus.values) v.code],
      'proposalOutcome': [for (final v in ProposalOutcome.values) v.code],
    },
    'payloads': payloads,
    'restoreScenarios': [
      for (final (id, message, cards, expect) in _scenarios)
        {
          'id': id,
          'messagePayloadId': message,
          'cardPayloadIds': cards,
          'expect': expect,
        },
    ],
    'serverRejectsAppTolerates': asymmetric,
    'codecServerRejects': codecRejects,
  };
}

/// Deterministic A21 sessions behind the codec payloads (also used by tests).
Map<String, ProposalSession> chatProposalSessions() {
  ProposalSession recompute(ProposalSession s, ProposalAdjustment a) =>
      ProposalEngine.recompute(s, a).value!.session;
  final ids = FixedIds();
  final m1 = session(
    message([
      intent([riceItem(), riceItem()]),
    ]),
    ids: ids,
  );
  final m2 = ProposalEngine.rebuild(
    m1.cards.single,
    ProposalRequest(
      interpretation: message([
        intent([riceItem(), riceItem(), riceItem()]),
      ]),
      messageId: _m2,
      idSource: ids,
      context: context(),
      facts: ProposalFacts(),
    ),
  ).value!.session;
  final single = session(message());
  final multi = session(
    message([
      intent([riceItem()]),
      intent([item()], slot: 'dinner'),
      intent([item(match: oilFood(), unit: 'tbsp')], slot: 'lunch'),
    ]),
  );
  // 26 items x 5 chip kinds: every tap records one `choices` member.
  ProposalSession taps(int count) {
    final dimensions = [
      dimension('portion', [
        for (var i = 1; i <= 3; i++)
          option('p$i', amount: i * 1.0, unit: 'piece'),
      ]),
      dimension('share', [
        for (var i = 1; i <= 3; i++) option('s$i', amount: i / 4, unit: 'g'),
      ]),
      dimension('variant', [
        for (var i = 1; i <= 3; i++)
          option(
            'v$i',
            candidate: food(key: 'usda:v$i', kcal: 100.0 + i),
          ),
      ]),
      fatDimension(),
      dimension('oilRetention', [
        option('all', amount: 1, unit: 'g'),
        option('most', amount: .25, unit: 'g'),
      ]),
    ];
    var s = session(
      message([
        intent([for (var i = 0; i < 26; i++) item(dimensions: dimensions)]),
      ]),
    );
    final all = [
      for (final l in s.cards.single.lines)
        for (final d in l.dimensions) (d.id, d.options.last.id),
    ];
    for (final (dimension, option) in all.take(count)) {
      s = recompute(s, ProposalSelect(dimension, option));
    }
    final draft = ProposalDraftCodec.syncProjection(s, s.cards.single.id);
    final choices = (jsonDecode(draft.value!.draft) as Map)['choices'] as Map;
    if (choices.length != count) throw StateError('choices probe drifted');
    return s;
  }

  return {
    'six-item': session(
      message([
        intent([
          riceItem(),
          riceItem(),
          item(dimensions: [fatDimension()]),
          item(),
          item(),
          item(),
        ], group: 'dish'),
      ]),
    ),
    'multi-card': multi,
    'follow-up-m1': m1,
    'follow-up-m2': m2,
    'confirmed': recompute(
      single,
      ProposalSetLifecycle(single.cards.single.id, .confirmed),
    ),
    'discarded': recompute(
      single,
      ProposalSetLifecycle(single.cards.single.id, .discarded),
    ),
    'worst-choices-128': taps(128),
    'worst-choices-129': taps(129),
    'worst-tiny-amount': recompute(
      single,
      ProposalSetAmount(
        single.cards.single.lines.single.entry.id,
        Quantity(1e-30, 'g'),
      ),
    ),
  };
}

const _scenarios = <(String, String, List<String>, String)>[
  ('six-item', 'codec-six-item-message', ['codec-six-item-card-1'], 'ok'),
  (
    'multi-card',
    'codec-multi-card-message',
    [
      'codec-multi-card-card-1',
      'codec-multi-card-card-2',
      'codec-multi-card-card-3',
    ],
    'ok',
  ),
  (
    'follow-up-m2-carried-card',
    'codec-follow-up-m2-message',
    ['codec-follow-up-m2-card-1'],
    'ok',
  ),
  ('follow-up-m1-after-move', 'codec-follow-up-m1-moved-message', [], 'ok'),
  ('confirmed', 'codec-confirmed-message', ['codec-confirmed-card-1'], 'ok'),
  ('discarded', 'codec-discarded-message', ['codec-discarded-card-1'], 'ok'),
  (
    'missing-card',
    'codec-multi-card-message',
    ['codec-multi-card-card-1', 'codec-multi-card-card-2'],
    'sessionIncomplete',
  ),
  (
    'card-bound-to-another-message',
    'codec-six-item-message',
    ['codec-follow-up-m2-card-1'],
    'budgetConflict',
  ),
  (
    'budget-names-foreign-card',
    'chat-budget-foreign-card',
    ['codec-six-item-card-1'],
    'budgetConflict',
  ),
  (
    'empty-budget',
    'chat-budgetJson-object',
    ['codec-six-item-card-1'],
    'sessionIncomplete',
  ),
  (
    'user-row-has-no-budget',
    'chat-user-row',
    ['codec-six-item-card-1'],
    'invalidInput',
  ),
  (
    'foodlog-null-refs',
    'codec-six-item-message',
    ['proposal-foodlog-null-refs'],
    'invalidInput',
  ),
  (
    'unknown-budget-version',
    'chat-budget-unknown-version',
    ['codec-six-item-card-1'],
    'unsupportedCodecVersion',
  ),
  (
    'unknown-card-version',
    'codec-six-item-message',
    ['proposal-draft-unknown-version'],
    'unsupportedCodecVersion',
  ),
  (
    'budget-of-only-an-unknown-version',
    'chat-budgetJson-unknown-codec-version',
    ['codec-six-item-card-1'],
    'invalidInput',
  ),
  (
    'budget-array-root',
    'chat-budgetJson-array',
    ['codec-six-item-card-1'],
    'invalidInput',
  ),
  (
    'budget-null-root',
    'chat-budgetJson-null-literal',
    ['codec-six-item-card-1'],
    'invalidInput',
  ),
  (
    'draft-array-root',
    'codec-six-item-message',
    ['proposal-draftJson-array'],
    'invalidInput',
  ),
  (
    'draft-empty-object',
    'codec-six-item-message',
    ['proposal-draftJson-object'],
    'unsupportedCodecVersion',
  ),
  (
    'draft-deep-object',
    'codec-six-item-message',
    ['proposal-draft-deep-object'],
    'unsupportedCodecVersion',
  ),
  (
    'near-limit-draft-string-root-invalid',
    'codec-six-item-message',
    ['proposal-draftJson-ascii-32768'],
    'invalidInput',
  ),
  (
    'near-limit-interpretation-parses-then-draft-unsupported',
    'codec-six-item-message',
    ['proposal-interpretationJson-supplementary-32768'],
    'unsupportedCodecVersion',
  ),
];

const _m1 = '019a1b2c-0000-7000-8000-000000009999';
const _m2 = '019a1b2c-0000-7000-8000-000000008888';
const _resolvedAtMs = 1792224000000;
const _emoji = '\u{1f34e}';
// Replaced by an escaped unpaired surrogate after encoding: the corpus file
// itself stays well-formed UTF-8.
const _mark = '@surrogate@';

const _chatBase = <String, Object?>{
  'createdAtMs': 0,
  'origin': 'synthetic',
  'editedByUser': false,
  'role': 'assistant',
  'text': 'Synthetic reply',
  'status': 'done',
  'language': 'en',
  'replyToMessageId': '019a1b2c-0000-7000-8000-000000007777',
  'codecVersion': 1,
  'budgetJson': '{}',
};

const _proposalBase = <String, Object?>{
  'createdAtMs': 0,
  'origin': 'synthetic',
  'editedByUser': false,
  'kind': 'foodLog',
  'status': 'pending',
  'outcome': null,
  'resolvedAtMs': null,
  'originMessageId': _m1,
  'budgetMessageId': _m1,
  'codecVersion': 1,
  'interpretationJson': '[]',
  'draftJson': '{}',
};

String _members(int count) =>
    '{${[for (var i = 0; i < count; i++) '"k$i":0'].join(',')}}';

String _field(Map<String, Object?> payload, String field) =>
    (jsonDecode(payload['rawPayload']! as String) as Map)[field]! as String;

/// Stable JSON bytes shared by Dart and C# tests, independent of local paths.
String generateChatProposalVectors() =>
    '${const JsonEncoder.withIndent('  ').convert(chatProposalVectors())}\n';

/// Writes only the corpus; the drift test calls the in-memory function.
void main() {
  File.fromUri(
    Platform.script.resolve(
      '../../../contracts/testdata/sync/chat-proposal-validation-vectors.json',
    ),
  ).writeAsStringSync(generateChatProposalVectors());
}
