import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' show CancelToken;
import 'package:fb_api_client/fb_api_client.dart' hide LocalDate;
import 'package:fb_domain/fb_domain.dart' show LocalDate, QueryLink;
import 'package:fb_mobile/features/buddy/data/buddy_turn_api.dart';
import 'package:fb_mobile/features/buddy/data/phone_tools.dart';
import 'package:fb_mobile/features/buddy/data/turn/turn_checkpoint.dart';

/// How a turn ended (A66 D3).
enum TurnEndKind {
  /// `done` arrived.
  done,

  /// Not processed yet (offline, unavailable): posted again later.
  pending,

  /// The user stopped it.
  stopped,

  /// Today's limit (429).
  rateLimited,

  /// Failed for good: Try again sends the text as a new message.
  failed,
}

/// The end of a turn.
final class TurnEnd {
  /// An end; [reason] is `done`'s reason (`answered`, `limit`, …).
  const new(this.kind, {this.reason});

  /// How it ended.
  final TurnEndKind kind;

  /// For [TurnEndKind.done]: the `done` event's reason wire code, or null.
  final String? reason;

  @override
  String toString() => 'TurnEnd(${kind.name})';
}

/// The card a `replaces` names and the revision it must still have.
typedef TurnReplaces = ({String proposalId, int expectedRevision});

/// Where an earlier attempt's card stands, for `priorAttempt` (06 §3.4).
enum PriorCardState {
  /// Logged.
  confirmed,

  /// Discarded.
  discarded,

  /// Still open.
  pending,
}

/// One step of a turn's dev trace (AI-172): local only, never logged.
final class TraceLine {
  /// A line.
  const new({
    required this.tool,
    required this.args,
    required this.resultSummary,
    required this.ms,
    required this.tokens,
    required this.usd,
  });

  /// The tool.
  final String tool;

  /// Its arguments as the server summarised them.
  final String args;

  /// What came back, summarised.
  final String resultSummary;

  /// How long it took.
  final int ms;

  /// Tokens used.
  final int tokens;

  /// Estimated cost, USD.
  final double usd;

  /// The JSON form (stored locally with the reply).
  Map<String, Object?> toJson() => {
    'tool': tool,
    'args': args,
    'resultSummary': resultSummary,
    'ms': ms,
    'tokens': tokens,
    'usd': usd,
  };

  @override
  String toString() => 'TraceLine($tool)';
}

/// A `proposal` event the runner hands over: its IDs, the raw intent JSON
/// and, for an update, the card it updates. Holds user content.
final class TurnProposal {
  /// A proposal.
  const new({
    required this.proposalId,
    required this.revision,
    required this.replaces,
    required this.intent,
    required this.round,
    required this.attempt,
    this.target,
  });

  /// The server's ID.
  final String proposalId;

  /// Its revision.
  final int revision;

  /// The card it updates, or `null` for a new card.
  final TurnReplaces? replaces;

  /// The raw `intent` object.
  final Map<String, Object?> intent;

  /// The round it came in.
  final int round;

  /// The attempt of [round].
  final int attempt;

  /// The card a `replaces` names, when known.
  final CheckpointCard? target;

  @override
  String toString() => 'TurnProposal($proposalId)';
}

/// The thread side of a running turn (the controller): live display, card
/// writes and the checkpoint. Every write goes through `ChangeSetApplier`
/// in the host; the runner only decides.
abstract interface class TurnHost {
  /// Saves [checkpoint] (the user row stays `processing`).
  Future<void> save(TurnCheckpoint checkpoint);

  /// A live step, by its wire code (`searchingFoods`, …).
  void step(String code);

  /// A reply text chunk.
  void text(String chunk);

  /// The reply text so far is dropped (a retry re-runs the round).
  void resetText();

  /// A question with chips.
  void question(String text, List<String> options);

  /// Trace steps (dev only).
  void trace(List<TraceLine> steps);

  /// The links of this round's answered `queryData` calls (AI-112).
  void links(List<QueryLink> links);

  /// Writes [proposal] as a new card (with a fresh card ID) or an update of
  /// its target, together with the checkpoint [withCard] builds from the
  /// card it wrote. The new checkpoint, or `null` when nothing was written
  /// (dropped, unbuildable, or another kind).
  Future<TurnCheckpoint?> proposal(
    TurnProposal proposal,
    TurnCheckpoint Function(CheckpointCard card) withCard,
  );

  /// The earlier attempt's still-pending cards [cardIds] are dropped
  /// (superseded) on a retry (06 §3.4).
  Future<void> supersede(List<String> cardIds);

  /// Where card [cardId] stands, for `priorAttempt`, with its label.
  ({PriorCardState status, String line, int revision})? priorCard(
    String cardId,
  );

  /// Stores a `summary` (only when the stored revision is still
  /// [revision] - 1).
  Future<void> summary(String text, int revision, String watermark);
}

