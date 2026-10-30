import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const userA = '0192f0c4-0000-7000-8000-000000000001';
const userB = '0192f0c4-0000-7000-8000-000000000002';
const canaryEmail = 'canary-a33@example.invalid';
const canaryToken = 'canary-a33-secret-token';

AuthTokens issued(String userId) => AuthTokens(
  userId: userId,
  isAnonymous: false,
  accessToken: canaryToken,
  refreshToken: canaryToken,
  expiresAt: DateTime.utc(2026, 10, 29, 12),
  refreshExpiresAt: DateTime.utc(2026, 11, 28),
);

DioException problem(int status, String type) => DioException(
  requestOptions: RequestOptions(path: '/v1/auth'),
  response: Response(
    requestOptions: RequestOptions(path: '/v1/auth'),
    statusCode: status,
    data: {'type': type},
  ),
);

/// In-memory preferences whose writes can be made to fail (a journal-write
/// failure crash point).
final class FlakyPreferences extends InMemorySharedPreferencesAsync {
  new() : super.empty();

  /// Fails the write with this 1-based index (counted from now on).
  int? failWriteAt;
  int _writes = 0;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    _writes++;
    if (_writes == failWriteAt) throw StateError('synthetic write failure');
    return super.setString(key, value, options);
  }

  /// Arms a failure [n] writes from now.
  void failNthWrite(int n) {
    _writes = 0;
    failWriteAt = n;
  }
}

/// The preferences behind the last [memoryRegistry].
late FlakyPreferences registryPreferences;

/// A fresh in-memory registry.
ProfileRegistry memoryRegistry() {
  SharedPreferencesAsyncPlatform.instance = registryPreferences =
      FlakyPreferences();
  return ProfileRegistry(SharedPreferencesAsync(), namespace: 'dev');
}

/// One ordered log of everything the fakes did.
final class EventLog {
  final events = <String>[];
}

final class FakeSession implements AccountSession {
  new(this.log);

  final EventLog log;

  /// Hashed key of the selected envelope (what a pointer references).
  String? active;

  /// Commit tag of the selected envelope.
  String? activeTag;
  Error? failAccept;
  bool commitThenFail = false;
  Error? failEnd;
  int suspensions = 0;
  int ended = 0;
  final accepted = <String>[];
  Future<void> Function()? onAccept;
  Future<void> Function()? onEnd;

  /// The fake's stand-in for A20's hashed account key.
  String credentialRef(String userId) => 'cred-${userId.hashCode}';

  @override
  Future<void> accept(AuthTokens tokens, {required String commitTag}) async {
    await onAccept?.call();
    if (commitThenFail) {
      active = credentialRef(tokens.userId);
      activeTag = commitTag;
    }
    if (failAccept case final error?) throw error;
    log.events.add('accept');
    accepted.add(tokens.userId);
    active = credentialRef(tokens.userId);
    activeTag = commitTag;
    stored.add(active!);
  }

  /// Keys still holding a stored envelope (what end must delete).
  final stored = <String>{};
  final forgotten = <String>[];

  @override
  Future<List<String>> storedCredentialRefs() async =>
      {?active, ...stored}.toList();

  @override
  Future<void> end(List<String> refs) async {
    await onEnd?.call();
    if (failEnd case final error?) throw error;
    log.events.add('end');
    ended++;
    forgotten.addAll(refs);
    stored.removeAll(refs);
    if (active case final ref?) stored.remove(ref);
    active = null;
    activeTag = null;
  }

  @override
  void Function() suspend() {
    suspensions++;
    return () => suspensions--;
  }

  @override
  Future<String?> activeCommitTag() async => activeTag;

  int reconciles = 0;
  Error? failReconcile;

  void Function()? onReconcile;

  @override
  Future<void> reconcile() async {
    onReconcile?.call();
    if (failReconcile case final error?) throw error;
    reconciles++;
  }
}

final class FakeHost implements ProfileHost {
  new(this.log);

  final EventLog log;
  final activated = <String>[];
  final deleted = <String>[];
  Error? failDelete;

  @override
  Future<void> activate(String profileKey) async {
    log.events.add('activate:$profileKey');
    activated.add(profileKey);
  }

  @override
  Future<void> deleteFiles(String profileKey) async {
    if (failDelete case final error?) throw error;
    log.events.add('delete:$profileKey');
    deleted.add(profileKey);
  }

  Completer<void>? holdQuiesce;

  @override
  Future<void> quiesce() async {
    log.events.add('quiesce');
    await holdQuiesce?.future;
  }
}

final class FakeIdentity implements IdentityClient {
  final calls = <String>[];
  String userId = userA;
  bool linkConflicts = false;
  bool offline = false;
  Completer<void>? hold;

  Future<AuthTokens> _issue(String name) async {
    calls.add(name);
    await hold?.future;
    if (offline) {
      throw DioException(requestOptions: RequestOptions(path: '/v1/auth'));
    }
    return issued(userId);
  }

  EmailChallenge _challenge() => EmailChallenge(
    challengeId: '0192f0c4-0000-7000-8000-00000000c0de',
    expiresAt: DateTime.utc(2026, 10, 29, 12, 10),
  );

  @override
  Future<EmailChallenge> startEmailSignIn({
    required EmailStartRequest body,
  }) async {
    calls.add('start:${body.purpose}');
    // The public endpoint never carries a guest upgrade (A33 review 5).
    if (body.purpose != 'signIn') throw StateError('link via public start');
    if (offline) {
      throw DioException(requestOptions: RequestOptions(path: '/v1/auth'));
    }
    return _challenge();
  }

  @override
  Future<EmailChallenge> startEmailLink({
    required EmailLinkStartRequest body,
  }) async {
    calls.add('start:link');
    if (offline) {
      throw DioException(requestOptions: RequestOptions(path: '/v1/auth'));
    }
    return _challenge();
  }

  @override
  Future<AuthTokens> linkIdentity({
    required String provider,
    required LinkIdentityRequest body,
  }) {
    if (linkConflicts) {
      calls.add('link:$provider');
      throw problem(409, ProblemTypes.identityConflict);
    }
    return _issue('link:$provider');
  }

  @override
  Future<AuthTokens> verifyEmailSignIn({required EmailVerifyRequest body}) =>
      _issue('verify');

  @override
  Future<AuthTokens> signInGoogle({required GoogleSignInRequest body}) =>
      _issue('google');

  @override
  Future<void> logoutSession() async {
    calls.add('logout');
    if (offline) {
      throw DioException(requestOptions: RequestOptions(path: '/v1/auth'));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class FakeGoogle implements GoogleIdTokenSource {
  new({this.available = true});

  final bool available;
  String? token = canaryToken;

  @override
  bool get isAvailable => available;

  @override
  Future<String?> idToken() async => token;

  @override
  Future<void> signOut() async {}
}
