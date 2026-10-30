import 'dart:async';

import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The three `google_sign_in` calls the adapter needs (A50 D6). The only
/// production implementation is [PluginGoogleSignInDriver]; tests use a fake.
abstract interface class GoogleSignInDriver {
  /// Initializes the plugin once per process; later calls share the result.
  Future<void> ensureInitialized();

  /// Shows Google's account sheet; the ID token, or `null` if Google gave
  /// none. Throws [GoogleSignInException] (a cancel included).
  Future<String?> authenticate();

  /// Forgets the chosen account.
  Future<void> signOut();
}

Future<void> _initializePlugin(String serverClientId) =>
    GoogleSignIn.instance.initialize(serverClientId: serverClientId);

/// [GoogleSignInDriver] over `GoogleSignIn.instance` (`google_sign_in`
/// 7.2.0; Credential Manager on Android). The only file that imports the
/// plugin.
final class PluginGoogleSignInDriver implements GoogleSignInDriver {
  /// `serverClientId` is the web client ID: the ID token's audience (A50
  /// D2). Tests may replace `initialize`; the process-wide sharing stays.
  const new(this._serverClientId, {this._initialize = _initializePlugin});

  /// The process-wide initialization: `GoogleSignIn.instance.initialize` may
  /// run only once per process, so even a failure is kept and shared, never
  /// reset or retried (A50 PA1).
  static Future<void>? _initialization;

  final String _serverClientId;
  final Future<void> Function(String serverClientId) _initialize;

  @override
  Future<void> ensureInitialized() =>
      _initialization ??= _initialize(_serverClientId);

  @override
  Future<String?> authenticate() async {
    // Only the ID token is read: never the email, name or photo (A50 D9).
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }

  @override
  Future<void> signOut() => GoogleSignIn.instance.signOut();
}

/// Google ID tokens through `google_sign_in` (A50 D6–D9).
///
/// Initializes the plugin lazily on the first [idToken] (nothing runs at
/// startup, rule 3). A cancel is `null`; every failure is a redacted
/// [GoogleIdTokenException]: no plugin text, token or account detail leaves
/// this class.
final class PluginGoogleIdTokenSource implements GoogleIdTokenSource {
  /// [serverClientId] is the web client ID ("" = unavailable).
  new({
    required String serverClientId,
    GoogleSignInDriver? driver,
    TargetPlatform Function()? platform,
    this._signOutTimeout = const Duration(seconds: 5),
  }) : _serverClientId = serverClientId,
       _driver = driver ?? PluginGoogleSignInDriver(serverClientId),
       _platform = platform ?? _currentPlatform;

  final String _serverClientId;
  final GoogleSignInDriver _driver;
  final TargetPlatform Function() _platform;
  final Duration _signOutTimeout;

  /// Kept, success or failure: one initialization attempt per source.
  Future<void>? _initialization;
  bool _initialized = false;

  static TargetPlatform _currentPlatform() => defaultTargetPlatform;

  /// iOS needs its own client and URL scheme: R2 (D-081).
  @override
  bool get isAvailable =>
      _serverClientId.isNotEmpty && _platform() == TargetPlatform.android;

  @override
  Future<String?> idToken() async {
    await (_initialization ??= _initialize());
    final String? token;
    try {
      token = await _driver.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw GoogleIdTokenException(_kindOf(error.code));
    } on MissingPluginException {
      throw const GoogleIdTokenException(GoogleIdTokenFailure.unavailable);
    } on Object {
      throw const GoogleIdTokenException(GoogleIdTokenFailure.failed);
    }
    if (token == null || token.isEmpty) {
      throw const GoogleIdTokenException(GoogleIdTokenFailure.misconfigured);
    }
    return token;
  }

  Future<void> _initialize() async {
    try {
      await _driver.ensureInitialized();
      _initialized = true;
    } on GoogleSignInException catch (error) {
      throw GoogleIdTokenException(
        error.code == GoogleSignInExceptionCode.clientConfigurationError
            ? GoogleIdTokenFailure.misconfigured
            : GoogleIdTokenFailure.unavailable,
      );
    } on Object {
      throw const GoogleIdTokenException(GoogleIdTokenFailure.unavailable);
    }
  }

  /// Best effort and bounded (A50 D8): a no-op unless the plugin initialized
  /// in this process (no account was chosen otherwise); never throws.
  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await _driver.signOut().timeout(_signOutTimeout);
    } on Object {
      // Google keeps its account choice; signing out of the app goes on.
    }
  }

  static GoogleIdTokenFailure _kindOf(GoogleSignInExceptionCode code) =>
      switch (code) {
        GoogleSignInExceptionCode.providerConfigurationError =>
          GoogleIdTokenFailure.unavailable,
        GoogleSignInExceptionCode.clientConfigurationError =>
          GoogleIdTokenFailure.misconfigured,
        _ => GoogleIdTokenFailure.failed,
      };
}
