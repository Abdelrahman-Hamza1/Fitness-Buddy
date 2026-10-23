import 'dart:async';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_clock.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';

/// Fixed failures suitable for callers/reporting, without request material.
enum SessionFailureKind {
  /// Explicit post-frame startup has not happened.
  notStarted,

  /// All automatic entry points share this cooldown.
  retryable,

  /// Storage errors require explicit recovery, never automatic auth attempts.
  storage,

  /// A33 must ask this registered account to sign in again.
  sessionExpired,

  /// Automatic attempts stopped on a validation/upgrade error.
  rejected,

  /// A newer account/session superseded this operation.
  superseded,
}

/// Never retains a credential-bearing cause.
final class SessionFailure implements Exception {
  /// [retryAfter] is present only for retryable unavailability.
  const new(this.kind, {this.retryAfter});

  /// Safe diagnostic category.
  final SessionFailureKind kind;

  /// Remaining monotonic cooldown.
  final Duration? retryAfter;

  @override
  String toString() => 'SessionFailure(${kind.name})';
}

/// Core transport lease, never provider state. WP3 checks account continuity
/// before replay; a new anonymous identity must not receive the old request.
final class SessionLease {
  const new _(
    this.bearer,
    this.generation,
    this.accountReference,
    this._epoch,
    this._owner,
  );

  final int _epoch;
  final SessionService _owner;

  /// Secret for the origin-bound interceptor only.
  final String bearer;

  /// Nonsecret generation to fence delayed 401 responses.
  final int generation;

  /// Opaque reference for same-account replay checks.
  final String accountReference;

  @override
  String toString() => 'SessionLease(redacted)';
}

/// Lazy, keepAlive session coordinator. No DB/repository/user-data dependency.
/// All durable mutations are serialized with A33 acceptance; generation fences
/// prevent late network results from overwriting a newer selected account.
final class SessionService {
  /// Construction does no storage or network I/O.
  new({
    required this._store,
    required this._transport,
    required this._clock,
    this._onState,
  });

  final SecureSessionStore _store;
  final AuthTransport _transport;
  final SessionClock _clock;
  final void Function(SessionState)? _onState;
  SessionState _state = const SessionState(status: SessionStatus.none);
  SessionEnvelope? _envelope;
  Future<SessionLease>? _flight;
  Future<SessionLease>? _acceptance;
  Future<void> _mutations = Future<void>.value();
  Duration _freshUntil = Duration.zero;
  Duration _nextAttemptAt = Duration.zero;
  int _failures = 0;
  int _generation = 0;
  int _epoch = 0;
  bool _started = false;
  bool _restored = false;
  bool _disposed = false;
  SessionFailureKind? _blocked;
  final _attemptListeners = <void Function()>{};

  /// Safe snapshot; no credentials or server user id.
  SessionState get state => _state;

  /// True while the original account ownership remains selected. Rotation may
  /// change token generation; A33 acceptance always invalidates ownership.
  bool ownsLease(SessionLease lease) =>
      !_disposed &&
      identical(lease._owner, this) &&
      lease._epoch == _epoch &&
      _envelope != null &&
      lease.accountReference == _store.accountKey(_envelope!.userId);

  /// Checks continuity synchronously, after asynchronous preparation.
  /// Acceptance fences even an earlier lease for the same account.
  bool isCurrentLease(SessionLease lease) =>
      ownsLease(lease) &&
      _acceptance == null &&
      lease.generation == _generation &&
      _envelope?.credentials != null &&
      !(_envelope?.rotationPending ?? true);

  /// WP4 scheduler reads this single deadline; wakeups may never shorten it.
  Duration get nextAttemptAt => _nextAttemptAt;

  /// Retry scheduling is allowed only for transport/throttling failures.
  /// Pending refresh markers still go through conservative recovery, never
  /// become safe to resend merely because the deadline elapsed.
  bool get canRetryAutomatically =>
      !_disposed &&
      _blocked == null &&
      _failures > 0 &&
      _flight == null &&
      _acceptance == null;

  /// Registers a token-free completion notification for the retry scheduler.
  void addAttemptListener(void Function() listener) =>
      _attemptListeners.add(listener);

  /// Stops completion notifications for a disposed scheduler.
  void removeAttemptListener(void Function() listener) =>
      _attemptListeners.remove(listener);

  void _attemptSettled() {
    if (_disposed) return;
    for (final listener in _attemptListeners.toList()) {
      listener();
    }
  }

  /// Explicitly invoked by WP4 only after the first frame.
  Future<SessionLease> startAfterFirstFrame() {
    _started = true;
    return ensureAvailable();
  }

  /// Joins acquisition/rotation/recovery, or observes the shared cooldown.
  Future<SessionLease> ensureAvailable() => _enter();

  /// A late rejection for an older generation uses the current durable pair.
  Future<SessionLease> refreshIfCurrent(int generation) =>
      _enter(rejectedGeneration: generation);

