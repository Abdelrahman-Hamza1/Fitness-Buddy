// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/buddy_interpretation.dart';
import '../models/buddy_turn_continue.dart';
import '../models/buddy_turn_event.dart';
import '../models/buddy_turn_start.dart';
import '../models/interpret_request.dart';

part 'buddy_client.g.dart';

@RestApi()
abstract class BuddyClient {
  factory BuddyClient(Dio dio, {String? baseUrl}) = _BuddyClient;

  /// Interpret a message into read-only typed intents.
  ///
  /// Any authenticated user including guests. Idempotency-Key must equal the UUIDv7 requestId. Replay retention 24 hours. Conflicting input returns 409; an in-flight or ambiguous paid attempt returns 503 and is never automatically charged again for that key during retention. Forward compatibility (04 §4.2): new intent kinds and enum values are added without a version bump. The client routes an unknown kind, a known kind with an unknown enum value, or a dateHint it can't parse as unrecognized, and never defaults to a destructive operation. Clarify reasons: unclear, unsupported, offTopic, invalidInterpretation, unmatchedFood, referenceNotFound, medical. context.activeCard requires activeProposal (else 400). Context limits: 30 personal foods, 20 memory items, 30 recent entries, 20 each saved meals/open batches/custom exercises, 12 slots, 30 active-card lines; names/values at most 200 characters. No images until the vision endpoint. Estimates are badged ranges only when no real match exists. Nutrition calculation and confirmation happen on the phone. Daily operational limits are tighter for guests; 429 never calls the provider.
  ///
  /// [idempotencyKey] - Required on every unsafe POST. The server stores the result for 24 h and replays it for a repeated key (Buddy uses the chat message ID).
  @POST('/v1/buddy/interpret')
  Future<BuddyInterpretation> interpretMessage({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required InterpretRequest body,
  });

  /// Start a Buddy agent turn (one user message).
  ///
  /// Runs round 0 of a turn (06 §3.1): history, summary, compaction, the personal slice, profile and snapshot come from the phone; the server never reads its sync copy. Every write is a proposal event; nothing is stored. A turn costs one allowance message however many rounds or retries it takes; 429 when that reservation is denied (no provider call), a later denied send ends with done reason quota. mode weeklyReview needs the weekly block (B26) and is answered 400 until then. Any authenticated user including guests. Idempotency-Key must equal turnId. The turn is stateless on the server: content-free ledger rows and, between rounds, a sealed continuation (06 §3.4). Retry rule: after an ambiguous disconnect (no terminal event) the app may retry the same round once with the same request plus priorAttempt; it re-runs as attempt 2 without a new message charge, a third attempt streams error expired. Errors before streaming are problems; afterwards they are error events. New event types, intent kinds and enum values are additive: the app ignores unknown events and routes unknown kinds as unrecognized.
  ///
  /// [idempotencyKey] - Required on every unsafe POST. The server stores the result for 24 h and replays it for a repeated key (Buddy uses the chat message ID).
  @POST('/v1/buddy/turns')
  Future<BuddyTurnEvent> startBuddyTurn({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required BuddyTurnStart body,
  });

  /// Continue a paused turn with phone-tool results.
  ///
  /// Runs the round a phoneTools event announced (06 §3.2). results must answer exactly the pending call IDs (no missing, extra or duplicate IDs), each validating against its tool's data schema and caps; otherwise the stream answers error invalid with no send. An expired continuation (10 minutes) answers error expired. Posting round r+1 acknowledges round r. Any authenticated user including guests. Idempotency-Key must equal turnId. The turn is stateless on the server: content-free ledger rows and, between rounds, a sealed continuation (06 §3.4). Retry rule: after an ambiguous disconnect (no terminal event) the app may retry the same round once with the same request plus priorAttempt; it re-runs as attempt 2 without a new message charge, a third attempt streams error expired. Errors before streaming are problems; afterwards they are error events. New event types, intent kinds and enum values are additive: the app ignores unknown events and routes unknown kinds as unrecognized.
  ///
  /// [idempotencyKey] - Required on every unsafe POST. The server stores the result for 24 h and replays it for a repeated key (Buddy uses the chat message ID).
  @POST('/v1/buddy/turns/continue')
  Future<BuddyTurnEvent> continueBuddyTurn({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required BuddyTurnContinue body,
  });
}
