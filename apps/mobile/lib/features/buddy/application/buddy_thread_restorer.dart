import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_state.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/records/record_cards.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:fb_mobile/features/buddy/application/turn/agent_card_writer.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_repository.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/buddy/data/proposal_mappers.dart';
import 'package:fb_mobile/features/buddy/data/proposal_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_thread_restorer.g.dart';

/// The thread read back from the database (A23 D12): turns in display
/// order and which cards left their messages.
final class RestoredThread {
  /// The restored thread.
  const new({
    required this.turns,
    required this.membership,
    this.orphans = const [],
  });

  /// Pending cards with no turn to show them in (A23 D13).
  final List<UnrestorableCard> orphans;

  /// The turns, oldest first, with their cards and placeholders.
  final List<BuddyTurn> turns;

  /// Departures and follow-up replies from the stored budgets.
  final SessionMembership membership;

  @override
  String toString() => 'RestoredThread(${turns.length} turns)';
}

/// Reads Buddy's stored sessions back (A23 D10, D12, D13): an assistant
/// row's budget plus every live card bound to it (`budgetMessageId`),
/// restored by the codec with current facts, and the turns they belong to.
/// Read-only; the database is the truth after a revert. Results are never
/// logged; only an issue type is reported.
final class BuddyThreadRestorer {
  /// The restorer over its read ports.
  const new({
    required this._messages,
    required this._proposals,
    required this._loader,
    this._clock,
    this._report,
    this._records,
  });

  final ChatMessageRepository _messages;
  final ProposalRepository _proposals;
  final ProposalInputLoader _loader;
  final Clock? _clock;
  final BuddyIssueSink? _report;
  final RecordCards? _records;

