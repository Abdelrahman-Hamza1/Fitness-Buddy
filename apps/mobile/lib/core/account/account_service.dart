import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:fb_mobile/core/api/request_guard.dart';
import 'package:fb_mobile/core/session/session_service.dart';

/// Fixed account failures: no email, code, token or server text (A33 D10).
enum AccountFailureKind {
  /// No connection or the server is unavailable; nothing changed.
  offline,

  /// The email code is wrong or expired.
  invalidCode,

  /// Too many attempts; try again later.
  throttled,

  /// Google sign-in isn't configured on this build, or can't run on this
  /// phone (A50 D7).
  googleUnavailable,

  /// The server or Google refused (validation, forbidden, unknown).
  rejected,

  /// The sign-in flow was cancelled or replaced; nothing changed.
  cancelled,
}

/// Redacted failure.
final class AccountFailure implements Exception {
  /// Safe category only.
  const new(this.kind);

  /// The category.
  final AccountFailureKind kind;

  @override
  String toString() => 'AccountFailure(${kind.name})';
}

/// What a completed sign-in did to the local profiles.
enum AccountOutcome {
  /// The guest was upgraded: same user id, same database (AC-003).
  upgraded,

  /// Signed in to the account already open (e.g. after session expiry).
  sameAccount,

  /// The guest database now belongs to the existing account (merge).
  merged,

  /// Opened the account's own database (discard, or another account).
  switched,

  /// The identity has an existing account: ask merge or discard (AC-003).
  needsConflictChoice,

  /// The user cancelled (Google picker closed).
  cancelled,

  /// Merge refused: a kept copy of that account is already on this phone.
  /// Nothing changed; both copies stay (real merging waits for A34).
  mergeBlocked,
}

/// The guest's choice when the identity already has an account (AC-003).
enum ConflictChoice {
  /// Re-own this device's guest data into the account.
  merge,

  /// Delete this device's guest data and open the account.
  discard,
}

/// The sign-out choice (AC-004).
enum SignOutChoice {
  /// Keep a read-only copy on this phone.
  keep,

  /// Delete the local database and credentials.
  remove,
}

/// An email challenge; the id is opaque and only kept in memory.
final class EmailChallengeRef {
  const new _({
    required this.challengeId,
    required this.expiresAt,
    required this.link,
    required this._identity,
  });

  /// Server challenge id.
  final String challengeId;

  /// When the code stops working.
  final DateTime expiresAt;

  /// Whether this is a guest-upgrade (link) challenge.
  final bool link;

  /// Hash of the normalized address: binds conflict consent to it.
  final String _identity;

  @override
  String toString() => 'EmailChallengeRef(link: $link)';
}

/// One sign-in attempt (A33 review 6): conflict consent and a pending
/// Google token live here, bound to one identity, and die with the flow
/// (cancel, a new flow, sign-out, or completion).
final class SignInFlow {
  new _(this._service);

  final AccountService _service;
  bool _closed = false;
  String? _conflictIdentity;
  ConflictChoice? _choice;
  String? _pendingGoogleToken;

  /// Whether this flow may still act.
  bool get isOpen => !_closed && identical(_service._flow, this);

  /// Discards consent and any pending token; later calls fail `cancelled`.
  void cancel() {
    _closed = true;
    _conflictIdentity = null;
    _choice = null;
    _pendingGoogleToken = null;
  }

  void _ensureOpen() {
    if (!isOpen) throw const AccountFailure(AccountFailureKind.cancelled);
  }

  /// After the server answered: a flow cancelled meanwhile abandons (and
  /// revokes) any session the server just issued.
  void _ensureIssuedStillOpen(AuthTokens? tokens) {
    if (isOpen) return;
    if (tokens != null) _service._abandon(tokens);
    throw const AccountFailure(AccountFailureKind.cancelled);
  }

  /// Consent applies only to the identity that hit the conflict.
  ConflictChoice? _choiceFor(String identity) =>
      identity == _conflictIdentity ? _choice : null;

