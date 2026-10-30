import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/proposal_persistence_contributor.dart';
import 'package:fb_mobile/features/buddy/data/buddy_api.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_repository.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_reader.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_buddy_message.g.dart';

/// A user message saved before dispatch (UX-052): its row ID (also the
/// interpret `requestId` and Idempotency-Key), the sanitized [text] and
/// when it was sent. Holds user content: never logged.
final class SavedBuddyMessage {
  /// Message [id] with [text] at [time].
  const new({required this.id, required this.text, required this.time});

  /// The user row's ID (UUIDv7).
  final String id;

  /// What was saved and is sent.
  final String text;

  /// The send time; the engine's reference time and the request's `now`.
  final EntryTime time;

  @override
  String toString() => 'SavedBuddyMessage($id)';
}

/// What dispatching a saved message gave.
sealed class BuddyReply {
  const new _();
}

/// Buddy answered: the user row is `done` and assistant row
/// [assistantMessageId] is saved, with [session]'s cards (none for a
/// template reply). [interpretation] is kept to rebuild a card after a
/// rejected confirm. Holds user content: never logged.
final class BuddyReplied extends BuddyReply {
  /// The reply.
  const new({
    required this.assistantMessageId,
    required this.session,
    required this.interpretation,
  }) : super._();

  /// The assistant row.
  final String assistantMessageId;

  /// The built cards, or `null` when the answer couldn't become cards.
  final ProposalSession? session;

  /// The answer JSON, or `null` with [session].
  final Map<String, Object?>? interpretation;

  @override
  String toString() => 'BuddyReplied($assistantMessageId)';
}

/// A follow-up updated open card [FollowUpTarget.card] (AI-044, A22b E2):
/// the user row is `done`, assistant row [assistantMessageId] holds the
/// rebuilt [session]'s budget, and [diff] says what changed (UX-024). The
/// card keeps its ID. Holds user content: never logged.
final class BuddyFollowedUp extends BuddyReply {
  /// The follow-up.
  const new({
    required this.assistantMessageId,
    required this.session,
    required this.diff,
    required this.interpretation,
  }) : super._();

  /// The follow-up assistant row (the card's new `budgetMessageId`).
  final String assistantMessageId;

  /// The rebuilt card's session.
  final ProposalSession session;

  /// What the rebuild changed.
  final ProposalDiff diff;

  /// The answer, to rebuild the card again after a rejected confirm.
  final Map<String, Object?> interpretation;

  @override
  String toString() => 'BuddyFollowedUp($assistantMessageId)';
}

/// The open card a message follows up on (A22b E2): the card and the time
/// of the message it came from (the engine's reference time, so "today"
/// stays the card's day). Holds user content: never logged.
final class FollowUpTarget {
  /// The target.
  const new({required this.card, required this.referenceTime});

  /// The open card.
  final ProposalCard card;

  /// The card's reference time.
  final EntryTime referenceTime;

  @override
  String toString() => 'FollowUpTarget(${card.id})';
}

/// The call failed: the user row is `failed`.
final class BuddyReplyFailed extends BuddyReply {
  /// Failed as [failure].
  const new(this.failure) : super._();

  /// Why (decides Try again, D6).
  final BuddySendFailure failure;

  @override
  String toString() => 'BuddyReplyFailed(${failure.name})';
}

/// The outcome couldn't be saved (the user row changed or is gone).
final class BuddyReplyNotSaved extends BuddyReply {
  /// The outcome.
  const new() : super._();

  @override
  String toString() => 'BuddyReplyNotSaved';
}

/// Engine IDs from the app's UUIDv7 generator.
final class GeneratorProposalIds implements ProposalIdSource {
  /// IDs from [_ids].
  const new(this._ids);

  final IdGenerator _ids;

  @override
  String next() => _ids.next();
}

/// The send path (A22 D6): save the user message (its own committed change
/// set), then interpret, build the cards and save the reply in one change
/// set with the persistence contributors' ops.
///
/// Saving a chat message has no undo (D5, PA9). Requests, answers, texts and
/// proposal results are never logged or reported; only [BuddyIssue] types
/// are.
final class SendBuddyMessage {
  /// The send path over its ports.
  const new({
    required this._apply,
    required this._ids,
    required this._clock,
    required this._api,
    required this._reader,
    required this._loader,
    required this._messages,
    required this._contributors,
    required this._report,
  });

  final Future<ApplyResult> Function(ChangeSet) _apply;
  final IdGenerator _ids;
  final Clock _clock;
  final BuddyApi _api;
  final InterpretRequestReader _reader;
  final ProposalInputLoader _loader;
  final ChatMessageRepository _messages;
  final List<ProposalPersistenceContributor> _contributors;
  final BuddyIssueSink _report;

