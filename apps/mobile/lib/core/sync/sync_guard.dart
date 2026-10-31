import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/request_guard.dart';
import 'package:fb_sync/fb_sync.dart';

/// [SyncTransport] that runs every call through `runGuarded` with [_valid],
/// so `RequestGuardInterceptor` checks the run is still for the same profile,
/// account and generation once the request has its credentials.
final class GuardedSyncTransport implements SyncTransport {
  /// Guards [_inner]'s calls with [_valid].
  new(this._inner, this._valid);

  final SyncTransport _inner;
  final bool Function() _valid;

  Future<T> _guarded<T>(Future<T> Function() call) {
    if (!_valid()) {
      return Future.error(const SyncFailure(SyncFailureKind.offline));
    }
    return runGuarded(_valid, call);
  }

  @override
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  }) => _guarded(() => _inner.push(changes, datasetId: datasetId));

  @override
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => _guarded(
    () => _inner.pull(cursor: cursor, limit: limit, datasetId: datasetId),
  );

  @override
  Future<SyncPage> itemHistory(
    String entity,
    String id, {
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => _guarded(
    () => _inner.itemHistory(
      entity,
      id,
      cursor: cursor,
      limit: limit,
      datasetId: datasetId,
    ),
  );
}