  void _rebind(String identity) {
    if (identity != _conflictIdentity) {
      _conflictIdentity = null;
      _choice = null;
      _pendingGoogleToken = null;
    }
  }

  /// Sends an email code. A guest gets a link challenge (same user id)
  /// unless they already chose merge/discard for this address.
  Future<EmailChallengeRef> startEmail(String email) async {
    _ensureOpen();
    final normalized = email.trim().toLowerCase();
    final identity = _hash('email|$normalized');
    _rebind(identity);
    final active = (await _service._registry.read()).active;
    final link =
        active.kind == ProfileKind.guest && _choiceFor(identity) == null;
    // A33 review 5: the guest-upgrade code comes from the authenticated
    // link endpoint (the interceptor attaches the guest bearer); the public
    // endpoint is for plain sign-in only.
    final challenge = await _service._call(
      () => link
          ? _service._identity.startEmailLink(
              body: EmailLinkStartRequest(email: email.trim()),
            )
          : _service._identity.startEmailSignIn(
              body: EmailStartRequest(email: email.trim(), purpose: 'signIn'),
            ),
    );
    _ensureOpen();
    return EmailChallengeRef._(
      challengeId: challenge.challengeId,
      expiresAt: challenge.expiresAt,
      link: link,
      identity: identity,
    );
  }

  /// Verifies the code and completes sign-in or upgrade.
  Future<AccountOutcome> verifyEmail(
    EmailChallengeRef challenge,
    String code,
  ) async {
    _ensureOpen();
    final identity = challenge._identity;
    final tokens = await _service._conflictAware(
      () => challenge.link
          ? _service._identity.linkIdentity(
              provider: 'email',
              body: LinkIdentityRequest(
                idToken: null,
                challengeId: challenge.challengeId,
                code: code,
              ),
            )
          : _service._identity.verifyEmailSignIn(
              body: EmailVerifyRequest(
                challengeId: challenge.challengeId,
                code: code,
              ),
            ),
    );
    _ensureIssuedStillOpen(tokens);
    if (tokens == null) {
      _conflictIdentity = identity;
      _choice = null;
      return AccountOutcome.needsConflictChoice;
    }
    return await _finish(tokens, linked: challenge.link, identity: identity);
  }

  /// Google sign-in or guest upgrade.
  Future<AccountOutcome> signInWithGoogle() async {
    _ensureOpen();
    if (!_service._google.isAvailable) {
      throw const AccountFailure(AccountFailureKind.googleUnavailable);
    }
    final String? idToken;
    try {
      idToken = await _service._google.idToken();
    } on GoogleIdTokenException catch (failure) {
      // Before any server call: nothing changed, the guest stays (AC-002).
      _ensureOpen();
      throw AccountFailure(switch (failure.kind) {
        GoogleIdTokenFailure.unavailable ||
        GoogleIdTokenFailure.misconfigured =>
          AccountFailureKind.googleUnavailable,
        GoogleIdTokenFailure.failed => AccountFailureKind.rejected,
      });
    }
    _ensureOpen();
    if (idToken == null) return AccountOutcome.cancelled;
    final identity = _hash('google|$idToken');
    _rebind(identity);
    return await _google(idToken, identity);
  }

  Future<AccountOutcome> _google(String idToken, String identity) async {
    final active = (await _service._registry.read()).active;
    final link =
        active.kind == ProfileKind.guest && _choiceFor(identity) == null;
    final tokens = await _service._conflictAware(
      () => link
          ? _service._identity.linkIdentity(
              provider: 'google',
              body: LinkIdentityRequest(
                idToken: idToken,
                challengeId: null,
                code: null,
              ),
            )
          : _service._identity.signInGoogle(
              body: GoogleSignInRequest(idToken: idToken),
            ),
      refused: AccountFailureKind.rejected,
    );
    _ensureIssuedStillOpen(tokens);
    if (tokens == null) {
      _conflictIdentity = identity;
      _choice = null;
      _pendingGoogleToken = idToken;
      return AccountOutcome.needsConflictChoice;
    }
    return await _finish(tokens, linked: link, identity: identity);
  }

