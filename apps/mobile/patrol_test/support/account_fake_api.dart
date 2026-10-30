import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';
import 'package:flutter_riverpod/misc.dart';

/// The synthetic guest's server user id (a contract-valid UUID).
const accountJourneyUserId = '00000000-0000-4000-8000-00000000a033';

/// The guest's synthetic access token, the one the link start must carry.
const accountJourneyGuestAccess = 'synthetic-guest-access';

/// The code the fake "sends".
const accountJourneyCode = '123456';

/// The synthetic Google ID token [FakeGoogleIdTokenSource] returns (A50).
const accountJourneyGoogleToken = 'synthetic-google-id-token';

/// Google sign-in without the plugin (A50 D10): the real plugin needs the
/// release certificate, so journeys get a synthetic ID token instead.
final class FakeGoogleIdTokenSource implements GoogleIdTokenSource {
  /// How often the app asked for a token / for Google sign-out.
  int tokenRequests = 0;

  /// See [tokenRequests].
  int signOuts = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<String?> idToken() async {
    tokenRequests++;
    return accountJourneyGoogleToken;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

Map<String, Object?> _tokens({required bool anonymous, required String tag}) {
  final now = DateTime.now().toUtc();
  return {
    'userId': accountJourneyUserId,
    'isAnonymous': anonymous,
    'accessToken': anonymous ? accountJourneyGuestAccess : 'synthetic-$tag',
    'refreshToken': 'synthetic-refresh-$tag',
    'expiresAt': now.add(const Duration(hours: 1)).toIso8601String(),
    'refreshExpiresAt': now.add(const Duration(days: 30)).toIso8601String(),
  };
}

/// The auth Dio's fake (A33 journey): `POST /v1/auth/anonymous` issues the
/// synthetic guest; everything else is offline.
final class AccountFakeAuthAdapter extends _FakeAdapter {
  /// Paths requested, in order.
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    if (options.path != '/v1/auth/anonymous') return _offline(options);
    return _json(_tokens(anonymous: true, tag: 'guest'));
  }
}

/// The API Dio's fake: the guest-upgrade link start (only with the guest's
/// bearer), the email and Google links (same user id, now registered) and
/// logout.
/// Everything else is offline, as in `app_test`. Nothing leaves the device.
final class AccountFakeApiAdapter extends _FakeAdapter {
  /// `METHOD path (bearer)` per request, synthetic values only.
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bearer = options.headers['Authorization'];
    calls.add('${options.method} ${options.path} ($bearer)');
    switch (options.path) {
      case '/v1/auth/link/email/start':
        if (bearer != 'Bearer $accountJourneyGuestAccess') {
          return _json({'type': '/errors/unauthorized'}, status: 401);
        }
        return _json({
          'challengeId': '00000000-0000-4000-8000-0000000c0de0',
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 10))
              .toIso8601String(),
        });
      case '/v1/auth/link/email':
        final body = await _body(options, requestStream);
        if (bearer != 'Bearer $accountJourneyGuestAccess' ||
            body['code'] != accountJourneyCode) {
          return _json({'type': '/errors/unauthorized'}, status: 401);
        }
        return _json(_tokens(anonymous: false, tag: 'registered'));
      case '/v1/auth/link/google':
        final body = await _body(options, requestStream);
        if (bearer != 'Bearer $accountJourneyGuestAccess' ||
            body['idToken'] != accountJourneyGoogleToken) {
          return _json({'type': '/errors/unauthorized'}, status: 401);
        }
        return _json(_tokens(anonymous: false, tag: 'google'));
      case '/v1/auth/logout':
        return ResponseBody.fromString('', 204);
      default:
        return _offline(options);
    }
  }
}

/// Both of the app's HTTP clients on the fakes, plus a fresh in-memory
/// session store (no keystore, no tokens from another journey).
List<Override> accountFakeApi(
  AccountFakeApiAdapter api, {
  required AccountFakeAuthAdapter auth,
}) => [
  httpClientAdapterProvider.overrideWithValue(api),
  authHttpClientAdapterProvider.overrideWithValue(auth),
  secureSessionStoreProvider.overrideWithValue(
    SecureSessionStore(
      flavor: 'account-journey',
      origin: Uri.parse('https://account-fake.example.test'),
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
  reason: 'offline (account journey)',
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

final class _InstantDurability implements SessionStorageDurability {
  const new();

  @override
  Future<void> commit() async {}
}
