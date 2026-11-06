import 'dart:async';
import 'dart:convert';

import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:shared_preferences/shared_preferences.dart';

/// Who is signed in on a local profile (AC-005, D-097, TD-115): the name to
/// show and the account's email. Account metadata kept only on this phone:
/// never synced, exported, sent to the server or Buddy, or logged. Its
/// [toString] says only whether each part is set.
@immutable
final class LocalIdentity {
  /// An identity; empty parts are stored as none.
  const new({this.name, this.email});

  /// The most characters a name keeps.
  static const int nameMax = 40;

  /// The name to show, or `null` for none.
  final String? name;

  /// The account's email, or `null` for none.
  final String? email;

  /// Whether nothing is known.
  bool get isEmpty => name == null && email == null;

  /// [raw] as a stored name: one line, trimmed, at most [nameMax]
  /// characters; empty is `null`.
  static String? cleanName(String? raw) {
    final line = (raw ?? '').replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
    if (line.isEmpty) return null;
    final runes = line.runes;
    return runes.length <= nameMax
        ? line
        : String.fromCharCodes(runes.take(nameMax)).trim();
  }

  /// [raw] as a stored email: trimmed; empty is `null`.
  static String? cleanEmail(String? raw) {
    final email = (raw ?? '').trim();
    return email.isEmpty ? null : email;
  }

  @override
  bool operator ==(Object other) =>
      other is LocalIdentity && other.name == name && other.email == email;

  @override
  int get hashCode => Object.hash(LocalIdentity, name, email);

  @override
  String toString() =>
      'LocalIdentity(name: ${name == null ? 'none' : 'set'}, '
      'email: ${email == null ? 'none' : 'set'})';
}

/// [LocalIdentity] per local profile in the app's preferences (TD-115), as
/// JSON `{"n": name, "e": email}` under
/// `PreferenceKeys.identityFor(namespace, profileKey)`. Shared preferences
/// are excluded from cloud backup and device transfer, and nothing here is
/// in `user.db`, so it never syncs or enters an export.
///
/// Every write runs through one queue, so a [prune] never races a save
/// that just committed (A63 PA3). An unreadable value reads as none.
final class LocalIdentityStore {
  /// Over [_preferences] in the `namespace` environment
  /// (`flavor|apiBaseUrl`, as the profile registry's).
  new(this._preferences, {required this._namespace});

  final SharedPreferencesAsync _preferences;
  final String _namespace;
  Future<void> _queue = Future.value();

  String _key(String profileKey) =>
      PreferenceKeys.identityFor(_namespace, profileKey);

  String get _prefix => PreferenceKeys.identityFor(_namespace, '');

  /// Runs [write] after every earlier write; a failure is the caller's and
  /// never blocks later writes.
  Future<void> _serialized(Future<void> Function() write) {
    final run = _queue.then((_) => write());
    _queue = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  /// The identity of [profileKey], or an empty one.
  Future<LocalIdentity> read(String profileKey) async {
    await _queue;
    final text = await _preferences.getString(_key(profileKey));
    if (text == null) return const LocalIdentity();
    try {
      final json = jsonDecode(text);
      if (json is Map<String, Object?>) {
        return LocalIdentity(
          name: LocalIdentity.cleanName(_string(json['n'])),
          email: LocalIdentity.cleanEmail(_string(json['e'])),
        );
      }
    } on FormatException {
      // Unreadable: none.
    }
    return const LocalIdentity();
  }

  static String? _string(Object? value) => value is String ? value : null;

  /// Stores [identity] for [profileKey] (cleaned); an empty one removes it.
  Future<void> save(String profileKey, LocalIdentity identity) =>
      _serialized(() => _write(profileKey, identity));

  Future<void> _write(String profileKey, LocalIdentity identity) {
    final clean = LocalIdentity(
      name: LocalIdentity.cleanName(identity.name),
      email: LocalIdentity.cleanEmail(identity.email),
    );
    if (clean.isEmpty) return _preferences.remove(_key(profileKey));
    return _preferences.setString(
      _key(profileKey),
      jsonEncode({'n': ?clean.name, 'e': ?clean.email}),
    );
  }

  /// Sets (or with an empty [name], clears) the name of [profileKey],
  /// keeping its email.
  Future<void> setName(String profileKey, String? name) =>
      _serialized(() async {
        final text = await _preferences.getString(_key(profileKey));
        var email = '';
        if (text != null) {
          try {
            final json = jsonDecode(text);
            if (json is Map<String, Object?>) email = _string(json['e']) ?? '';
          } on FormatException {
            // Unreadable: the name alone.
          }
        }
        await _write(profileKey, LocalIdentity(name: name, email: email));
      });

  /// Removes the identity of [profileKey] (its profile was deleted).
  Future<void> remove(String profileKey) =>
      _serialized(() => _preferences.remove(_key(profileKey)));

  /// Removes the identities of profiles not in [liveKeys] (removed from
  /// the registry). [liveKeys] is read inside the queue, after every
  /// earlier save, so a stale registry snapshot can't remove an identity a
  /// sign-in just stored (A63 PA3).
  Future<void> prune(Future<Set<String>> Function() liveKeys) =>
      _serialized(() async {
        final live = await liveKeys();
        final prefix = _prefix;
        final keys = await _preferences.getKeys();
        for (final key in keys) {
          if (!key.startsWith(prefix)) continue;
          if (live.contains(key.substring(prefix.length))) continue;
          await _preferences.remove(key);
        }
      });
}