/// Runs one Buddy turn round by round (06 §2, §3.4; A66 D2, D3): posts the
/// checkpoint's round, handles its events in order, runs phone tools and
/// posts `continue`, retries an ambiguous round once with `priorAttempt`,
/// and stops for good on [BuddyTurnRunner.stop]. Nothing here logs.
final class BuddyTurnRunner {
  /// A runner for one turn over its host.
  new(
    this._host, {
    required this._api,
    required this._tools,
    required this._today,
  });

  final TurnHost _host;
  final BuddyTurnApi _api;
  final PhoneTools _tools;
  final LocalDate _today;
  CancelToken? _cancel;
  bool _stopped = false;

  /// Whether the user stopped the turn.
  bool get stopped => _stopped;

  /// Stops the turn: the stream closes, nothing later is handled, no
  /// `continue` is posted and it is never retried (AI-171).
  void stop() {
    _stopped = true;
    _cancel?.cancel();
  }

  /// Runs from [checkpoint]. [resumed]: the round may have reached the
  /// server before (a restart): it is the one retry.
  Future<TurnEnd> run(TurnCheckpoint checkpoint, {bool resumed = false}) async {
    var cp = checkpoint;
    if (cp.stopped) return const TurnEnd(TurnEndKind.stopped);
    if (resumed) {
      final retry = await _retry(cp);
      if (retry == null) return const TurnEnd(TurnEndKind.failed);
      cp = retry;
    }
    while (true) {
      if (_stopped) return await _stop(cp);
      final cancel = _cancel = CancelToken();
      final body = {
        ...cp.body,
        'priorAttempt': cp.attempt > 1 ? _prior(cp) : null,
      };
      final post = await switch (cp.kind) {
        TurnRoundKind.start => _api.start(body, cancel: cancel),
        TurnRoundKind.resume => _api.resume(body, cancel: cancel),
      };
      if (_stopped) return await _stop(cp);
      switch (post) {
        case TurnRefused(:final refusal):
          switch (refusal) {
            case TurnRefusal.pending:
              return const TurnEnd(TurnEndKind.pending);
            case TurnRefusal.ambiguous:
              final retry = await _retry(cp);
              if (retry == null) return const TurnEnd(TurnEndKind.failed);
              cp = retry;
              continue;
            case TurnRefusal.rateLimited:
              return const TurnEnd(TurnEndKind.rateLimited);
            case TurnRefusal.alreadyRan:
            case TurnRefusal.rejected:
              return const TurnEnd(TurnEndKind.failed);
          }
        case TurnStreaming(:final frames):
          final outcome = await _read(cp, frames);
          if (_stopped) return await _stop(outcome.checkpoint);
          cp = outcome.checkpoint;
          switch (outcome.next) {
            case _Next.done:
              return TurnEnd(TurnEndKind.done, reason: outcome.reason);
            case _Next.round:
              continue;
            case _Next.retry:
              final retry = await _retry(cp);
              if (retry == null) return const TurnEnd(TurnEndKind.failed);
              cp = retry;
              continue;
            case _Next.failed:
              return const TurnEnd(TurnEndKind.failed);
          }
      }
    }
  }