  /// Records the merge/discard choice for the identity that hit the
  /// conflict. For Google the sign-in continues at once; for email the
  /// caller starts a new code for the same address.
  Future<AccountOutcome?> chooseOnConflict(ConflictChoice choice) async {
    _ensureOpen();
    final identity = _conflictIdentity;
    if (identity == null) {
      throw const AccountFailure(AccountFailureKind.cancelled);
    }
    _choice = choice;
    final token = _pendingGoogleToken;
    if (token == null) return null;
    return await _google(token, identity);
  }

  Future<AccountOutcome> _finish(
    AuthTokens tokens, {
    required bool linked,
    required String identity,
  }) async {
    final outcome = await _service._complete(
      tokens,
      linked: linked,
      choice: _choiceFor(identity),
      stillValid: () => isOpen,
    );
    if (outcome == AccountOutcome.mergeBlocked) {
      // Consent is spent; the user may choose discard or cancel.
      _choice = null;
    } else {
      cancel();
    }
    return outcome;
  }

  static String _hash(String text) =>
      sha256.convert(utf8.encode(text)).toString();
}

/// Sign-in, guest upgrade and sign-out orchestration (A33 D4–D6, D9).
/// Local changes go through [AccountTransitions] (A33 §6).
final class AccountService {
  /// All collaborators injected for tests.
  new({
    required this._identity,
    required this._transitions,
    required this._registry,
    required this._google,
    required this._revoke,
    this._account,
  });

  final IdentityClient _identity;

  /// `DELETE /v1/me` (A35); `null` in tests that don't delete.
  final AccountClient? _account;
  final AccountTransitions _transitions;
  final ProfileRegistry _registry;
  final GoogleIdTokenSource _google;
  final Future<void> Function(String accessToken) _revoke;
  SignInFlow? _flow;

  /// Revokes an issued-but-abandoned session with its own bearer (A33
  /// security 7). Best effort, never awaited by the caller, never logged.
  void _abandon(AuthTokens tokens) {
    unawaited(
      _revoke(tokens.accessToken).then<void>((_) {}, onError: (Object _) {}),
    );
  }

  /// Whether Google sign-in can be offered.
  bool get googleAvailable => _google.isAvailable;

  /// Starts a sign-in attempt, cancelling any earlier one.
  SignInFlow newFlow() {
    _flow?.cancel();
    return _flow = SignInFlow._(this);
  }

  /// Signs out (AC-004). Offline is fine: the server logout is best effort.
  /// The transition persists the read-only/removal state before it clears
  /// the credentials. Any sign-in flow is discarded first.
  Future<void> signOut(SignOutChoice choice) async {
    _flow?.cancel();
    _flow = null;
    try {
      await _identity.logoutSession();
    } on Object {
      // Best effort; the local credentials are forgotten below either way.
    }
    try {
      // Bounded and best effort in the adapter too (A50 D8).
      await _google.signOut();
    } on Object {
      // Google keeps its account choice; the app signs out regardless.
    }
    await _transitions.signOut(keep: choice == SignOutChoice.keep);
  }