  Future<SessionLease> _enter({int? rejectedGeneration}) {
    if (_disposed) return _failed(SessionFailureKind.superseded);
    if (!_started) return _failed(SessionFailureKind.notStarted);
    if (_acceptance case final acceptance?) return acceptance;
    if (_flight case final flight?) return flight;
    if (_blocked case final kind?) return _failed(kind);
    if (_clock.elapsed < _nextAttemptAt) {
      return Future.error(
        SessionFailure(
          SessionFailureKind.retryable,
          retryAfter: _nextAttemptAt - _clock.elapsed,
        ),
      );
    }
    final epoch = _epoch;
    final flight = _run(epoch, rejectedGeneration);
    _flight = flight;
    unawaited(
      flight.then<void>(
        (_) {
          if (identical(_flight, flight)) {
            _flight = null;
            _attemptSettled();
          }
        },
        onError: (Object _) {
          if (identical(_flight, flight)) {
            _flight = null;
            _attemptSettled();
          }
        },
      ),
    );
    return flight;
  }

  Future<SessionLease> _failed(SessionFailureKind kind) =>
      Future.error(SessionFailure(kind));

  void _check(int epoch) {
    if (_disposed || epoch != _epoch) {
      throw const SessionFailure(SessionFailureKind.superseded);
    }
  }

  void _publish(SessionReadiness readiness) {
    final envelope = _envelope;
    _state = SessionState(
      status: envelope == null
          ? _state.status
          : envelope.credentials == null
          ? SessionStatus.sessionExpired
          : envelope.kind == SessionKind.registered
          ? SessionStatus.registered
          : SessionStatus.anonymous,
      readiness: readiness,
      accountReference: envelope == null
          ? _state.accountReference
          : _store.accountKey(envelope.userId),
    );
    if (!_disposed) _onState?.call(_state);
  }

  Future<SessionLease> _run(int epoch, int? rejectedGeneration) async {
    try {
      _publish(SessionReadiness.pending);
      if (!_restored) {
        final restored = await _store.readActive();
        _check(epoch);
        _envelope = restored;
        _restored = true;
        // A restored wall expiry can be skewed: ask the server once.
        _freshUntil = Duration.zero;
      }
      _check(epoch);
      final envelope = _envelope;
      if (envelope == null) return await _acquire(epoch);
      if (envelope.credentials == null) {
        _blocked = SessionFailureKind.sessionExpired;
        throw const SessionFailure(SessionFailureKind.sessionExpired);
      }
      if (envelope.rotationPending) return await _recover(epoch);
      if ((rejectedGeneration != null && rejectedGeneration == _generation) ||
          _clock.elapsed >= _freshUntil) {
        return await _rotate(epoch);
      }
      _publish(SessionReadiness.ready);
      return _lease();
    } on SessionStorageFailure catch (error) {
      _check(epoch);
      _blocked = SessionFailureKind.storage;
      if (error.knownState case final known?) _state = known;
      _publish(SessionReadiness.unavailable);
      throw const SessionFailure(SessionFailureKind.storage);
    } on AuthFailure catch (error) {
      _check(epoch);
      if (error.kind == AuthFailureKind.retryable ||
          error.kind == AuthFailureKind.throttled) {
        _failures++;
        final delay = Duration(seconds: 1 << (_failures - 1).clamp(0, 6));
        final capped = delay > const Duration(seconds: 60)
            ? const Duration(seconds: 60)
            : delay;
        for (final deadline in [_clock.elapsed + capped, ?error.retryAt]) {
          if (deadline > _nextAttemptAt) _nextAttemptAt = deadline;
        }
        _publish(SessionReadiness.unavailable);
        throw SessionFailure(
          SessionFailureKind.retryable,
          retryAfter: _nextAttemptAt - _clock.elapsed,
        );
      }
      _blocked = SessionFailureKind.rejected;
      _publish(SessionReadiness.unavailable);
      throw const SessionFailure(SessionFailureKind.rejected);
    } on SessionFailure {
      if (epoch == _epoch && !_disposed) {
        _publish(SessionReadiness.unavailable);
      }
      rethrow;
    } on Object {
      _check(epoch);
      _blocked = SessionFailureKind.rejected;
      _publish(SessionReadiness.unavailable);
      throw const SessionFailure(SessionFailureKind.rejected);
    }
  }

