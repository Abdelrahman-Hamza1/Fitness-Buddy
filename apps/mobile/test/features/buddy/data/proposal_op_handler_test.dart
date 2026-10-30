import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';

const _v5 = '0a1b2c3d-0000-5000-8000-000000000001';
final _now = DateTime.utc(2026, 10, 30, 9);

Map<String, Object?> _corpusRow(String id) {
  final corpus = jsonDecode(
    File('../../contracts/testdata/sync/chat-proposal-validation-vectors.json')
        .readAsStringSync(),
  ) as Map<String, Object?>;
  final payload = (corpus['payloads']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .singleWhere((p) => p['id'] == id);
  return jsonDecode(payload['rawPayload']! as String) as Map<String, Object?>;
}

/// The real six-item codec card and budget (B18 corpus, codec v2).
final Map<String, Object?> _card = _corpusRow('codec-six-item-card-1');
final String _budget =
    _corpusRow('codec-six-item-message')['budgetJson']! as String;

/// [json] (an engine object) at codec [revision].
String _at(String json, int revision) => jsonEncode({
  ...(jsonDecode(json) as Map<String, Object?>),
  'revision': revision,
});

String get _draft => _card['draftJson']! as String;
String get _interpretation => _card['interpretationJson']! as String;

/// The real applier with the chat and proposal families.
final class ProposalHarness {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [ChatMessageOpHandler(db), ProposalOpHandler(db)],
      clock: ManualClock(_now),
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  final UuidV7Generator ids = UuidV7Generator(
    ManualClock(DateTime.utc(2026, 10, 30)),
    Random(23),
  );
  late final ChangeSetApplier<AppDatabase> applier;

  Future<Applied> apply(List<ChangeOp> ops, {Origin? origin}) async {
    final r = await applier.apply(
      ChangeSet(ops, origin: origin ?? Origin.system),
    );
    if (r is! Applied) fail('expected Applied: $r');
    return r;
  }

  Future<ChangeFailure> reject(List<ChangeOp> ops) async {
    final before = await raw();
    final r = await applier.apply(ChangeSet(ops, origin: Origin.system));
    expect(await raw(), before, reason: 'rejection changed persisted state');
    if (r is! Rejected) fail('expected Rejected: $r');
    return r.failure;
  }

  Future<ProposalRow> proposal(String id) =>
      (db.select(db.proposals)..where((t) => t.id.equals(id))).getSingle();

  Future<ChatMessageRow> chat(String id) =>
      (db.select(db.chatMessages)..where((t) => t.id.equals(id))).getSingle();

  Future<String> raw() async => jsonEncode({
    for (final table in ['chat_messages', 'proposals', 'sync_outbox'])
      table: [
        for (final r
            in await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
          r.data,
      ],
  });

  /// A user message and its assistant reply, which holds the budget.
  Future<(String, String)> exchange({String? answerJson}) async {
    final user = ids.next();
    final assistant = ids.next();
    await apply([
      CreateChatMessage(
        user,
        const ChatMessageDraft(
          role: ChatMessageRole.user,
          text: 'eggs',
          status: ChatMessageStatus.done,
        ),
      ),
      CreateChatMessage(
        assistant,
        ChatMessageDraft(
          role: ChatMessageRole.assistant,
          text: 'Here is your meal.',
          status: ChatMessageStatus.done,
          replyToMessageId: user,
          codecVersion: ProposalDraftCodec.version,
          budgetJson: _budget,
        ),
        answerJson: answerJson,
      ),
    ]);
    return (user, assistant);
  }
}

ProposalRowDraft _row(
  String? budget, {
  String kind = foodLogKind,
  String? origin,
  int codecVersion = ProposalDraftCodec.version,
  String? interpretation,
  String? draft,
  bool noInterpretation = false,
}) => ProposalRowDraft(
  kind: kind,
  originMessageId: origin ?? budget,
  budgetMessageId: budget,
  codecVersion: codecVersion,
  interpretationJson: noInterpretation
      ? null
      : interpretation ?? _interpretation,
  draftJson: draft ?? _draft,
);

SaveProposalDraft _save(
  String id,
  String? expected, {
  String? to,
  int revision = 0,
}) => SaveProposalDraft(
  id,
  expectedBudgetMessageId: expected,
  budgetMessageId: to ?? expected,
  codecVersion: ProposalDraftCodec.version,
  interpretationJson: _interpretation,
  draftJson: _at(_draft, revision),
);

ResolveProposal _resolve(
  String id,
  String? expected, {
  ProposalStatus to = ProposalStatus.confirmed,
  ProposalOutcome outcome = ProposalOutcome.unchanged,
  int revision = 0,
}) => ResolveProposal(
  id,
  expectedBudgetMessageId: expected,
  to: to,
  outcome: outcome,
  codecVersion: ProposalDraftCodec.version,
  interpretationJson: _interpretation,
  draftJson: _at(_draft, revision),
);

void main() {
  // rule: A23 proposal-handler
  test('A23 proposal handler rejects invalid rows and stale bindings without '
      'writing', () async {
    final h = ProposalHarness();
    final (user, m1) = await h.exchange();
    final (_, m2) = await h.exchange();
    final id = h.ids.next();

    // Wire and kind rules on create.
    final creates = <ProposalRowDraft, String>{
      _row(m1, kind: ''): 'proposalKind',
      _row(m1, kind: 'k' * 33): 'proposalKind',
      _row(m1, origin: 'not-a-uuid'): 'proposalRef',
      _row('019A1B2C-0000-7000-8000-000000000001'): 'proposalRef',
      _row(m1, codecVersion: 0): 'proposalCodecVersion',
      _row(m1, codecVersion: 2147483648): 'proposalCodecVersion',
      _row(m1, interpretation: '['): 'proposalInterpretation',
      _row(m1, interpretation: '"\uD800"'): 'proposalInterpretation',
      _row(m1, draft: '[]'): 'proposalDraft',
      _row(m1, draft: '{'): 'proposalDraft',
      _row(m1, draft: '{"p":"${'x' * (512 * 1024)}"}'): 'proposalDraft',
      _row(null, origin: m1): 'proposalFoodLog',
      _row(m1, noInterpretation: true): 'proposalFoodLog',
      // The budget row must be a live assistant row.
      _row(user): 'proposalMessageMissing',
      _row(h.ids.next()): 'proposalMessageMissing',
    };
    for (final MapEntry(key: draft, value: code) in creates.entries) {
      expect(
        await h.reject([CreateProposal(id, draft)]),
        InvalidOp(code),
        reason: code,
      );
    }
    expect(
      await h.reject([CreateProposal(_v5, _row(m1))]),
      const InvalidOp('proposalId'),
    );
    // Another kind needs no message refs and no interpretation.
    final other = h.ids.next();
    await h.apply([
      CreateProposal(
        other,
        _row(null, kind: 'targetChange', noInterpretation: true, draft: '{}'),
      ),
    ]);

    // A pending card bound to m1 at revision 0.
    await h.apply([CreateProposal(id, _row(m1))]);
    final created = await h.proposal(id);
    expect(created.status, 'pending');
    expect(created.outcome, isNull);
    expect(created.resolvedAt, isNull);
    expect(created.budgetMessageId, m1);
    expect(created.originMessageId, m1);

    // Binding, revision and target checks on save.
    expect(await h.reject([_save(id, m2)]), const InvalidOp('proposalRebound'));
    expect(await h.reject([_save(h.ids.next(), m1)]), isA<RowNotFound>());
    expect(
      await h.reject([_save(id, m1, to: h.ids.next())]),
      const InvalidOp('proposalMessageMissing'),
    );
    expect(
      await h.reject([_save(id, m1, to: user)]),
      const InvalidOp('proposalMessageMissing'),
    );
    await h.apply([_save(id, m1, revision: 2)]);
    expect(
      await h.reject([_save(id, m1, revision: 1)]),
      const InvalidOp('proposalStale'),
    );
    // Equal revision is allowed; an identical save writes nothing.
    final same = await h.apply([_save(id, m1, revision: 2)]);
    expect(same.inverse.rows, isEmpty);
    // A follow-up rebinds the card; origin never changes.
    await h.apply([_save(id, m1, to: m2, revision: 3)]);
    expect((await h.proposal(id)).budgetMessageId, m2);
    expect((await h.proposal(id)).originMessageId, m1);

    // Resolution checks.
    expect(
      await h.reject([
        _resolve(id, m2, revision: 3, outcome: ProposalOutcome.discarded),
      ]),
      const InvalidOp('proposalResolution'),
    );
    expect(
      await h.reject([
        _resolve(
          id,
          m2,
          to: ProposalStatus.discarded,
          outcome: ProposalOutcome.adjusted,
          revision: 3,
        ),
      ]),
      const InvalidOp('proposalResolution'),
    );
    expect(
      await h.reject([_resolve(id, m2, to: ProposalStatus.pending)]),
      const InvalidOp('proposalResolution'),
    );
    expect(
      await h.reject([_resolve(id, m1, revision: 3)]),
      const InvalidOp('proposalRebound'),
    );
    expect(
      await h.reject([_resolve(id, m2, revision: 2)]),
      const InvalidOp('proposalStale'),
    );
    await h.apply([
      _resolve(id, m2, revision: 3, outcome: ProposalOutcome.adjusted),
    ]);
    final resolved = await h.proposal(id);
    expect(resolved.status, 'confirmed');
    expect(resolved.outcome, 'adjusted');
    expect(resolved.resolvedAt, _now.millisecondsSinceEpoch);
    // A second resolution of the same card never applies.
    expect(
      await h.reject([_resolve(id, m2, revision: 3)]),
      const InvalidOp('proposalResolved'),
    );
    // A resolved sibling's content may still be saved with its session; its
    // status never changes that way.
    await h.apply([_save(id, m2, revision: 4)]);
    expect((await h.proposal(id)).status, 'confirmed');
    // Moving a card (a follow-up or rebuild) requires it to be pending.
    expect(
      await h.reject([
        SaveProposalDraft(
          id,
          expectedBudgetMessageId: m2,
          budgetMessageId: m1,
          codecVersion: ProposalDraftCodec.version,
          interpretationJson: _interpretation,
          draftJson: _at(_draft, 5),
          requirePending: true,
        ),
      ]),
      const InvalidOp('proposalResolved'),
    );
    // Ops are content-free in logs.
    for (final op in [
      CreateProposal(id, _row(m1)),
      _save(id, m1),
      _resolve(id, m1),
    ]) {
      expect('$op', isNot(contains('foods')));
      expect('$op', isNot(contains('Synthetic')));
    }
  });

  // rule: A23 budget-writer
  test('A23 budget writes need a live assistant row and never lower the '
      'revision', () async {
    final h = ProposalHarness();
    final (user, m1) = await h.exchange(answerJson: '{"intents":[]}');
    expect((await h.chat(m1)).answerJson, '{"intents":[]}');
    SetChatMessageBudget set(String id, int revision, {bool clear = false}) =>
        SetChatMessageBudget(
          id,
          ProposalDraftCodec.version,
          _at(_budget, revision),
          clearAnswer: clear,
        );
    expect(
      await h.reject([set(user, 1)]),
      const InvalidOp('proposalMessageMissing'),
    );
    expect(
      await h.reject([set(h.ids.next(), 1)]),
      const InvalidOp('proposalMessageMissing'),
    );
    expect(
      await h.reject([SetChatMessageBudget(m1, 1, '{')]),
      const InvalidOp('chatMessageBudget'),
    );
    expect(
      await h.reject([SetChatMessageBudget(m1, 0, '{}')]),
      const InvalidOp('chatMessageCodecVersion'),
    );
    expect(
      await h.reject([SetChatMessageBudget(m1, 1, '"${'x' * 32767}"')]),
      const InvalidOp('chatMessageBudget'),
    );
    await h.apply([set(m1, 3)]);
    expect(await h.reject([set(m1, 2)]), const InvalidOp('proposalStale'));
    expect((await h.apply([set(m1, 3)])).inverse.rows, isEmpty);
    expect((await h.chat(m1)).answerJson, isNotNull);
    await h.apply([set(m1, 3, clear: true)]);
    final row = await h.chat(m1);
    expect(row.answerJson, isNull);
    expect(row.budgetJson, _at(_budget, 3));
    // The local answer is only for well-formed assistant rows.
    for (final (draft, answer) in [
      (
        const ChatMessageDraft(
          role: ChatMessageRole.user,
          text: 'x',
          status: ChatMessageStatus.queued,
        ),
        '{}',
      ),
      (
        const ChatMessageDraft(
          role: ChatMessageRole.assistant,
          text: 'x',
          status: ChatMessageStatus.done,
        ),
        '[]',
      ),
    ]) {
      expect(
        await h.reject([
          CreateChatMessage(h.ids.next(), draft, answerJson: answer),
        ]),
        const InvalidOp('chatMessageAnswer'),
      );
    }
    expect('${set(m1, 3)}', isNot(contains('revision')));
  });
}