  Future<TurnEnd> _stop(TurnCheckpoint cp) async {
    try {
      await _host.save(cp.copyWith(stopped: true));
      // The stop stands whether or not it was recorded.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
    return const TurnEnd(TurnEndKind.stopped);
  }

  /// The one retry of [cp]'s round (attempt 2), saved; `null` when the
  /// round was already retried or the user stopped.
  Future<TurnCheckpoint?> _retry(TurnCheckpoint cp) async {
    if (_stopped || cp.attempt >= 2) return null;
    final next = cp.copyWith(attempt: cp.attempt + 1);
    await _host.save(next);
    _host.resetText();
    return next;
  }

  /// The earlier attempt's cards of [cp]'s round, as `priorAttempt` JSON
  /// (an empty list when nothing arrived).
  Map<String, Object?> _prior(TurnCheckpoint cp) => jsonDecode(
    jsonEncode(
      BuddyPriorAttempt(
        attempt: cp.attempt - 1,
        cards: [
          for (final c in cp.cards)
            if (c.round == cp.round && c.attempt < cp.attempt)
              if (_host.priorCard(c.cardId) case final p?)
                BuddyPriorCard(
                  proposalId: c.proposalId,
                  status: switch (p.status) {
                    PriorCardState.confirmed => BuddyPriorCardStatus.confirmed,
                    PriorCardState.discarded => BuddyPriorCardStatus.discarded,
                    PriorCardState.pending => BuddyPriorCardStatus.pending,
                  },
                  revision: p.revision,
                  line: p.line,
                ),
        ].take(12).toList(),
      ).toJson(),
    ),
  ) as Map<String, Object?>;

  Future<_RoundOutcome> _read(
    TurnCheckpoint start,
    Stream<TurnFrame> frames,
  ) async {
    var cp = start;
    var seq = -1;
    var reconciled = cp.attempt == 1;
    final prefix = '${cp.turnId}:${cp.round}:';
    // The earlier attempt's cards this attempt updated: they stay.
    final updated = <String>{};
    // At the round's end (its phone round or done, never before its
    // updates could arrive), the earlier attempt's cards that this attempt
    // didn't update are dropped; confirmed ones stay (06 §3.4).
    Future<void> reconcile() async {
      if (reconciled || _stopped) return;
      reconciled = true;
      await _host.supersede([
        for (final c in cp.cards)
          if (c.round == cp.round &&
              c.attempt < cp.attempt &&
              !updated.contains(c.cardId))
            c.cardId,
      ]);
    }

    try {
      await for (final frame in frames) {
        if (_stopped) break;
        // Events of another turn or round, or out of order: ignored.
        if (frame.id case final id?) {
          if (!id.startsWith(prefix)) continue;
          final n = int.tryParse(id.substring(prefix.length));
          if (n == null || n <= seq) continue;
          seq = n;
        }
        switch (frame.event) {
          case BuddyTurnEventStep(:final code):
            _host.step(code.json ?? 'working');
          case BuddyTurnEventText(:final text):
            _host.text(text);
          case BuddyTurnEventQuestion(:final text, :final options):
            _host.question(text, options);
          case BuddyTurnEventTrace(:final steps):
            _host.trace([
              for (final s in steps)
                TraceLine(
                  tool: s.tool,
                  args: s.args,
                  resultSummary: s.resultSummary,
                  ms: s.ms,
                  tokens: s.tokens,
                  usd: s.usd,
                ),
            ]);
          case BuddyTurnEventSummary(
            :final text,
            :final revision,
            :final watermark,
          ):
            await _host.summary(text, revision, watermark);
          case final BuddyTurnEventProposal event:
            final intent = frame.raw['intent'];
            if (intent is! Map<String, Object?>) continue;
            final replaces = event.replaces;
            final known = cp.card(event.proposalId);
            // A replayed or older revision of a card already shown.
            if (replaces == null && known != null) continue;
            if (known != null && event.revision <= known.revision) continue;
            final at = cp;
            final target = replaces == null
                ? null
                : cp.card(replaces.proposalId);
            if (_stopped) break;
            final written = await _host.proposal(
              TurnProposal(
                proposalId: event.proposalId,
                revision: event.revision,
                replaces: replaces == null
                    ? null
                    : (
                        proposalId: replaces.proposalId,
                        expectedRevision: replaces.expectedRevision,
                      ),
                intent: intent,
                round: at.round,
                attempt: at.attempt,
                target: target,
              ),
              (card) => at
                  .withCard(card)
                  .copyWith(
                    lastEventId: frame.id ?? at.lastEventId,
                    stopped: _stopped ? true : null,
                  ),
            );
            if (written != null) {
              cp = written;
              if (replaces != null) {
                updated.add(
                  target?.cardId ??
                      written.card(replaces.proposalId)?.cardId ??
                      replaces.proposalId,
                );
              }
            }
          case BuddyTurnEventPhoneTools(:final round, :final continuation):
            if (_stopped) break;
            final raw = frame.raw['calls'];
            final calls = [
              if (raw is List<Object?>)
                for (final c in raw)
                  if (c is Map<String, Object?>) c,
            ];
            final ran = await _tools.run(
              calls,
              today: _today,
              rows: cp.rows,
              bytes: cp.bytes,
            );
            if (_stopped) break;
            if (ran.links.isNotEmpty) _host.links(ran.links);
            await reconcile();
            final next = cp.copyWith(
              kind: TurnRoundKind.resume,
              round: round,
              attempt: 1,
              rows: ran.rows,
              bytes: ran.bytes,
              lastEventId: frame.id,
              body: {
                'turnId': cp.turnId,
                'round': round,
                'continuation': continuation,
                'results': ran.results,
              },
            );
            await _host.save(next);
            return _RoundOutcome(next, _Next.round);
          case BuddyTurnEventDone(:final reason):
            await reconcile();
            return _RoundOutcome(cp, _Next.done, reason: reason.json);
          case BuddyTurnEventError(:final code):
            return _RoundOutcome(cp, switch (code) {
              BuddyTurnErrorCode.unavailable ||
              BuddyTurnErrorCode.timeout => _Next.retry,
              _ => _Next.failed,
            });
          case BuddyTurnEventUnrecognized():
            break;
        }
      }
      // A broken connection (or a stop) ends the stream with an error.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
    // No terminal event: the round may have run (06 §3.4).
    return _RoundOutcome(cp, _Next.retry);
  }

  @override
  String toString() => 'BuddyTurnRunner';
}

enum _Next { done, round, retry, failed }

final class _RoundOutcome {
  const new(this.checkpoint, this.next, {this.reason});

  final TurnCheckpoint checkpoint;
  final _Next next;
  final String? reason;
}
