import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Raw secret-store seam for tests. Only SecureSessionStore writes these keys.
abstract interface class SessionSecretStorage {
  /// Reads without inferring absence from an exception.
  Future<String?> read(String key);

  /// Writes encrypted data, not yet acknowledged durable.
  Future<void> write(String key, String value);

  /// Deletes only this key, never the whole plugin store.
  Future<void> delete(String key);
}

/// Pinned 11.2.0 mapping is shared with SessionStorageDurability.kt.
final class PluginSessionSecretStorage implements SessionSecretStorage {
  /// The plugin instance has no access outside this adapter.
  const new();

  static const _options = AndroidOptions(
    resetOnError: false,
    migrateOnAlgorithmChange: false,
    // PA1: pin recovery options, including current false defaults.
    // ignore: avoid_redundant_argument_values
    migrateWithBackup: false,
    storageNamespace: 'fb.session.secure.v1',
  );
  static const _plugin = FlutterSecureStorage(aOptions: _options);

  @override
  Future<String?> read(String key) =>
      _plugin.read(key: key, aOptions: _options);

  @override
  Future<void> write(String key, String value) =>
      _plugin.write(key: key, value: value, aOptions: _options);

  @override
  Future<void> delete(String key) =>
      _plugin.delete(key: key, aOptions: _options);
}

/// Core-only private request material. Never expose via providers or reporting.
final class SessionCredentials {
  /// Stores the complete pair returned by the generated auth client.
  const new({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });

  /// Request bearer; never log.
  final String accessToken;

  /// Rotating secret; never log or resend while rotation is pending.
  final String refreshToken;

  /// Server hints, not proof of validity.
  final DateTime expiresAt;

  /// Absolute server refresh expiry.
  final DateTime refreshExpiresAt;

  @override
  String toString() => 'SessionCredentials(redacted)';
}

/// Versioned core-only envelope. Null credentials represent registered expiry.
final class SessionEnvelope {
  /// Creates a complete pair or a registered expired marker.
  const new({
    required this.userId,
    required this.kind,
    this.credentials,
    this.rotationPending = false,
    this.commitTag,
  });

  /// Server identity, confined to the core session/storage layer.
  final String userId;

  /// Retained even after terminal registered expiry.
  final SessionKind kind;

  /// Never publish this object as Riverpod state.
  final SessionCredentials? credentials;

  /// Durable intent marker required before physically sending refresh.
  final bool rotationPending;

  /// A33 §6: the unique tag of the account transition that committed these
  /// credentials (opaque, no secret). Recovery rolls a sign-in forward only
  /// on an exact match, so an unchanged guest envelope (same user id after
  /// an upgrade) never looks like a new commit.
  final String? commitTag;

  @override
  String toString() => 'SessionEnvelope(redacted)';
}

/// One instance per origin/isolate. All operations, including reads, are queued.
///
/// A failed mutation poisons this instance: an in-memory preferences value
/// after a failed/lost commit is not proof of durable state. Reopen after restart;
/// Never retry refresh or publish credentials from this instance after failure.
final class SecureSessionStore {
  /// Inject both ports for deterministic ordering/failure tests.
  new({
    required String flavor,
    required Uri origin,
    required this._storage,
    required this._durability,
  }) {
    if (!{'http', 'https'}.contains(origin.scheme) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        flavor.isEmpty) {
      throw ArgumentError('invalid_session_origin');
    }
    _namespace = _hash(
      '$flavor|${origin.scheme.toLowerCase()}|'
      '${origin.host.toLowerCase()}|${origin.port}',
    );
  }

  final SessionSecretStorage _storage;
  final SessionStorageDurability _durability;
  late final String _namespace;
  Future<void> _tail = Future<void>.value();
  SessionState? _knownState;
  bool _poisoned = false;

  static String _hash(String text) =>
      sha256.convert(utf8.encode(text)).toString();

  /// Hash avoids plugin native error logs revealing server ids in key names.
  String accountKey(String userId) =>
      'fb.session.v1.$_namespace.${_hash(userId)}';
  String get _pointer => 'fb.session.active.v1.$_namespace';
  String get _intent => 'fb.session.intent.v1.$_namespace';