  /// Deletes the account of profile [profileKey] (the one the user
  /// confirmed, A35 D19, fix 2) and removes it from this phone. Bound to
  /// that profile throughout: the deletion is recorded first (refused unless
  /// it is the active registered profile), sign-in, sign-out and switches
  /// are refused while `DELETE /v1/me` is in flight, the request is refused
  /// after it has its credentials if that no longer holds, and on `204` one
  /// journaled transition removes exactly that profile (credentials, its
  /// `user.db` directory, caches), finished by recovery after a crash.
  /// Independent of any screen.
  ///
  /// Throws [AccountDeletionFailure]: `offline` (nothing reached the
  /// server), `uncertain` (a timeout, a dropped connection, a server
  /// failure: retry), `sessionEnded` (a 401 or an expired session after an
  /// earlier unconfirmed attempt: B06 says that is not proof of deletion,
  /// so the user decides), `needsSignIn` (the session had ended before any
  /// attempt reached the server), `localRemovalFailed` (the server account
  /// is gone; removing it here failed and can be retried). Throws
  /// [DeletionRefused] when [profileKey] isn't the active account profile.
  Future<void> deleteAccount(String profileKey) async {
    final account = _account;
    if (account == null) throw StateError('no account client');
    _flow?.cancel();
    _flow = null;
    final earlier = await _transitions.beginDeletion(profileKey);
    try {
      await runGuarded(
        () => _transitions.deletionBoundTo(profileKey),
        account.deleteAccount,
      );
    } on DioException catch (error) {
      final kind = _deletionKind(error, earlier: earlier);
      await _transitions.endDeletionAttempt(
        profileKey,
        forget:
            kind == AccountDeletionKind.needsSignIn ||
            (kind == AccountDeletionKind.offline && !earlier),
      );
      throw AccountDeletionFailure(kind);
    } on Object {
      await _transitions.endDeletionAttempt(profileKey, forget: false);
      rethrow;
    }
    try {
      await _transitions.removeProfile(profileKey);
    } on Object {
      throw const AccountDeletionFailure(
        AccountDeletionKind.localRemovalFailed,
      );
    }
    await _googleSignOut();
  }

  /// Removes profile [profileKey] from this phone without a server call
  /// (A35): a guest's own data, the user's choice after an unconfirmed
  /// deletion, or a retry after a failed local removal. Throws
  /// [DeletionRefused] when [profileKey] isn't the active profile.
  Future<void> removeLocalData(String profileKey) async {
    _flow?.cancel();
    _flow = null;
    await _transitions.removeProfile(profileKey);
    await _googleSignOut();
  }

  /// Keeps the account: drops an unconfirmed deletion record of
  /// [profileKey] (e.g. before signing in again).
  Future<void> cancelDeletion(String profileKey) =>
      _transitions.endDeletionAttempt(profileKey, forget: true);

  /// The recorded deletion, if any (an earlier attempt that wasn't
  /// confirmed shows as "couldn't confirm" on the deletion screen).
  Future<PendingDeletion?> pendingDeletion() => _transitions.pendingDeletion();

  Future<void> _googleSignOut() async {
    try {
      // Bounded and best effort (A50 D8): the next sign-in asks again.
      await _google.signOut();
    } on Object {
      // The phone is wiped regardless.
    }
  }

  /// The deletion outcome of [error]; [earlier]: an unconfirmed attempt
  /// was recorded before this one. The auth interceptor turns a 401 whose
  /// refresh fails into a response-less error carrying a typed
  /// [SessionFailure] (A35 fix 3).
  static AccountDeletionKind _deletionKind(
    DioException error, {
    required bool earlier,
  }) {
    final status = error.response?.statusCode;
    final session = switch (error.error) {
      final SessionFailure failure => failure.kind,
      _ => null,
    };
    if (status == 401 || session == SessionFailureKind.sessionExpired) {
      return earlier
          ? AccountDeletionKind.sessionEnded
          : AccountDeletionKind.needsSignIn;
    }
    if (status != null || session != null) return AccountDeletionKind.uncertain;
    return switch (error.type) {
      // Nothing was sent: no connection, or the guard refused it.
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.cancel => AccountDeletionKind.offline,
      _ => AccountDeletionKind.uncertain,
    };
  }

  /// Leaves a read-only copy and opens a guest profile.
  Future<void> continueAsGuest() => _transitions.continueAsGuest();

