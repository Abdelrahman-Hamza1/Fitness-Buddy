// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/buddy_interpretation.dart';
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
}
