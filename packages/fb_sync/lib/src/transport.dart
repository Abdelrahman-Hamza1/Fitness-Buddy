import 'package:fb_api_client/fb_api_client.dart';

/// The engine's network side: the three B05 sync operations. Implementations
/// throw `SyncFailure` with a fixed kind for every failure, never a raw
/// transport error (no request content in errors).
abstract interface class SyncTransport {
  /// `POST /v1/sync/push` of [changes], bound to [datasetId] (an unbound
  /// push writes nothing, B05).
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  });

  /// `GET /v1/sync/pull` after [cursor]; [datasetId] `null` only to
  /// discover at cursor `0`.
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  });

  /// `GET /v1/sync/history/{entity}/{id}`: earlier versions of one row
  /// (G7), paged by its own history cursor.
  Future<SyncPage> itemHistory(
    String entity,
    String id, {
    required String cursor,
    required int limit,
    required String? datasetId,
  });
}
