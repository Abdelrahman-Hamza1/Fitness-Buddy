import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/features/buddy/application/proposal_persistence_contributor.dart';
import 'package:fb_mobile/features/buddy/application/proposal_session_writer.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart'
    show GeneratorProposalIds;
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_card_writer.g.dart';

/// A card written from a `proposal` event: its one-card [session], held by
/// assistant row [holderId], built from [answer] (the stored one-intent
/// answer, for an offline rebuild). Holds user content: never logged.
final class AgentCard {
  /// A written card.
  const new({
    required this.session,
    required this.holderId,
    required this.answer,
  });

  /// The card's session (one card).
  final ProposalSession session;

  /// The holder row (the card's budget message).
  final String holderId;

  /// The one-intent answer the card was built from.
  final Map<String, Object?> answer;

  /// The card.
  ProposalCard get card => session.cards.single;

  @override
  String toString() => 'AgentCard($holderId)';
}

/// The first ID is the card's (the engine allocates the card first for a
/// meal), then fresh UUIDv7s.
final class _FirstThen implements ProposalIdSource {
  new(this._first, this._ids);

  String? _first;
  final IdGenerator _ids;

  @override
  String next() {
    final first = _first;
    _first = null;
    return first ?? _ids.next();
  }
}

/// Writes the cards of agent `proposal` events (A66 D5–D7): never a diary
/// row. A new card gets its own holder assistant row and one-card session
/// (the A23 writer, restore and undo unchanged); an update rebuilds the
/// open card into a new holder (the follow-up move); a superseded card is
/// closed without an undo. Each write is one change set with the turn's
/// checkpoint. Nothing here logs.
final class AgentCardWriter {
  /// The writer over its ports.
  const new({
    required this._apply,
    required this._ids,
    required this._loader,
    required this._contributors,
  });

  final Future<ApplyResult> Function(ChangeSet) _apply;
  final IdGenerator _ids;
  final ProposalInputLoader _loader;
  final List<ProposalPersistenceContributor> _contributors;

  static bool _never() => false;

  /// The kind of card this version builds (A67–A69 add the others).
  static const buildable = {'foodLog'};

  /// The stored one-intent answer for [intent].
  static Map<String, Object?> answerOf(
    Map<String, Object?> intent, {
    int revision = 1,
  }) => {
    'promptVersion': 'interpret-v1',
    'model': 'agent',
    'intents': [intent],
    // The card's revision as the phone shows it (A66 D6), kept with the
    // holder so it survives a restart; raised by SaveCardRevision.
    revisionKey: revision,
  };

  /// Where a holder's local answer keeps the card's revision.
  static const revisionKey = 'agentRevision';

  /// The card's compact label (history outcomes, `priorAttempt`; ≤ 120).
  static String labelOf(ProposalCard card) {
    final names = [
      for (final l in card.lines)
        if (l.entry.food.names.en.trim() case final n when n.isNotEmpty) n,
    ];
    final text = names.isEmpty ? 'Meal' : names.join(', ');
    return text.length <= 120 ? text : '${text.substring(0, 117)}...';
  }

  /// Builds card [cardId] from [intent] for user message [userId] at
  /// [referenceTime] and writes it with [checkpoint] (the user row's turn
  /// checkpoint), or `null` when it can't be a card or wasn't written.
  Future<AgentCard?> create({
    required Map<String, Object?> intent,
    required int revision,
    required String cardId,
    required String userId,
    required EntryTime referenceTime,
    required String checkpoint,
    bool Function() cancelled = _never,
  }) async {
    if (!buildable.contains(intent['kind'])) return null;
    final holderId = _ids.next();
    final answer = answerOf(intent, revision: revision);
    final session = await _build(
      answer,
      holderId,
      _FirstThen(cardId, _ids),
      referenceTime,
    );
    if (session == null ||
        session.cards.length != 1 ||
        session.cards.single.id != cardId) {
      return null;
    }
    final ops = [
      for (final c in _contributors) ...c.onReply(session, holderId),
    ];
    final written = await _holder(
      holderId,
      userId,
      labelOf(session.cards.single),
      answer,
      ops,
      checkpoint,
      cancelled,
    );
    return written
        ? AgentCard(session: session, holderId: holderId, answer: answer)
        : null;
  }