  /// Saves [raw] as a `queued` user message (sanitized to the composer's
  /// 1000 UTF-16 units). `null` for blank text or a rejected write.
  Future<SavedBuddyMessage?> save(String raw) async {
    final text = ChatText.sanitize(raw, limit: ChatText.composerLimit);
    if (text.trim().isEmpty) return null;
    final id = _ids.next();
    final result = await _apply(
      ChangeSet([
        CreateChatMessage(
          id,
          ChatMessageDraft(
            role: ChatMessageRole.user,
            text: text,
            status: ChatMessageStatus.queued,
          ),
        ),
      ], origin: Origin.direct),
    );
    if (result is! Applied) return null;
    return SavedBuddyMessage(id: id, text: text, time: EntryTime.now(_clock));
  }

  /// The request for [message], frozen for every retry; a follow-up on
  /// [followUp] carries its bounded summary (A22b E1).
  Future<PreparedInterpret> prepare(
    SavedBuddyMessage message, {
    ProposalCard? followUp,
  }) => _reader.prepare(
    requestId: message.id,
    text: message.text,
    now: message.time,
    activeCard: followUp,
  );

  /// Sends [request] for [message] and saves the outcome (D6). With
  /// [followUp], an answer with one meal for the card's slot rebuilds that
  /// card ([BuddyFollowedUp]); anything else is a normal reply with its own
  /// cards (D21).
  Future<BuddyReply> dispatch(
    SavedBuddyMessage message,
    PreparedInterpret request,
    BuddyReplyTexts texts, {
    FollowUpTarget? followUp,
    bool followUpClosed = false,
  }) async {
    switch (await _api.interpret(request)) {
      case BuddyInterpretFailed(:final failure):
        if (failure == BuddySendFailure.rejected) {
          _report(const BuddyRequestRejected());
        }
        final saved = await _setStatus(message.id, ChatMessageStatus.failed);
        return saved ? BuddyReplyFailed(failure) : const BuddyReplyNotSaved();
      case BuddyUnusableReply():
        _report(const BuddyReplyUnusable());
        return await _reply(message, texts.noCard, null, null, null);
      case BuddyInterpreted(:final json):
        final assistantId = _ids.next();
        // The card this follow-up was about is already logged or
        // discarded: nothing is rebuilt and no new card is made from the
        // whole-meal answer (it would log the meal twice).
        if (followUpClosed) {
          return await _reply(message, texts.cardClosed, null, null, null);
        }
        if (followUp != null) {
          final update = await _rebuild(json, assistantId, followUp);
          if (update != null) {
            final saved = await _reply(
              message,
              texts.updated,
              update.session,
              json,
              assistantId,
              followUp: followUp.card,
            );
            return saved is BuddyReplied
                ? BuddyFollowedUp(
                    assistantMessageId: assistantId,
                    session: update.session,
                    diff: update.diff,
                    interpretation: json,
                  )
                : saved;
          }
        }
        final session = await _build(json, assistantId, message.time);
        if (session == null) {
          _report(const BuddyReplyUnusable());
          return await _reply(message, texts.noCard, null, null, assistantId);
        }
        bool routed(String kind) => session.routing.any((i) => i.kind == kind);
        // A routed part next to the cards still gets its fixed sentence
        // (cards first), so it isn't silently dropped (A22a review).
        final routing = routed('medical')
            ? texts.medical
            : routed('unrecognized')
            ? texts.unsupported
            : null;
        final text = session.cards.isNotEmpty
            ? (routing == null ? texts.cards : '${texts.cards} $routing')
            : routing ?? texts.notFood;
        return await _reply(message, text, session, json, assistantId);
    }
  }

