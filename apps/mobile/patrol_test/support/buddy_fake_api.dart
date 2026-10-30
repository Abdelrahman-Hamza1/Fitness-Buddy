import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../test/fixtures/buddy_fixtures.dart';

/// An in-app fake of the endpoints Buddy's journeys reach (A22 D18), on the
/// app's two independent transports: [BuddyFakeAuthAdapter] under the auth
/// Dio (a synthetic guest session) and [BuddyFakeAdapter] under the API Dio
/// (the recorded J1–J3 answer for the message's text). Everything else fails
/// like no connection, so the rest of the app stays offline as in `app_test`.
/// Nothing leaves the device.
final class BuddyFakeAdapter extends _FakeAdapter {
  /// The interpret requests seen, by message text (synthetic only).
  final List<String> interpreted = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/v1/buddy/interpret') return _offline(options);
    final body = await _body(options, requestStream);
    final text = body['text'] as String? ?? '';
    interpreted.add(text);
    final answer = buddyFixtureFor(text);
    return answer == null
        ? _json({'type': 'about:blank', 'status': 400}, status: 400)
        : _json(answer);
  }
}

/// The auth transport's fake: `POST /v1/auth/anonymous` and
/// `POST /v1/auth/refresh` answer contract-valid synthetic `AuthTokens`.
final class BuddyFakeAuthAdapter extends _FakeAdapter {
  /// The auth paths requested, in order.
  final List<String> calls = [];

  int _issued = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    switch (options.path) {
      case '/v1/auth/anonymous':
      case '/v1/auth/refresh':
        calls.add(options.path);
        _issued++;
        final now = DateTime.now().toUtc();
        return _json({
          // The contract's userId is a UUID; a fixed synthetic one.
          'userId': '00000000-0000-4000-8000-00000000b0dd',
          'isAnonymous': true,
          'accessToken': 'synthetic-access-$_issued',
          'refreshToken': 'synthetic-refresh-$_issued',
          'expiresAt': now.add(const Duration(hours: 1)).toIso8601String(),
          'refreshExpiresAt': now
              .add(const Duration(days: 30))
              .toIso8601String(),
        });
      default:
        return _offline(options);
    }
  }
}

/// The overrides that put the fakes under both of the app's HTTP clients and
/// give the session a fresh in-memory store, so no tokens from another test
/// (or the phone's real keystore) are read or written. [adapter] is any API
/// transport fake (Buddy's, or A24's catalog fake); [flavor] keys the
/// session store (lowercase letters, digits or '-').
List<Override> buddyFakeApi(
  HttpClientAdapter adapter, {
  required BuddyFakeAuthAdapter auth,
  String flavor = 'buddy-journeys',
}) => [
  httpClientAdapterProvider.overrideWithValue(adapter),
  authHttpClientAdapterProvider.overrideWithValue(auth),
  secureSessionStoreProvider.overrideWithValue(
    SecureSessionStore(
      flavor: flavor,
      origin: Uri.parse('https://buddy-fake.example.test'),
      storage: _MemorySessionSecrets(),
      durability: const _InstantDurability(),
    ),
  ),
];

abstract base class _FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}
}

Never _offline(RequestOptions options) => throw DioException.connectionError(
  requestOptions: options,
  reason: 'offline (Buddy journeys)',
);

Future<Map<String, Object?>> _body(
  RequestOptions options,
  Stream<Uint8List>? stream,
) async {
  final data = options.data;
  if (data is Map<String, Object?>) return data;
  if (stream == null) return const {};
  final bytes = await stream.fold<List<int>>([], (all, b) => all..addAll(b));
  return jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

/// Session secrets that live only as long as the journey.
final class _MemorySessionSecrets implements SessionSecretStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

/// Memory is "durable" for the journey's lifetime.
final class _InstantDurability implements SessionStorageDurability {
  const new();

  @override
  Future<void> commit() async {}
}