  /// Every session with a live pending card, as turns keyed by their user
  /// message (A23 D12): cards under the turn of their `originMessageId`,
  /// resolved siblings as resolved rows, cards of a session that can't be
  /// reopened as placeholders (D13). [generation] stamps the turns.
  Future<RestoredThread> restore({required int generation}) async {
    final all = await _proposals.pending();
    // Record cards (A67) reopen on their own: re-planned from current rows.
    final recordRows = [
      for (final r in all)
        if (RecordKind.fromCode(r.kind) != null) r,
    ];
    final pending = [
      for (final r in all)
        if (RecordKind.fromCode(r.kind) == null) r,
    ];
    final budgets = <String>[
      for (final m in {for (final r in pending) ?r.budgetMessageId}) m,
    ];
    final turns = <String, _TurnDraft>{};
    final orphans = <UnrestorableCard>[
      // No message refs (a synced row not made by chat): nowhere to show.
      // Other kinds without refs belong elsewhere (A38's weekly check-in
      // shows on Progress), not in the chat.
      for (final r in pending)
        if (r.budgetMessageId == null && r.kind == foodLogKind)
          UnrestorableCard(record: r, issue: ProposalIssue.invalidInput),
    ];
    var membership = const SessionMembership();
    final rows = <String, ChatMessage?>{};
    Future<ChatMessage?> row(String id) async =>
        rows.containsKey(id) ? rows[id] : rows[id] = await _messages.byId(id);
    Future<_TurnDraft?> turnOf(String originId) async {
      final origin = await row(originId);
      final userId = origin?.replyToMessageId;
      if (origin == null || userId == null) return null;
      final user = await row(userId);
      if (user == null || user.role != ChatMessageRole.user) return null;
      return turns[userId] ??= _TurnDraft(user, origin, await _answer(origin));
    }

    for (final budgetId in budgets) {
      final message = await row(budgetId);
      final records = await _proposals.byBudgetMessage(budgetId);
      final ProposalBuildResult result;
      if (message == null) {
        result = const ProposalResult.failure(ProposalIssue.sessionIncomplete);
      } else {
        final origin = records.firstOrNull?.originMessageId;
        final originRow = origin == null ? null : await row(origin);
        final user = originRow?.replyToMessageId == null
            ? null
            : await row(originRow!.replyToMessageId!);
        result = await session(
          budgetId,
          referenceTime: _timeOf(user ?? message),
        );
      }
      final restored = result.value;
      if (restored == null) {
        _report?.call(BuddyRestoreIssue(result.issue!));
        for (final record in records.where((r) => r.isPending)) {
          final turn = record.originMessageId == null
              ? null
              : await turnOf(record.originMessageId!);
          final card = UnrestorableCard(record: record, issue: result.issue!);
          if (turn == null) {
            orphans.add(card);
          } else {
            turn.unrestorable.add(card);
          }
        }
        continue;
      }
      final budget = ProposalDraftCodec.messageFromSync(message!.budgetJson);
      final departed = budget.value?['departed'];
      if (departed is List<Object?>) {
        for (final id in departed.whereType<String>()) {
          membership = membership.merge(
            const SessionMembership().rebuilt(id, budgetId),
          );
        }
      }
      final answer = await _answer(message);
      for (final card in restored.cards) {
        final turn = await turnOf(card.originMessageId);
        if (turn == null) {
          // Its origin turn is gone (cleared or never synced): a pending
          // card still gets a place to be discarded.
          final record = records.where((r) => r.id == card.id).firstOrNull;
          if (record != null && record.isPending) {
            orphans.add(
              UnrestorableCard(
                record: record,
                issue: ProposalIssue.sessionIncomplete,
              ),
            );
          }
          continue;
        }
        final moved = card.budgetMessageId != card.originMessageId;
        if (moved && message.replyToMessageId != null) {
          membership = membership.merge(
            SessionMembership(followUps: {budgetId}),
          );
        }
        if (card.issues.any(
          (i) =>
              i == ProposalIssue.staleFacts || i == ProposalIssue.factsMismatch,
        )) {
          _report?.call(BuddyRestoreIssue(card.issues.first));
        }
        turn.cards.add(
          BuddyCard(
            id: card.id,
            session: restored,
            resolution: switch (card.lifecycle) {
              ProposalLifecycle.active => CardResolution.open,
              ProposalLifecycle.confirmed => CardResolution.logged,
              ProposalLifecycle.discarded => CardResolution.discarded,
              ProposalLifecycle.superseded => CardResolution.superseded,
            },
            rebuilt: moved && message.replyToMessageId == null,
            // The revision the phone showed (A66 D6), kept with the holder.
            revision: switch (answer?[AgentCardWriter.revisionKey]) {
              final int r when r >= 1 => r,
              _ => 1,
            },
            // Each card's own answer (an agent card's holder holds one).
            origin: answer == null
                ? null
                : CardOrigin(
                    interpretation: answer,
                    messageId: budgetId,
                    referenceTime: turn.time(this),
                  ),
          ),
        );
      }
    }
    for (final record in recordRows) {
      final origin = record.originMessageId;
      final turn = origin == null ? null : await turnOf(origin);
      if (turn == null) {
        orphans.add(
          UnrestorableCard(
            record: record,
            issue: ProposalIssue.sessionIncomplete,
          ),
        );
        continue;
      }
      final holder = record.budgetMessageId == null
          ? null
          : await row(record.budgetMessageId!);
      final answer = holder == null ? null : await _answer(holder);
      final card = await _records?.restore(
        record,
        turn.time(this),
        revision: switch (answer?[AgentCardWriter.revisionKey]) {
          final int r when r >= 1 => r,
          _ => 1,
        },
      );
      if (card == null) {
        turn.unrestorable.add(
          UnrestorableCard(record: record, issue: ProposalIssue.staleFacts),
        );
      } else {
        turn.records.add(card);
      }
    }
    // The latest turns, with or without cards (A66 review 9): user rows,
    // their reply rows and the reply's local question and trace.
    final recent = await _messages.recent(historyRows);
    final users = [
      for (final m in recent)
        if (m.role == ChatMessageRole.user) m,
    ];
    for (final user in users.skip(
      users.length > historyTurns ? users.length - historyTurns : 0,
    )) {
      turns[user.id] ??= _TurnDraft(user, null, null);
    }
    for (final m in recent) {
      final to = m.replyToMessageId;
      if (m.role != ChatMessageRole.assistant || to == null) continue;
      final turn = turns[to];
      if (turn == null || m.budgetJson != null || turn.reply != null) continue;
      turn
        ..reply = m
        ..meta = await _answer(m);
    }
    // Resolved record cards of the turns shown keep their outcome rows
    // (A67 review 6): read by their holders, never re-planned as open.
    final records = _records;
    if (records != null) {
      final holders = {
        for (final m in recent)
          if (m.role == ChatMessageRole.assistant &&
              m.budgetJson == recordHolderBudget &&
              turns.containsKey(m.replyToMessageId))
            m.id: m.replyToMessageId!,
      };
      final shown = {
        for (final t in turns.values) ...t.records.map((r) => r.id),
      };
      for (final r in await _proposals.byOrigins(holders.keys.toSet())) {
        final turn = turns[holders[r.originMessageId]];
        if (turn == null ||
            r.isPending ||
            shown.contains(r.id) ||
            RecordKind.fromCode(r.kind) == null) {
          continue;
        }
        final card = await records.restore(
          r,
          turn.time(this),
          requireView: false,
        );
        if (card == null) continue;
        shown.add(r.id);
        turn.records.add(
          card.copyWith(
            resolution: switch (r.status) {
              ProposalStatus.confirmed => CardResolution.logged,
              ProposalStatus.superseded => CardResolution.superseded,
              _ => CardResolution.discarded,
            },
          ),
        );
      }
    }
    final ordered = turns.values.toList()
      ..sort(
        (a, b) => a.user.createdAt.compareTo(b.user.createdAt) != 0
            ? a.user.createdAt.compareTo(b.user.createdAt)
            : a.user.id.compareTo(b.user.id),
      );
    return RestoredThread(
      turns: [for (final t in ordered) t.build(this, generation)],
      membership: membership,
      orphans: orphans,
    );
  }

