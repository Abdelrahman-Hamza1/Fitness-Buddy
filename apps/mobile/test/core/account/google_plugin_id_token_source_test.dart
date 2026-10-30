import 'dart:async';

import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/google_plugin_id_token_source.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _webId = '1234567890-webclient.apps.googleusercontent.com';
const _token = 'canary-a50-id-token';
const _canary = 'CANARY-A50-plugin-description';

/// Records every plugin call the adapter makes.
final class _FakeDriver implements GoogleSignInDriver {
  int inits = 0;
  int authentications = 0;
  int signOuts = 0;
  Completer<void>? initGate;
  Object? initError;
  Object? authError;
  String? token = _token;
  Object? signOutError;
  bool signOutHangs = false;

  @override
  Future<void> ensureInitialized() async {
    inits++;
    await initGate?.future;
    if (initError case final error?) await Future<void>.error(error);
  }

  @override
  Future<String?> authenticate() async {
    authentications++;
    if (authError case final error?) await Future<void>.error(error);
    return token;
  }

  @override
  Future<void> signOut() {
    signOuts++;
    if (signOutHangs) return Completer<void>().future;
    if (signOutError case final error?) return Future.error(error);
    return Future.value();
  }
}

GoogleSignInException _plugin(GoogleSignInExceptionCode code) =>
    GoogleSignInException(code: code, description: _canary, details: _canary);

Matcher _failure(GoogleIdTokenFailure kind) =>
    throwsA(isA<GoogleIdTokenException>().having((e) => e.kind, 'kind', kind));

