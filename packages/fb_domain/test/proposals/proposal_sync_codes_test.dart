import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import 'proposal_fixtures.dart';
import 'proposal_recompute_test.dart' show update;

Map<String, Object?> _object(Object? value) => value! as Map<String, Object?>;

/// `entities.<entity>."1"` in the sync-entities contract.
Map<String, Object?> _schema(String entity) {
  final root = Directory.current.path.endsWith('fb_domain') ? '../..' : '.';
  final contract = _object(
    jsonDecode(
      File('$root/contracts/openapi/sync-entities.json').readAsStringSync(),
    ),
  );
  return _object(_object(_object(contract['entities'])[entity])['1']);
}

/// Properties of [_schema].
Map<String, Map<String, Object?>> _contract(String entity) =>
    _object(_schema(entity)['properties'])
        .map((key, value) => MapEntry(key, _object(value)));

void main() {
  // rule: B18 contract-handoff
  test('B18 sync codes and bounds equal the sync-entities contract', () {
    final chat = _contract('chatMessage');
    final proposal = _contract('proposal');
    expect(chat.keys, [
      'createdAtMs',
      'origin',
      'editedByUser',
      'role',
      'text',
      'status',
      'language',
      'replyToMessageId',
      'codecVersion',
      'budgetJson',
    ]);
    expect(proposal.keys, [
      'createdAtMs',
      'origin',
      'editedByUser',
      'kind',
      'status',
      'outcome',
      'resolvedAtMs',
      'originMessageId',
      'budgetMessageId',
      'codecVersion',
      'interpretationJson',
      'draftJson',
    ]);
    expect(chat['role']!['enum'], [
      for (final v in ChatMessageRole.values) v.code,
    ]);
    expect(chat['status']!['enum'], [
      for (final v in ChatMessageStatus.values) v.code,
    ]);
    expect(proposal['status']!['enum'], [
      for (final v in ProposalStatus.values) v.code,
    ]);
    expect(proposal['outcome']!['enum'], [
      for (final v in ProposalOutcome.values) v.code,
      null,
    ]);
    for (final field in [
      chat['budgetJson']!,
      proposal['interpretationJson']!,
      proposal['draftJson']!,
    ]) {
      expect(field['maxLength'], ChatProposalSyncBounds.json);
    }
    expect(ChatProposalSyncBounds.json, 32768);
    expect(chat['text']!['maxLength'], ChatProposalSyncBounds.text);
    expect(chat['language']!['maxLength'], ChatProposalSyncBounds.language);
    expect(proposal['kind']!['maxLength'], ChatProposalSyncBounds.kind);
    for (final entity in [chat, proposal]) {
      expect(entity['origin']!['maxLength'], ChatProposalSyncBounds.origin);
      expect(
        entity['codecVersion']!['minimum'],
        ChatProposalSyncBounds.codecVersionMin,
      );
      expect(
        entity['codecVersion']!['maximum'],
        ChatProposalSyncBounds.codecVersionMax,
      );
    }
    // Nullable only on chatMessage (user rows carry no budget).
    expect(chat['codecVersion']!['type'], ['integer', 'null']);
    expect(proposal['codecVersion']!['type'], 'integer');
    for (final field in [
      proposal['originMessageId']!,
      proposal['budgetMessageId']!,
      proposal['interpretationJson']!,
      chat['replyToMessageId']!,
      chat['language']!,
      chat['budgetJson']!,
    ]) {
      expect(field['type'], ['string', 'null']);
    }
    expect(proposal['draftJson']!['type'], 'string');
    for (final ref in [
      proposal['originMessageId']!,
      proposal['budgetMessageId']!,
      chat['replyToMessageId']!,
    ]) {
      expect(ref['format'], 'uuid');
      expect(ref['maxLength'], 36);
    }
    expect(proposal['resolvedAtMs']!['type'], ['integer', 'null']);
    expect(proposal['resolvedAtMs']!['minimum'], 0);
    expect(proposal['resolvedAtMs']!['maximum'], 9007199254740991);
    for (final entity in ['chatMessage', 'proposal']) {
      final schema = _schema(entity);
      expect(
        (schema['required']! as List<Object?>).toSet(),
        _contract(entity).keys.toSet(),
      );
      expect(schema['additionalProperties'], isFalse);
    }
  });

  // rule: B18 contract-handoff
  test('AI-045 engine lifecycle maps to stored pending confirmed discarded '
      'and never superseded', () {
    expect(
      {
        for (final l in ProposalLifecycle.values)
          l: ProposalStatus.ofLifecycle(l),
      },
      {
        ProposalLifecycle.active: ProposalStatus.pending,
        ProposalLifecycle.confirmed: ProposalStatus.confirmed,
        ProposalLifecycle.discarded: ProposalStatus.discarded,
        ProposalLifecycle.superseded: ProposalStatus.superseded,
      },
    );
    // The engine builds active cards and the app observes confirm/discard;
    // the engine never originates superseded; only the application marks a
    // row superseded (historical).
    final s = session(
      message([
        intent([item()]),
        intent([riceItem()], slot: 'dinner'),
      ]),
    );
    expect(s.cards.map((c) => ProposalStatus.ofLifecycle(c.lifecycle)), [
      ProposalStatus.pending,
      ProposalStatus.pending,
    ]);
    for (final observed in [
      ProposalLifecycle.confirmed,
      ProposalLifecycle.discarded,
    ]) {
      final next = update(
        s,
        ProposalSetLifecycle(s.cards.first.id, observed),
      ).session;
      expect(
        next.cards.map((c) => ProposalStatus.ofLifecycle(c.lifecycle)),
        isNot(contains(ProposalStatus.superseded)),
      );
    }
  });

  // rule: B18 contract-handoff
  test('B18 unknown wire codes decode to null', () {
    for (final v in ChatMessageRole.values) {
      expect(ChatMessageRole.fromCode(v.code), v);
    }
    for (final v in ChatMessageStatus.values) {
      expect(ChatMessageStatus.fromCode(v.code), v);
    }
    for (final v in ProposalStatus.values) {
      expect(ProposalStatus.fromCode(v.code), v);
    }
    for (final v in ProposalOutcome.values) {
      expect(ProposalOutcome.fromCode(v.code), v);
    }
    for (final code in [null, '', 'system', 'User', 'ASSISTANT', ' user']) {
      expect(ChatMessageRole.fromCode(code), isNull);
    }
    for (final code in [null, 'sent', 'pendingOffline', 'Done', 'pending']) {
      expect(ChatMessageStatus.fromCode(code), isNull);
    }
    for (final code in [null, 'active', 'Pending', 'resolved', 'adjusted']) {
      expect(ProposalStatus.fromCode(code), isNull);
    }
    for (final code in [null, 'adjusted chips', 'Adjusted', 'confirmed']) {
      expect(ProposalOutcome.fromCode(code), isNull);
    }
  });
}