  /// The chat rows read for history, and the turns shown from them.
  static const historyRows = 120;

  /// See [historyRows].
  static const historyTurns = 20;

  /// The local interpret answer of [message] (A23 D14), or `null`.
  Future<Map<String, Object?>?> _answer(ChatMessage message) async {
    final text = await _messages.answerOf(message.id);
    if (text == null) return null;
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// [message]'s time in the zone it was written in (the phone's offset
  /// then).
  EntryTime _timeOf(ChatMessage message) {
    final clock = _clock;
    return clock == null
        ? EntryTime(message.createdAt, 0)
        : EntryTime.at(message.createdAt, clock);
  }

  /// The stored session of assistant message [messageId], with
  /// [referenceTime] for the day context. A missing row, budget or card is
  /// a fixed issue, never a throw.
  Future<ProposalBuildResult> session(
    String messageId, {
    required EntryTime referenceTime,
  }) async {
    try {
      final message = await _messages.byId(messageId);
      if (message == null) {
        return const ProposalResult.failure(ProposalIssue.sessionIncomplete);
      }
      final budget = ProposalDraftCodec.messageFromSync(message.budgetJson);
      if (budget.issue case final issue?) return ProposalResult.failure(issue);
      final cards = <Map<String, Object?>>[];
      for (final record in await _proposals.byBudgetMessage(messageId)) {
        final card = proposalRestoreCard(record);
        if (card.issue case final issue?) return ProposalResult.failure(issue);
        cards.add(card.value!);
      }
      return await _loader.restore(
        message: budget.value!,
        cards: cards,
        referenceTime: referenceTime,
      );
      // A read failure is a session that can't be reopened; its text never
      // leaves here.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return const ProposalResult.failure(ProposalIssue.invalidInput);
    }
  }

  @override
  String toString() => 'BuddyThreadRestorer';
}

/// A turn being assembled from stored rows.
final class _TurnDraft {
  new(this.user, this.assistant, this.answer);

  final ChatMessage user;

  /// The first card holder (or the A23 reply holding the session).
  final ChatMessage? assistant;
  final Map<String, Object?>? answer;

  /// The reply text row (no budget), and its local question/trace.
  ChatMessage? reply;
  Map<String, Object?>? meta;
  final List<BuddyCard> cards = [];
  final List<RecordCard> records = [];
  final List<UnrestorableCard> unrestorable = [];

  EntryTime time(BuddyThreadRestorer restorer) => restorer._timeOf(user);

  BuddyTurn build(BuddyThreadRestorer restorer, int generation) => BuddyTurn(
    message: SavedBuddyMessage(
      id: user.id,
      text: user.text,
      time: time(restorer),
    ),
    phase: switch (user.status) {
      ChatMessageStatus.done => BuddyTurnPhase.replied,
      ChatMessageStatus.failed => BuddyTurnPhase.failed,
      // Waiting or interrupted: the queue resumes this install's own rows.
      ChatMessageStatus.queued ||
      ChatMessageStatus.processing ||
      ChatMessageStatus.pendingOffline => BuddyTurnPhase.pending,
    },
    assistantMessageId: reply?.id ?? assistant?.id,
    interpretation: answer,
    // Creation order: card IDs are UUIDv7s allocated in order.
    cards: cards..sort((a, b) => a.id.compareTo(b.id)),
    records: records..sort((a, b) => a.id.compareTo(b.id)),
    unrestorable: unrestorable,
    profileGeneration: generation,
    question: switch (meta?['question']) {
      {'text': final String text, 'options': final List<Object?> options} =>
        BuddyQuestion(text, [...options.whereType<String>()]),
      _ => null,
    },
    trace: [
      if (meta?['trace'] case final List<Object?> steps)
        for (final step in steps)
          if (step case {
            'tool': final String tool,
            'args': final String args,
            'resultSummary': final String result,
            'ms': final int ms,
            'tokens': final int tokens,
            'usd': final num usd,
          })
            TraceStepView(
              tool: tool,
              args: args,
              resultSummary: result,
              ms: ms,
              tokens: tokens,
              usd: usd.toDouble(),
            ),
    ],
  );
}

/// The app's restorer (per profile: its repositories watch the database).
@Riverpod(keepAlive: true)
BuddyThreadRestorer buddyThreadRestorer(Ref ref) => BuddyThreadRestorer(
  messages: ref.watch(chatMessageRepositoryProvider),
  proposals: ref.watch(proposalRepositoryProvider),
  loader: ref.watch(proposalInputLoaderProvider),
  clock: ref.watch(clockProvider),
  report: ref.watch(buddyIssueSinkProvider),
  records: ref.watch(recordCardsProvider),
);