void main() {
  late _FakeDriver driver;
  PluginGoogleIdTokenSource source({
    String serverClientId = _webId,
    TargetPlatform platform = TargetPlatform.android,
    Duration signOutTimeout = const Duration(seconds: 5),
  }) => PluginGoogleIdTokenSource(
    serverClientId: serverClientId,
    driver: driver,
    platform: () => platform,
    signOutTimeout: signOutTimeout,
  );

  setUp(() => driver = _FakeDriver());

  test(
    'AC-001 google adapter returns the ID token for the web client id',
    () async {
      final google = source();
      expect(google.isAvailable, isTrue);

      expect(await google.idToken(), _token);
      expect(driver.inits, 1);
      expect(driver.authentications, 1);
    },
  );

  test('AC-001 the production driver initializes the plugin once per process '
      'with the web client id; a failure is kept and shared', () async {
    final calls = <String>[];
    final gate = Completer<void>();
    Future<void> initialize(String serverClientId) async {
      calls.add(serverClientId);
      await gate.future;
      throw _plugin(GoogleSignInExceptionCode.unknownError);
    }

    // Two driver instances (as after a provider rebuild) share one attempt.
    final first = PluginGoogleSignInDriver(_webId, initialize: initialize);
    final second = PluginGoogleSignInDriver(
      '999-other.apps.googleusercontent.com',
      initialize: initialize,
    );
    final a = first.ensureInitialized();
    final b = second.ensureInitialized();
    gate.complete();
    await expectLater(a, throwsA(isA<GoogleSignInException>()));
    await expectLater(b, throwsA(isA<GoogleSignInException>()));
    await expectLater(
      first.ensureInitialized(),
      throwsA(isA<GoogleSignInException>()),
    );
    expect(calls, [_webId], reason: 'never initialized twice or retried');
  });

  test('AC-001 google adapter initializes the plugin exactly once, lazily, '
      'shared by concurrent callers; a failure is kept', () async {
    final google = source();
    expect(driver.inits, 0, reason: 'construction does nothing (rule 3)');

    driver.initGate = Completer<void>();
    final first = google.idToken();
    final second = google.idToken();
    // Sign-out while initialization is pending never touches the plugin.
    await google.signOut();
    expect(driver.signOuts, 0);
    driver.initGate!.complete();
    expect(await first, _token);
    expect(await second, _token);
    expect(await google.idToken(), _token);
    expect(driver.inits, 1);

    for (final (error, kind) in <(Object, GoogleIdTokenFailure)>[
      (
        _plugin(GoogleSignInExceptionCode.providerConfigurationError),
        GoogleIdTokenFailure.unavailable,
      ),
      (
        _plugin(GoogleSignInExceptionCode.clientConfigurationError),
        GoogleIdTokenFailure.misconfigured,
      ),
      (MissingPluginException(_canary), GoogleIdTokenFailure.unavailable),
      (StateError(_canary), GoogleIdTokenFailure.unavailable),
    ]) {
      driver = _FakeDriver()..initError = error;
      final failing = source();
      await expectLater(failing.idToken(), _failure(kind));
      await expectLater(failing.idToken(), _failure(kind));
      expect(driver.inits, 1, reason: 'a failed initialization is kept');
      expect(driver.authentications, 0);
      await failing.signOut();
      expect(driver.signOuts, 0, reason: 'no plugin call after a failed init');
    }
  });

  test('AC-001 google adapter maps a cancel to null', () async {
    driver.authError = _plugin(GoogleSignInExceptionCode.canceled);
    expect(await source().idToken(), isNull);
  });

  test('AC-001 google adapter maps plugin errors', () async {
    const expected = {
      GoogleSignInExceptionCode.unknownError: GoogleIdTokenFailure.failed,
      GoogleSignInExceptionCode.interrupted: GoogleIdTokenFailure.failed,
      GoogleSignInExceptionCode.clientConfigurationError:
          GoogleIdTokenFailure.misconfigured,
      GoogleSignInExceptionCode.providerConfigurationError:
          GoogleIdTokenFailure.unavailable,
      GoogleSignInExceptionCode.uiUnavailable: GoogleIdTokenFailure.failed,
      GoogleSignInExceptionCode.userMismatch: GoogleIdTokenFailure.failed,
    };
    for (final code in GoogleSignInExceptionCode.values) {
      if (code == GoogleSignInExceptionCode.canceled) continue;
      driver.authError = _plugin(code);
      await expectLater(
        source().idToken(),
        _failure(expected[code] ?? GoogleIdTokenFailure.failed),
        reason: code.name,
      );
    }
    for (final (error, kind) in <(Object, GoogleIdTokenFailure)>[
      (MissingPluginException(_canary), GoogleIdTokenFailure.unavailable),
      (
        PlatformException(code: 'x', message: _canary),
        GoogleIdTokenFailure.failed,
      ),
      (StateError(_canary), GoogleIdTokenFailure.failed),
    ]) {
      driver.authError = error;
      await expectLater(source().idToken(), _failure(kind));
    }
    driver.authError = null;
    for (final token in [null, '']) {
      driver.token = token;
      await expectLater(
        source().idToken(),
        _failure(GoogleIdTokenFailure.misconfigured),
      );
    }
  });

  test('AC-004 google adapter sign-out is best effort and bounded', () async {
    // Never initialized: nothing to forget, no plugin call.
    await source().signOut();
    expect(driver.signOuts, 0);

    final google = source(signOutTimeout: const Duration(milliseconds: 50));
    await google.idToken();
    await google.signOut();
    expect(driver.signOuts, 1);

    driver.signOutError = _plugin(GoogleSignInExceptionCode.unknownError);
    await google.signOut();
    driver
      ..signOutError = null
      ..signOutHangs = true;
    final watch = Stopwatch()..start();
    await google.signOut();
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(driver.signOuts, 3);
  });

  test('Rule:09.4-no-content-logging google failures carry no token or '
      'plugin text', () async {
    for (final error in <Object>[
      _plugin(GoogleSignInExceptionCode.unknownError),
      _plugin(GoogleSignInExceptionCode.clientConfigurationError),
      PlatformException(code: _canary, message: _canary, details: _token),
    ]) {
      driver.authError = error;
      Object? caught;
      try {
        await source().idToken();
      } on Object catch (e) {
        caught = e;
      }
      expect(caught, isA<GoogleIdTokenException>());
      expect(caught.toString(), isNot(contains(_canary)));
      expect(caught.toString(), isNot(contains(_token)));
    }
    expect(
      const GoogleIdTokenException(GoogleIdTokenFailure.failed).toString(),
      'GoogleIdTokenException(failed)',
    );
  });

  group('AC-001 Google is offered only with a client id on Android', () {
    GoogleIdTokenSource provided(String clientId) {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              flavor: AppFlavor.prod,
              apiBaseUrl: Uri.parse('https://api.example.test'),
              sentryDsn: '',
              googleServerClientId: clientId,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container.read(googleIdTokenSourceProvider);
    }

    test('no client id: unconfigured', () {
      expect(provided(''), isA<UnconfiguredGoogleIdTokenSource>());
      expect(source(serverClientId: '').isAvailable, isFalse);
    });

    test('client id on Android: the plugin source, nothing initialized', () {
      final google = provided(_webId);
      expect(google, isA<PluginGoogleIdTokenSource>());
      expect(google.isAvailable, isTrue);
    });

    test('client id on iOS: unconfigured (R2, D-081)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(provided(_webId), isA<UnconfiguredGoogleIdTokenSource>());
      expect(source(platform: TargetPlatform.iOS).isAvailable, isFalse);
    });
  });
}
