/// Gets a Google ID token for the server client ID (A33 D7, A50), with the
/// account's email and name for "who's signed in" on this phone (AC-005,
/// A63 D10).
///
/// The email and name are read only here and kept only on the sign-in
/// success path, on this phone (TD-115): never sent, synced or logged.
///
/// Release-key builds with the web client ID use the `google_sign_in`
/// adapter (`google_plugin_id_token_source.dart`); every other build uses
/// [UnconfiguredGoogleIdTokenSource], which hides the Google button. Tests
/// use a fake.
abstract interface class GoogleIdTokenSource {
  /// Whether Google sign-in can be offered on this build.
  bool get isAvailable;

  /// The credential, or `null` if the user cancelled. Never logged.
  ///
  /// Throws [GoogleIdTokenException] when Google can't give one.
  Future<GoogleCredential?> credential();

  /// Forgets the Google account choice on sign-out (best effort).
  Future<void> signOut();
}

/// What Google sign-in gave (A63 D10): the ID token for the server, and the
/// account's email and display name for this phone only. Its [toString]
/// carries none of them.
final class GoogleCredential {
  /// A credential.
  const new({required this.idToken, required this.email, this.displayName});

  /// The ID token (the server's audience). Never logged.
  final String idToken;

  /// The Google account's email ("" when Google gave none).
  final String email;

  /// The Google account's name, or `null`.
  final String? displayName;

  @override
  String toString() => 'GoogleCredential(redacted)';
}

/// Why Google gave no ID token (A50 D7). Safe categories only.
enum GoogleIdTokenFailure {
  /// Google sign-in can't run on this phone (no provider, no plugin).
  unavailable,

  /// The build's client configuration was refused, or no token came back.
  misconfigured,

  /// Anything else (interrupted, no account, unknown): try again.
  failed,
}

/// A redacted Google sign-in failure: the kind only, never the plugin's
/// description or a token (A50 D9).
final class GoogleIdTokenException implements Exception {
  /// A failure of [kind].
  const new(this.kind);

  /// The category.
  final GoogleIdTokenFailure kind;

  @override
  String toString() => 'GoogleIdTokenException(${kind.name})';
}

/// No Google client configured on this build.
final class UnconfiguredGoogleIdTokenSource implements GoogleIdTokenSource {
  /// Always unavailable.
  const new();

  @override
  bool get isAvailable => false;

  @override
  Future<GoogleCredential?> credential() async => null;

  @override
  Future<void> signOut() async {}
}