  /// Rebuilds open [card] of [from] with [intent] (an update by `replaces`)
  /// into a new holder answering [userId], keeping the card's ID and its
  /// adjustments (A22b, A23 D7), written with [checkpoint]; `null` when it
  /// can't be rebuilt or was refused (the card was resolved meanwhile).
  Future<AgentCard?> update({
    required ProposalCard card,
    required ProposalSession from,
    required SessionMembership membership,
    required Map<String, Object?> intent,
    required int revision,
    required String userId,
    required EntryTime referenceTime,
    required String checkpoint,
    bool Function() cancelled = _never,
  }) async {
    if (!buildable.contains(intent['kind']) ||
        card.lifecycle != ProposalLifecycle.active) {
      return null;
    }
    final holderId = _ids.next();
    final answer = answerOf(intent, revision: revision);
    final ProposalSession? rebuilt;
    try {
      final request = await _loader.load(
        interpretation: answer,
        messageId: holderId,
        idSource: GeneratorProposalIds(_ids),
        referenceTime: referenceTime,
        days: {card.preview.date},
      );
      final fresh = request.value;
      rebuilt = fresh == null
          ? null
          : ProposalEngine.rebuild(card, fresh).value?.session;
      // A throw is an update that can't apply (never its text).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
    final moved = rebuilt?.cards.where((c) => c.id == card.id).firstOrNull;
    if (rebuilt == null || moved == null) return null;
    final ops = [
      for (final c in _contributors)
        ...c.onFollowUp(
          moved,
          rebuilt,
          holderId,
          from: from,
          membership: membership,
        ),
    ];
    final written = await _holder(
      holderId,
      userId,
      labelOf(moved),
      answer,
      ops,
      checkpoint,
      cancelled,
    );
    return written
        ? AgentCard(session: rebuilt, holderId: holderId, answer: answer)
        : null;
  }

  /// Closes the still-pending card [cardId] of [session] that a retry replaced
  /// (06 §3.4): resolved as discarded by the system, without an undo entry.
  /// The resolved session, or `null` when nothing was written.
  Future<ProposalSession?> supersede(
    ProposalSession session,
    String cardId,
    SessionMembership membership,
  ) async {
    final resolved = ProposalEngine.recompute(
      session,
      ProposalSetLifecycle(cardId, ProposalLifecycle.discarded),
    ).value?.session;
    if (resolved == null) return null;
    final ops = ProposalSessionWriter.write(
      resolved,
      membership,
      resolve: ResolvedCard(
        cardId,
        ProposalStatus.discarded,
        ProposalOutcome.discarded,
      ),
    );
    if (ops.isEmpty) return null;
    final result = await _apply(ChangeSet(ops, origin: Origin.system));
    return result is Applied ? resolved : null;
  }

  Future<ProposalSession?> _build(
    Map<String, Object?> answer,
    String holderId,
    ProposalIdSource ids,
    EntryTime referenceTime,
  ) async {
    try {
      final request = await _loader.load(
        interpretation: answer,
        messageId: holderId,
        idSource: ids,
        referenceTime: referenceTime,
      );
      final value = request.value;
      return value == null ? null : ProposalEngine.build(value).value;
      // A throw is an event that can't become a card (never its text).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  Future<bool> _holder(
    String holderId,
    String userId,
    String label,
    Map<String, Object?> answer,
    List<ChangeOp> ops,
    String checkpoint,
    bool Function() cancelled,
  ) async {
    if (ops.isEmpty) return false;
    final json = jsonEncode(answer);
    // A stop wins over a card still being prepared: checked right before
    // the commit, with nothing awaited in between (A66 review 5).
    if (cancelled()) return false;
    final result = await _apply(
      ChangeSet([
        CreateChatMessage(
          holderId,
          ChatMessageDraft(
            role: ChatMessageRole.assistant,
            text: ChatText.sanitize(label),
            status: ChatMessageStatus.done,
            language: ChatLanguage.english,
            replyToMessageId: userId,
          ),
          answerJson: isLocalJsonObject(json) ? json : null,
        ),
        ...ops,
        SaveTurnCheckpoint(userId, checkpoint),
      ], origin: Origin.system),
    );
    return result is Applied;
  }

  @override
  String toString() => 'AgentCardWriter';
}

/// The app's agent card writer.
@Riverpod(keepAlive: true)
AgentCardWriter agentCardWriter(Ref ref) => AgentCardWriter(
  apply: ref.watch(changeSetApplierProvider).apply,
  ids: ref.watch(idGeneratorProvider),
  loader: ref.watch(proposalInputLoaderProvider),
  contributors: ref.watch(proposalPersistenceContributorsProvider),
);