  Future<ProposalSession?> _build(
    Map<String, Object?> json,
    String assistantId,
    EntryTime time,
  ) async {
    try {
      final request = await _loader.load(
        interpretation: json,
        messageId: assistantId,
        idSource: GeneratorProposalIds(_ids),
        referenceTime: time,
      );
      final value = request.value;
      return value == null ? null : ProposalEngine.build(value).value;
      // Anything the loader or engine throws (an Error included) is a reply
      // that can't become a card: the fixed template, the type reported by
      // the caller, never the thrown object's text (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// The follow-up's rebuild of [target]'s card (A22b E2): only for an
  /// answer with exactly one meal, rebuilt by the engine (matched lines keep
  /// their IDs and adjustments), whose slot is the card's unless the answer
  /// names none. `null` otherwise: the answer becomes a normal reply.
  Future<ProposalUpdate?> _rebuild(
    Map<String, Object?> json,
    String assistantId,
    FollowUpTarget target,
  ) async {
    final intents = json['intents'];
    if (intents is! List<Object?>) return null;
    final meals = [
      for (final i in intents)
        if (i is Map<String, Object?> && i['kind'] == 'foodLog') i,
    ];
    if (meals.length != 1) return null;
    try {
      final request = await _loader.load(
        interpretation: json,
        messageId: assistantId,
        idSource: GeneratorProposalIds(_ids),
        referenceTime: target.referenceTime,
        // The card's own day, which the answer may not name.
        days: {target.card.preview.date},
      );
      final fresh = request.value;
      if (fresh == null) return null;
      final update = ProposalEngine.rebuild(target.card, fresh).value;
      final card = update?.session.cards
          .where((c) => c.id == target.card.id)
          .firstOrNull;
      if (update == null || card == null) return null;
      // Another explicit slot is another meal: a new card (D21).
      final hint = meals.single['slotHint'];
      final slot = card.lines.firstOrNull?.entry.slotId;
      final before = target.card.lines.firstOrNull?.entry.slotId;
      if (hint is String && hint.trim().isNotEmpty && slot != before) {
        return null;
      }
      return update;
      // As in [_build]: a throw is an answer that can't update the card.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  Future<BuddyReply> _reply(
    SavedBuddyMessage message,
    String text,
    ProposalSession? session,
    Map<String, Object?>? json,
    String? assistantId, {
    ProposalCard? followUp,
  }) async {
    final user = await _messages.byId(message.id);
    if (user == null) return const BuddyReplyNotSaved();
    final id = assistantId ?? _ids.next();
    String? budget;
    if (session != null && session.cards.isNotEmpty) {
      budget = jsonEncode(ProposalDraftCodec.encodeMessageBudget(session));
      if (!ProposalDraftCodec.fitsSyncString(budget)) {
        budget = null;
        _report(const BuddyBudgetTooLarge());
      }
    }
    final result = await _apply(
      ChangeSet([
        SetChatMessageStatus(
          user.id,
          user.version,
          ChatMessageStatus.done,
          language: json == null ? null : languageOf(json),
        ),
        CreateChatMessage(
          id,
          ChatMessageDraft(
            role: ChatMessageRole.assistant,
            text: ChatText.sanitize(text),
            status: ChatMessageStatus.done,
            language: ChatLanguage.english,
            replyToMessageId: user.id,
            codecVersion: budget == null ? null : 1,
            budgetJson: budget,
          ),
        ),
        if (session != null)
          for (final c in _contributors)
            ...(followUp == null
                ? c.onReply(session, id)
                : c.onFollowUp(
                    session.cards.firstWhere((x) => x.id == followUp.id),
                    session,
                    id,
                  )),
      ], origin: Origin.system),
    );
    if (result is! Applied) return const BuddyReplyNotSaved();
    return BuddyReplied(
      assistantMessageId: id,
      session: session,
      interpretation: session == null ? null : json,
    );
  }

  Future<bool> _setStatus(String id, ChatMessageStatus status) async {
    final row = await _messages.byId(id);
    if (row == null) return false;
    final result = await _apply(
      ChangeSet([
        SetChatMessageStatus(row.id, row.version, status),
      ], origin: Origin.system),
    );
    return result is Applied;
  }

  /// The message language from the answer's intents (D8): each intent's
  /// `language` and `script` normalized, unanimous, else `null`.
  static ChatLanguage? languageOf(Map<String, Object?> interpretation) {
    final intents = interpretation['intents'];
    if (intents is! List<Object?>) return null;
    return ChatLanguage.unanimous([
      for (final intent in intents)
        if (intent is Map<String, Object?>)
          ChatLanguage.normalize(
            _string(intent['language']),
            _string(intent['script']),
          )
        else
          null,
    ]);
  }

  static String? _string(Object? value) => value is String ? value : null;

  @override
  String toString() => 'SendBuddyMessage';
}

/// The app's send path.
@Riverpod(keepAlive: true)
SendBuddyMessage sendBuddyMessage(Ref ref) => SendBuddyMessage(
  apply: ref.watch(changeSetApplierProvider).apply,
  ids: ref.watch(idGeneratorProvider),
  clock: ref.watch(clockProvider),
  api: ref.watch(buddyApiProvider),
  reader: ref.watch(interpretRequestReaderProvider),
  loader: ref.watch(proposalInputLoaderProvider),
  messages: ref.watch(chatMessageRepositoryProvider),
  contributors: ref.watch(proposalPersistenceContributorsProvider),
  report: ref.watch(buddyIssueSinkProvider),
);
