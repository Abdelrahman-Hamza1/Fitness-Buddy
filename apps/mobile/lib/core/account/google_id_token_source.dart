/// Gets a Google ID token for the server client ID (A33 D7).
///
/// The R1 adapter needs the `google_sign_in` plugin and an OAuth client ID:
/// an owner item. Until then [UnconfiguredGoogleIdTokenSource] hides the
/// Google button; tests use a fake.
abstract interface class GoogleIdTokenSource {
  /// Whether Google sign-in can be offered on this build.
  bool get isAvailable;

  /// An ID token, or `null` if the user cancelled. Never logged.
  Future<String?> idToken();

  /// Forgets the Google account choice on sign-out (best effort).
  Future<void> signOut();
}

/// No Google client configured on this build.
final class UnconfiguredGoogleIdTokenSource implements GoogleIdTokenSource {
  /// Always unavailable.
  const new();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> idToken() async => null;

  @override
  Future<void> signOut() async {}
}
