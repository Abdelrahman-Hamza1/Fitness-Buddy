import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_sync/src/model.dart';
import 'package:fb_sync/src/transport.dart';

/// [SyncTransport] over the generated `UserDataClient` on a configured
/// [Dio] (the app's, with its auth and client-header interceptors; the
/// harness's, with a bearer header). Every failure becomes a [SyncFailure]
/// of a fixed kind; the request and response bodies never reach an error.
final class ApiSyncTransport implements SyncTransport {
  /// A transport over [dio].
  new(Dio dio) : _client = UserDataClient(dio);

  final UserDataClient _client;

  @override
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  }) => _call(
    () => _client.pushSync(
      body: SyncPushRequest(changes: changes, datasetId: datasetId),
    ),
  );

  @override
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => _call(
    () => _client.pullSync(cursor: cursor, limit: limit, datasetId: datasetId),
  );

  @override
  Future<SyncPage> itemHistory(
    String entity,
    String id, {
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => _call(
    () => _client.getItemSyncHistory(
      cursor: cursor,
      limit: limit,
      entity: entity,
      id: id,
      datasetId: datasetId,
    ),
  );

  static Future<T> _call<T>(Future<T> Function() send) async {
    try {
      return await send();
    } on DioException catch (error) {
      throw failureOf(error);
    } on SyncFailure {
      rethrow;
    } on Object {
      // A body that didn't parse (a proxy page, a truncated response).
      throw const SyncFailure(SyncFailureKind.protocol);
    }
  }

  /// The fixed failure kind of a Dio [error] (A34 D12).
  static SyncFailure failureOf(DioException error) {
    final response = error.response;
    if (response == null) {
      return switch (error.type) {
        DioExceptionType.badCertificate => const SyncFailure(
          SyncFailureKind.protocol,
        ),
        _ => const SyncFailure(SyncFailureKind.offline),
      };
    }
    final status = response.statusCode ?? 0;
    return switch (status) {
      401 => const SyncFailure(SyncFailureKind.unauthorized),
      403 => const SyncFailure(SyncFailureKind.forbidden),
      413 => const SyncFailure(SyncFailureKind.payloadTooLarge),
      426 => const SyncFailure(SyncFailureKind.upgradeRequired),
      429 => SyncFailure(
        SyncFailureKind.rateLimited,
        retryAfter: _retryAfter(response.headers.value('retry-after')),
      ),
      >= 500 => const SyncFailure(SyncFailureKind.server),
      _ => const SyncFailure(SyncFailureKind.protocol),
    };
  }

  /// A `Retry-After` in seconds (the API never sends an HTTP date), capped
  /// at an hour.
  static Duration? _retryAfter(String? value) {
    final seconds = int.tryParse(value?.trim() ?? '');
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds > 3600 ? 3600 : seconds);
  }
}
