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

  /// sync push.
  ///
  /// Registered-user document sync; immutable HLC versions, dataset-bound admission and recoverable history. See technical-planning/05 section 5.
  @POST('/v1/sync/push')
  Future<SyncPushResponse> pushSync({@Body() required SyncPushRequest body});

  /// sync pull.
  ///
  /// Registered-user document sync; immutable HLC versions, dataset-bound admission and recoverable history. See technical-planning/05 section 5.
  ///
  /// [cursor] - Last delivered sequence; start at zero. History and document cursors are separate.
  ///
  /// [limit] - Maximum rows in this page (100 recommended).
  ///
  /// [datasetId] - Dataset binding; omit only when starting discovery at cursor zero.
  @GET('/v1/sync/pull')
  Future<SyncPage> pullSync({
    @Query('cursor') required String cursor,
    @Query('limit') required int limit,
    @Query('datasetId') String? datasetId,
  });

  /// sync history.
  ///
  /// Registered-user document sync; immutable HLC versions, dataset-bound admission and recoverable history. See technical-planning/05 section 5.
  ///
  /// [cursor] - Last delivered sequence; start at zero. History and document cursors are separate.
  ///
  /// [limit] - Maximum rows in this page (100 recommended).
  ///
  /// [datasetId] - Dataset binding; omit only when starting discovery at cursor zero.
  @GET('/v1/sync/history')
  Future<SyncPage> getSyncHistory({
    @Query('cursor') required String cursor,
    @Query('limit') required int limit,
    @Query('datasetId') String? datasetId,
  });

  /// Recover earlier versions of one item.
  ///
  /// Registered-user document sync; immutable HLC versions, dataset-bound admission and recoverable history. See technical-planning/05 section 5.
  ///
  /// [cursor] - Last delivered sequence; start at zero. History and document cursors are separate.
  ///
  /// [limit] - Maximum rows in this page (100 recommended).
  ///
  /// [datasetId] - Dataset binding; omit only when starting discovery at cursor zero.
  @GET('/v1/sync/history/{entity}/{id}')
  Future<SyncPage> getItemSyncHistory({
    @Query('cursor') required String cursor,
    @Query('limit') required int limit,
    @Path('entity') required String entity,
    @Path('id') required String id,
    @Query('datasetId') String? datasetId,
  });
}