  Future<T> _queued<T>(Future<T> Function() action, {bool checkIntent = true}) {
    final result = _tail.then((_) async {
      if (_poisoned) {
        throw SessionStorageFailure(
          SessionStorageFailureKind.durability,
          knownState: _knownState,
        );
      }
      try {
        if (checkIntent) await _checkIntent();
        return await action();
      } on SessionStorageFailure {
        rethrow;
      } on Object {
        throw SessionStorageFailure(
          SessionStorageFailureKind.unavailable,
          knownState: _knownState,
        );
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Never _malformed() => throw SessionStorageFailure(
    SessionStorageFailureKind.malformed,
    knownState: _knownState,
  );

  Future<void> _mutate(Future<void> Function() action) async {
    try {
      await action();
      await _durability.commit();
    } on Object {
      _poisoned = true;
      throw SessionStorageFailure(
        SessionStorageFailureKind.durability,
        knownState: _knownState,
      );
    }
  }

  void _validateKey(String key) {
    if (!RegExp('^fb\\.session\\.v1\\.$_namespace\\.[a-f0-9]{64}\$')
        .hasMatch(key)) {
      _malformed();
    }
  }

  Map<String, dynamic> _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic> || value['v'] != 1) _malformed();
      return value;
    } on Object {
      _malformed();
    }
  }

  Future<SessionEnvelope?> _read(String key) async {
    _validateKey(key);
    final raw = await _storage.read(key);
    if (raw == null) return null;
    final data = _decode(raw);
    try {
      final userId = data['userId'] as String;
      final kind = SessionKind.values.byName(data['kind'] as String);
      if (userId.isEmpty || accountKey(userId) != key) _malformed();
      final pair = data['pair'] as Map<String, dynamic>?;
      final credentials = pair == null
          ? null
          : SessionCredentials(
              accessToken: pair['access'] as String,
              refreshToken: pair['refresh'] as String,
              expiresAt: DateTime.parse(pair['expires'] as String).toUtc(),
              refreshExpiresAt: DateTime.parse(pair['refreshExpires'] as String)
                  .toUtc(),
            );
      final envelope = SessionEnvelope(
        userId: userId,
        kind: kind,
        credentials: credentials,
        rotationPending: data['pending'] as bool,
        commitTag: data['tag'] as String?,
      );
      _validate(envelope);
      return envelope;
    } on Object {
      _malformed();
    }
  }

  void _validate(SessionEnvelope envelope) {
    final pair = envelope.credentials;
    if (envelope.userId.isEmpty ||
        (pair == null &&
            (envelope.kind != SessionKind.registered ||
                envelope.rotationPending)) ||
        (pair != null &&
            (pair.accessToken.isEmpty || pair.refreshToken.isEmpty))) {
      _malformed();
    }
  }

  Future<void> _checkIntent() async {
    final intent = await _storage.read(_intent);
    if (intent != null) {
      _readMarker(intent);
      throw SessionStorageFailure(
        SessionStorageFailureKind.durability,
        knownState: _knownState,
      );
    }
  }

  Future<SessionEnvelope?> _readActive() async {
    final raw = await _storage.read(_pointer);
    if (raw == null) return null;
    final data = _decode(raw);
    try {
      final key = _readMarker(raw);
      final kind = SessionKind.values.byName(data['kind'] as String);
      final envelope = await _read(key);
      if (envelope == null || envelope.kind != kind) _malformed();
      return envelope;
    } on SessionStorageFailure {
      rethrow;
    } on Object {
      throw SessionStorageFailure(
        SessionStorageFailureKind.unavailable,
        knownState: _knownState,
      );
    }
  }

  /// Null means a successful read confirmed no pointer, never an I/O error.
  Future<SessionEnvelope?> readActive() => _queued(_readActive);

  /// Reads only this origin's account namespace.
  Future<SessionEnvelope?> read(String accountKey) =>
      _queued(() => _read(accountKey));

  String _readMarker(String raw) {
    final data = _decode(raw);
    try {
      final key = data['key'] as String;
      _validateKey(key);
      final kind = SessionKind.values.byName(data['kind'] as String);
      _knownState = SessionState(
        status: kind == SessionKind.registered
            ? SessionStatus.registered
            : SessionStatus.anonymous,
        readiness: SessionReadiness.unavailable,
        accountReference: key,
      );
      return key;
    } on Object {
      _malformed();
    }
  }

  String _marker(SessionEnvelope envelope) => jsonEncode({
    'v': 1,
    'key': accountKey(envelope.userId),
    'kind': envelope.kind.name,
  });

  Future<void> _begin(SessionEnvelope envelope) async {
    // An orphan registered envelope must never look like an absent account.
    // Leave the intent on any interrupted/ambiguous mutation. WP5 kills here.
    _readMarker(_marker(envelope));
    await _mutate(() => _storage.write(_intent, _marker(envelope)));
  }

  Future<void> _finish() => _mutate(() => _storage.delete(_intent));

  Future<void> _select(SessionEnvelope envelope) async {
    final key = accountKey(envelope.userId);
    await _mutate(
      () => _storage.write(
        _pointer,
        jsonEncode({'v': 1, 'key': key, 'kind': envelope.kind.name}),
      ),
    );
    _knownState = SessionState(
      status: envelope.credentials == null
          ? SessionStatus.sessionExpired
          : envelope.kind == SessionKind.registered
          ? SessionStatus.registered
          : SessionStatus.anonymous,
      readiness: SessionReadiness.unavailable,
      accountReference: key,
    );
  }

  /// Durable recovery intent, whole pair, pointer, then clear intent.
  /// Each mutation commits all backing files before the next mutation starts.
  Future<void> save(SessionEnvelope envelope) => _queued(() async {
    _validate(envelope);
    final pair = envelope.credentials;
    await _begin(envelope);
    await _mutate(
      () => _storage.write(
        accountKey(envelope.userId),
        jsonEncode({
          'v': 1,
          'userId': envelope.userId,
          'kind': envelope.kind.name,
          'pending': envelope.rotationPending,
          'tag': ?envelope.commitTag,
          'pair': pair == null
              ? null
              : {
                  'access': pair.accessToken,
                  'refresh': pair.refreshToken,
                  'expires': pair.expiresAt.toUtc().toIso8601String(),
                  'refreshExpires': pair.refreshExpiresAt
                      .toUtc()
                      .toIso8601String(),
                },
        }),
      ),
    );
    await _select(envelope);
    await _finish();
  });

  /// Select only a readable, matching envelope, after durable acknowledgement.
  Future<void> select(String accountKey) => _queued(() async {
    final envelope = await _read(accountKey);
    if (envelope == null) _malformed();
    await _begin(envelope);
    await _select(envelope);
    await _finish();
  });

  /// Removes one envelope. Retains the pointer/kind so deletion cannot silently
  /// turn an active registered identity into a guest on the next startup.
  Future<void> remove(String accountKey) => _queued(() async {
    _validateKey(accountKey);
    await _mutate(() => _storage.delete(accountKey));
  });

  /// A33 §6: explicit reconciliation of an interrupted save, invoked only by
  /// account-transition recovery (startup, before the session starts). An
  /// intent marker otherwise blocks every operation. Deterministic:
  /// - the marked envelope is readable → complete: select it, clear intent;
  /// - it is missing or malformed → discard: clear the intent, keep the
  ///   pointer as it was;
  /// - the store can't be read → throw and keep the intent (fail closed).
  /// Returns whether an intent was found.
  Future<bool> reconcileIntent() => _queued(checkIntent: false, () async {
    final raw = await _storage.read(_intent);
    if (raw == null) return false;
    String? key;
    try {
      key = _readMarker(raw);
    } on SessionStorageFailure {
      key = null; // A malformed marker names nothing to complete.
    }
    SessionEnvelope? envelope;
    if (key != null) {
      try {
        envelope = await _read(key);
      } on SessionStorageFailure catch (error) {
        if (error.kind != SessionStorageFailureKind.malformed) rethrow;
      }
    }
    if (envelope != null) await _select(envelope);
    await _finish();
    return true;
  });

  /// A33 sign-out (§6): clears the active pointer first (a pointer to a
  /// missing envelope would read as malformed and block startup), then
  /// deletes every envelope in [accountKeys]. The keys come from the account
  /// transition journal, so a crash between the deletes is finished by
  /// recovery deleting the same keys, whether or not a pointer still exists.
  Future<void> forgetKeys(Iterable<String> accountKeys) => _queued(() async {
    final keys = accountKeys.toSet()..forEach(_validateKey);
    await _mutate(() => _storage.delete(_pointer));
    _knownState = null;
    for (final key in keys) {
      await _mutate(() => _storage.delete(key));
    }
  });

  /// [forgetKeys] for one key.
  Future<void> forget(String accountKey) => forgetKeys([accountKey]);
}
