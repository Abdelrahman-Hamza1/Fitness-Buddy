// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/buddy_label_extraction.dart';
import '../models/buddy_label_request.dart';
import '../models/buddy_turn_continue.dart';
import '../models/buddy_turn_event.dart';
import '../models/buddy_turn_start.dart';

part 'buddy_client.g.dart';

@RestApi()
abstract class BuddyClient {
  factory BuddyClient(Dio dio, {String? baseUrl}) = _BuddyClient;

  /// Start a Buddy agent turn (one user message).
  ///
  /// Runs round 0 of a turn (06 §3.1): history, summary, compaction, the personal slice, profile and snapshot come from the phone; the server never reads its sync copy. Every write is a proposal event; nothing is stored. A turn costs one allowance message however many rounds or retries it takes; 429 when that reservation is denied (no provider call), a later denied send ends with done reason quota. mode weeklyReview needs the weekly block (else 400) and runs without tools. Any authenticated user including guests. Idempotency-Key must equal turnId. The turn is stateless on the server: content-free ledger rows and, between rounds, a sealed continuation (06 §3.4). Retry rule: after an ambiguous disconnect (no terminal event) the app may retry the same round once with the same request plus priorAttempt; it re-runs as attempt 2 without a new message charge, a third attempt streams error expired. Errors before streaming are problems; afterwards they are error events. New event types, intent kinds and enum values are additive: the app ignores unknown events and routes unknown kinds as unrecognized.
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

  /// Read a nutrition-label photo into reviewable values.
  ///
  /// One structured vision call (FD-040–042, 06 §8), not an agent turn. Returns what the label's nutrition panel says on its own basis (per 100 g, per 100 ml or per serving), the printed serving, a product name guess and a confidence per field; found false when no panel could be read. The model only transcribes: code converts kJ to kcal and salt to sodium (flagged) and drops impossible values; the app's review screen runs the FD-012 sanity check and highlights uncertain fields before the user saves a personal food (a proposal, D-079). Nothing is stored; the photo and the values are never logged. Costs one allowance message (and one send); 429 when that is denied, before any provider call. No Idempotency-Key: a read changes no data, and a retry is a new read. Any authenticated user including guests. 503 when Buddy is disabled, busy, or the provider fails, refuses or times out.
  @POST('/v1/buddy/label')
  Future<BuddyLabelExtraction> extractBuddyLabel({
    @Body() required BuddyLabelRequest body,
  });
}