  Future<AccountOutcome> _complete(
    AuthTokens tokens, {
    required bool linked,
    required ConflictChoice? choice,
    required bool Function() stillValid,
  }) async {
    if (tokens.isAnonymous) {
      throw const AccountFailure(AccountFailureKind.rejected);
    }
    final owner = _registry.ownerRefFor(tokens.userId);
    var outcome = AccountOutcome.switched;
    // Planned inside the transition lock against the current registry, and
    // only while the flow is still open (A33 security 3).
    SignInPlan? plan(ProfilesSnapshot snapshot) {
      final active = snapshot.active;
      if (linked || active.ownerRef == owner) {
        // Upgrade or re-sign-in: same user, same database (AC-003, D9).
        outcome = linked ? AccountOutcome.upgraded : AccountOutcome.sameAccount;
        return (
          target: active.copyWith(
            kind: ProfileKind.registered,
            ownerRef: owner,
            readOnly: false,
          ),
          discard: null,
        );
      }
      final existing = snapshot.ofOwner(owner);
      final guest = active.kind == ProfileKind.guest;
      if (guest && choice == ConflictChoice.merge) {
        if (existing != null) {
          // A33 review 7: two local copies of one account can't be merged
          // before A34. Nothing changes.
          outcome = AccountOutcome.mergeBlocked;
          return null;
        }
        // Merge: re-own the guest rows; A34 enqueues every row.
        outcome = AccountOutcome.merged;
        return (
          target: active.copyWith(
            kind: ProfileKind.registered,
            ownerRef: owner,
          ),
          discard: null,
        );
      }
      // Discard or another account.
      outcome = AccountOutcome.switched;
      return (
        target:
            existing?.copyWith(readOnly: false) ??
            LocalProfile(
              profileKey: _registry.profileKeyFor(tokens.userId),
              kind: ProfileKind.registered,
              ownerRef: owner,
            ),
        discard: guest && choice == ConflictChoice.discard
            ? active.profileKey
            : null,
      );
    }

    // The transition stores the tokens durably before any local change,
    // then switches the profile; deletion runs last (A33 §6).
    try {
      await _transitions.signIn(
        tokens: tokens,
        plan: plan,
        stillValid: stillValid,
      );
    } on SignInNotCommitted catch (failure) {
      // Provably never committed: revoke the unused session (A33 re-check 2).
      _abandon(tokens);
      throw AccountFailure(
        failure.cancelled
            ? AccountFailureKind.cancelled
            : AccountFailureKind.rejected,
      );
    }
    if (outcome == AccountOutcome.mergeBlocked) _abandon(tokens);
    return outcome;
  }

  /// Null when the server reports an identity conflict (409).
  Future<AuthTokens?> _conflictAware(
    Future<AuthTokens> Function() call, {
    AccountFailureKind refused = AccountFailureKind.invalidCode,
  }) async {
    try {
      return await _call(call, refused: refused);
    } on _Conflict {
      return null;
    }
  }

  /// [refused] is what a 400/401 means: a wrong email code, or (Google) a
  /// token the server rejected (A50 review).
  Future<T> _call<T>(
    Future<T> Function() call, {
    AccountFailureKind refused = AccountFailureKind.invalidCode,
  }) async {
    try {
      return await call();
    } on DioException catch (error) {
      final response = error.response;
      final data = response?.data;
      final type = data is Map ? data['type'] : null;
      throw switch ((response?.statusCode ?? 0, type)) {
        (409, ProblemTypes.identityConflict) => const _Conflict(),
        (400, _) || (401, _) => AccountFailure(refused),
        (429, _) => const AccountFailure(AccountFailureKind.throttled),
        (0, _) ||
        (>= 500, _) => const AccountFailure(AccountFailureKind.offline),
        _ => const AccountFailure(AccountFailureKind.rejected),
      };
    }
  }
}

/// Why `DELETE /v1/me` didn't confirm (A35 D19).
enum AccountDeletionKind {
  /// No connection: nothing reached the server.
  offline,

  /// The request may or may not have been processed, or the server failed.
  uncertain,

  /// The session ended after an earlier unconfirmed attempt (a lost
  /// `204` is likely, but B06 says not proof): the user decides.
  sessionEnded,

  /// The session had ended before any attempt reached the server.
  needsSignIn,

  /// The server account is gone; removing it from this phone failed.
  localRemovalFailed,
}

/// `DELETE /v1/me` didn't confirm. A fixed kind, no details.
final class AccountDeletionFailure implements Exception {
  /// A failure of [kind].
  const new(this.kind);

  /// What happened.
  final AccountDeletionKind kind;

  @override
  String toString() => 'AccountDeletionFailure(${kind.name})';
}

final class _Conflict implements Exception {
  const new();
}
