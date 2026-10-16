// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/sync_page.dart';
import '../models/sync_push_request.dart';
import '../models/sync_push_response.dart';

part 'user_data_client.g.dart';

@RestApi()
abstract class UserDataClient {
  factory UserDataClient(Dio dio, {String? baseUrl}) = _UserDataClient;

  /// Experimental sync push.
  ///
  /// B01 feasibility prototype, synthetic data only; disabled in normal environments. See technical-planning/05 section 5.4.
  ///
  /// [xSyncSpikeKey] - Ephemeral synthetic-data test access; unavailable in normal API environments.
  @POST('/v1/sync/push')
  Future<SyncPushResponse> pushSync({
    @Header('X-Sync-Spike-Key') required String xSyncSpikeKey,
    @Body() required SyncPushRequest body,
  });

  /// Experimental sync pull.
  ///
  /// B01 feasibility prototype, synthetic data only; disabled in normal environments. See technical-planning/05 section 5.4.
  ///
  /// [xSyncSpikeKey] - Ephemeral synthetic-data test access; unavailable in normal API environments.
  ///
  /// [cursor] - Last delivered sequence; start at zero. History and document cursors are separate.
  ///
  /// [limit] - Maximum rows in this page (100 recommended).
  @GET('/v1/sync/pull')
  Future<SyncPage> pullSync({
    @Header('X-Sync-Spike-Key') required String xSyncSpikeKey,
    @Query('cursor') required String cursor,
    @Query('limit') required int limit,
  });

  /// Experimental sync history.
  ///
  /// B01 feasibility prototype, synthetic data only; disabled in normal environments. See technical-planning/05 section 5.4.
  ///
  /// [xSyncSpikeKey] - Ephemeral synthetic-data test access; unavailable in normal API environments.
  ///
  /// [cursor] - Last delivered sequence; start at zero. History and document cursors are separate.
  ///
  /// [limit] - Maximum rows in this page (100 recommended).
  @GET('/v1/sync/history')
  Future<SyncPage> getSyncHistory({
    @Header('X-Sync-Spike-Key') required String xSyncSpikeKey,
    @Query('cursor') required String cursor,
    @Query('limit') required int limit,
  });
}
