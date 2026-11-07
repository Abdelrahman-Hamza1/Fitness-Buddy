import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';

/// One card a turn produced (A66 D4): the server's [proposalId], the local
/// [cardId] it maps to, its current [revision], and the round and attempt
/// that created it.
final class CheckpointCard {
  /// A card.
  const new({
    required this.proposalId,
    required this.cardId,
    required this.revision,
    required this.round,
    required this.attempt,
  });

  /// Reads [json], or `null` when it isn't a card.
  static CheckpointCard? fromJson(Object? json) {
    if (json
        case {
          'p': final String p,
          'c': final String c,
          'r': final int r,
          'rd': final int rd,
          'a': final int a,
        }
        when isUuidV7(c)) {
      return CheckpointCard(
        proposalId: p,
        cardId: c,
        revision: r,
        round: rd,
        attempt: a,
      );
    }
    return null;
  }

  /// The server's ID (UUIDv5), or a local card ID echoed back.
  final String proposalId;

  /// The local card (UUIDv7).
  final String cardId;

  /// The revision the card shows.
  final int revision;

  /// The round that created it.
  final int round;

  /// The attempt of [round] that created it.
  final int attempt;

  /// With [revision].
  CheckpointCard at(int revision) => CheckpointCard(
    proposalId: proposalId,
    cardId: cardId,
    revision: revision,
    round: round,
    attempt: attempt,
  );

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'p': proposalId,
    'c': cardId,
    'r': revision,
    'rd': round,
    'a': attempt,
  };

  @override
  String toString() => 'CheckpointCard($cardId, r$revision)';
}

/// What a round posts.
enum TurnRoundKind {
  /// `POST /v1/buddy/turns`.
  start,

  /// `POST /v1/buddy/turns/continue`.
  resume,
}

/// The durable turn checkpoint (06 §3.4, A66 D4): what the phone last
/// posted (the body without `priorAttempt`), the attempt, the last event
/// ID, whether the user stopped it, the disclosure spent and the cards it
/// received. Kept in the user row's local `request_json` while the turn
/// runs; never synced or logged.
final class TurnCheckpoint {
  /// A checkpoint.
  const new({
    required this.turnId,
    required this.kind,
    required this.round,
    required this.attempt,
    required this.body,
    this.lastEventId,
    this.stopped = false,
    this.rows = 0,
    this.bytes = 0,
    this.cards = const [],
    this.createdAtMs = 0,
  });

  /// The first round of turn [turnId] with start [body].
  factory start(
    String turnId,
    Map<String, Object?> body, {
    required int createdAtMs,
  }) => TurnCheckpoint(
    turnId: turnId,
    kind: TurnRoundKind.start,
    round: 0,
    attempt: 1,
    body: body,
    createdAtMs: createdAtMs,
  );

  /// Reads [text], or `null` when it isn't a checkpoint of [turnId].
  static TurnCheckpoint? decode(String? text, String turnId) {
    if (text == null) return null;
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json
        case {
          'v': 1,
          'kind': final String kind,
          'round': final int round,
          'attempt': final int attempt,
          'body': final Map<String, Object?> body,
          'rows': final int rows,
          'bytes': final int bytes,
          'stopped': final bool stopped,
          'cards': final List<Object?> cards,
          'createdAtMs': final int createdAtMs,
        }
        when body['turnId'] == turnId) {
      final k = TurnRoundKind.values.asNameMap()[kind];
      if (k == null) return null;
      final last = json['lastEventId'];
      return TurnCheckpoint(
        turnId: turnId,
        kind: k,
        round: round,
        attempt: attempt,
        body: body,
        lastEventId: last is String ? last : null,
        stopped: stopped,
        rows: rows,
        bytes: bytes,
        cards: [for (final c in cards) ?CheckpointCard.fromJson(c)],
        createdAtMs: createdAtMs,
      );
    }
    return null;
  }

  /// The turn (the user message ID).
  final String turnId;

  /// Which route [body] goes to.
  final TurnRoundKind kind;

  /// The round (0 = start).
  final int round;

  /// The attempt of [round] (1, or 2 for the one retry).
  final int attempt;

  /// The body last posted, without `priorAttempt`.
  final Map<String, Object?> body;

  /// The last event ID handled.
  final String? lastEventId;

  /// The user stopped the turn: it is never posted or retried again.
  final bool stopped;

  /// Phone-tool rows disclosed so far this turn.
  final int rows;

  /// Phone-tool result bytes disclosed so far this turn.
  final int bytes;

  /// The cards received.
  final List<CheckpointCard> cards;

  /// When the turn was first prepared (UTC ms): auto-replay stops 23 h on.
  final int createdAtMs;

  /// The card for server or local ID [proposalId].
  CheckpointCard? card(String proposalId) {
    for (final c in cards) {
      if (c.proposalId == proposalId || c.cardId == proposalId) return c;
    }
    return null;
  }

  /// A copy with the given fields replaced.
  TurnCheckpoint copyWith({
    TurnRoundKind? kind,
    int? round,
    int? attempt,
    Map<String, Object?>? body,
    String? lastEventId,
    bool? stopped,
    int? rows,
    int? bytes,
    List<CheckpointCard>? cards,
  }) => TurnCheckpoint(
    turnId: turnId,
    kind: kind ?? this.kind,
    round: round ?? this.round,
    attempt: attempt ?? this.attempt,
    body: body ?? this.body,
    lastEventId: lastEventId ?? this.lastEventId,
    stopped: stopped ?? this.stopped,
    rows: rows ?? this.rows,
    bytes: bytes ?? this.bytes,
    cards: cards ?? this.cards,
    createdAtMs: createdAtMs,
  );

  /// With [card] added or replaced (by card ID).
  TurnCheckpoint withCard(CheckpointCard card) => copyWith(
    cards: [
      for (final c in cards)
        if (c.cardId != card.cardId) c,
      card,
    ],
  );

  /// The JSON text stored.
  String encode() => jsonEncode({
    'v': 1,
    'kind': kind.name,
    'round': round,
    'attempt': attempt,
    'body': body,
    'lastEventId': ?lastEventId,
    'stopped': stopped,
    'rows': rows,
    'bytes': bytes,
    'cards': [for (final c in cards) c.toJson()],
    'createdAtMs': createdAtMs,
  });

  @override
  String toString() => 'TurnCheckpoint($turnId, r$round a$attempt)';
}