  Future<void> _save(SessionEnvelope envelope, int epoch) {
    final result = _mutations.then((_) async {
      _check(epoch);
      await _store.save(envelope);
      _check(epoch);
      _envelope = envelope;
    });
    _mutations = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  SessionEnvelope _fromTokens(AuthTokens tokens) {
    if (tokens.userId.isEmpty ||
        tokens.accessToken.isEmpty ||
        tokens.refreshToken.isEmpty) {
      throw const AuthFailure(AuthFailureKind.rejected);
    }
    return SessionEnvelope(
      userId: tokens.userId,
      kind: tokens.isAnonymous ? SessionKind.anonymous : SessionKind.registered,
      credentials: SessionCredentials(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
        refreshExpiresAt: tokens.refreshExpiresAt,
      ),
    );
  }

  Future<SessionLease> _commitTokens(AuthTokens tokens, int epoch) async {
    _check(epoch);
    final envelope = _fromTokens(tokens);
    await _save(envelope, epoch);
    _restored = true;
    _blocked = null;
    _generation++;
    final hint =
        tokens.expiresAt.toUtc().difference(_clock.wallNow) -
        const Duration(seconds: 30);
    // Even a past expiry gets one use; the server's 401 is authoritative.
    final freshness =
        hint <= Duration.zero || hint > const Duration(minutes: 15)
        ? const Duration(minutes: 15)
        : hint;
    _freshUntil = _clock.elapsed + freshness;
    _failures = 0;
    _nextAttemptAt = Duration.zero;
    _publish(SessionReadiness.ready);
    return _lease();
  }

  SessionLease _lease() => SessionLease._(
    _envelope!.credentials!.accessToken,
    _generation,
    _store.accountKey(_envelope!.userId),
    _epoch,
    this,
  );

  Future<SessionLease> _acquire(int epoch) async {
    final tokens = await _transport.createAnonymous();
    _check(epoch);
    if (!tokens.isAnonymous) throw const AuthFailure(AuthFailureKind.rejected);
    return await _commitTokens(tokens, epoch);
  }

  Future<SessionLease> _rotate(int epoch) async {
    final current = _envelope!;
    _freshUntil = Duration.zero;
    await _save(
      SessionEnvelope(
        userId: current.userId,
        kind: current.kind,
        credentials: current.credentials,
        rotationPending: true,
      ),
      epoch,
    );
    _check(
      epoch,
    ); // PA2: physically send only after the pending commit barrier.
    AuthTokens tokens;
    try {
      tokens = await _transport.refresh(current.credentials!.refreshToken);
    } on AuthFailure catch (error) {
      _check(epoch);
      if (error.kind == AuthFailureKind.unauthorized) {
        return await _recover(epoch);
      }
      if (error.kind == AuthFailureKind.throttled || error.refreshNotConsumed) {
        // Host throttling precedes Identity (HttpSetup); connection/TLS failure
        // may also prove no dispatch. All other failures retain pending.
        await _save(current, epoch);
      }
      rethrow;
    }
    _check(epoch);
    if (tokens.userId != current.userId ||
        tokens.isAnonymous != (current.kind == SessionKind.anonymous)) {
      throw const AuthFailure(AuthFailureKind.rejected);
    }
    return await _commitTokens(tokens, epoch);
  }

  Future<SessionLease> _recover(int epoch) async {
    final current = _envelope!;
    if (current.kind == SessionKind.registered) {
      await _save(
        SessionEnvelope(userId: current.userId, kind: current.kind),
        epoch,
      );
      _generation++;
      _blocked = SessionFailureKind.sessionExpired;
      throw const SessionFailure(SessionFailureKind.sessionExpired);
    }
    // Only a confirmed readable guest can acquire a replacement identity.
    return await _acquire(epoch);
  }

  /// A33 calls this only after selecting/merging its local account. Acceptance
  /// fences pending auth immediately and publishes only after durable storage.
  Future<SessionLease> acceptAuthenticatedSession(AuthTokens tokens) {
    if (_disposed) return _failed(SessionFailureKind.superseded);
    final epoch = ++_epoch;
    _generation++;
    _flight = null;
    final acceptance = _accept(tokens, epoch);
    _acceptance = acceptance;
    unawaited(
      acceptance.then<void>(
        (_) {
          if (identical(_acceptance, acceptance)) {
            _acceptance = null;
            _attemptSettled();
          }
        },
        onError: (Object _) {
          if (identical(_acceptance, acceptance)) {
            _acceptance = null;
            _attemptSettled();
          }
        },
      ),
    );
    return acceptance;
  }

  Future<SessionLease> _accept(AuthTokens tokens, int epoch) async {
    try {
      if (tokens.isAnonymous) throw const AuthFailure(AuthFailureKind.rejected);
      return await _commitTokens(tokens, epoch);
    } on SessionStorageFailure catch (error) {
      _check(epoch);
      _blocked = SessionFailureKind.storage;
      if (error.knownState case final known?) _state = known;
      _envelope = null;
      _publish(SessionReadiness.unavailable);
      throw const SessionFailure(SessionFailureKind.storage);
    } on SessionFailure {
      rethrow;
    } on Object {
      _check(epoch);
      _blocked = SessionFailureKind.rejected;
      _publish(SessionReadiness.unavailable);
      throw const SessionFailure(SessionFailureKind.rejected);
    }
  }

  /// Invalidates late operations. WP4 owns timer/lifecycle disposal.
  void dispose() {
    _disposed = true;
    _attemptListeners.clear();
    _epoch++;
  }
}
