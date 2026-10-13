// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/interpret_request.dart';
import '../models/interpretation.dart';

part 'buddy_client.g.dart';

@RestApi()
abstract class BuddyClient {
  factory BuddyClient(Dio dio, {String? baseUrl}) = _BuddyClient;

  @POST('/v1/buddy/interpret')
  Future<Interpretation> interpret({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required InterpretRequest body,
  });
}
