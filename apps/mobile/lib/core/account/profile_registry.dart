import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who owns a local profile's `user.db` (A33 D1).
enum ProfileKind {
  /// A guest: data never leaves the device; sync refuses it.
  guest,

  /// A signed-in account.
  registered,
}

/// One local profile: a `profiles/<profileKey>/user.db` file (`05` §3).
final class LocalProfile {
  /// [ownerRef] is an opaque hash of the account, never the raw user id.
  const new({
    required this.profileKey,
    required this.kind,
    this.ownerRef,
    this.readOnly = false,
  });

  /// The directory name under `profiles/`.
  final String profileKey;

  /// Guest or registered.
  final ProfileKind kind;

  /// Opaque account reference for registered profiles.
  final String? ownerRef;

  /// A copy kept after sign-out (A33 D2): visible, not editable.
  final bool readOnly;

  /// A modified copy.
  LocalProfile copyWith({
    ProfileKind? kind,
    String? ownerRef,
    bool? readOnly,
  }) => LocalProfile(
    profileKey: profileKey,
    kind: kind ?? this.kind,
    ownerRef: ownerRef ?? this.ownerRef,
    readOnly: readOnly ?? this.readOnly,
  );

  Map<String, Object?> _toJson() => {
    'key': profileKey,
    'kind': kind.name,
    'owner': ?ownerRef,
    'ro': readOnly,
  };

  // A private parser keeps the JSON shape out of the public API.
  // ignore: prefer_constructors_over_static_methods
  static LocalProfile _fromJson(Map<String, Object?> json) => LocalProfile(
    profileKey: json['key']! as String,
    kind: ProfileKind.values.byName(json['kind']! as String),
    ownerRef: json['owner'] as String?,
    readOnly: json['ro'] as bool? ?? false,
  );

  @override
  String toString() => 'LocalProfile(${kind.name}, readOnly: $readOnly)';
}

/// What an account transition does (A33 §6).
enum TransitionKind {
  /// Sign-in, guest upgrade, re-sign-in, switch, merge or discard.
  signIn,

  /// Sign-out, keep or remove.
  signOut,

  /// Open another local profile without credential changes (continue as
  /// guest from a read-only copy).
  switchProfile,
}

/// The durable phase of an account transition (A33 §6).
enum TransitionPhase {
  /// Journal written, nothing else changed yet.
  preparing,

  /// Sign-in: the tokens are durably stored.
  credentialsCommitted,

  /// The registry's ownership/active profile changed.
  profileSwitched,

  /// Sign-out: the credentials are forgotten.
  credentialsCleared,

  /// Only deferred deletion of reserved directories remains.
  cleanupPending,
}

/// The account transition journal (A33 §6): no secret, no raw id, no email.
final class AccountTransition {
  /// See the fields.
  const new({
    required this.kind,
    required this.phase,
    required this.fromKey,
    required this.target,
    this.commitTag,
    this.discard,
    this.forgetRefs = const [],
  });

  /// What this transition does.
  final TransitionKind kind;

  /// How far it got durably.
  final TransitionPhase phase;

  /// The profile active when it started.
  final String fromKey;

  /// The profile entry installed and made active at
  /// [TransitionPhase.profileSwitched].
  final LocalProfile target;

  /// Sign-in: the unique tag stored with the committed credentials.
  final String? commitTag;

  /// A profile to reserve at the switch and delete at cleanup.
  final String? discard;

  /// Sign-out: A20's hashed keys of every credential envelope to delete
  /// (journaled before anything is cleared; hashes, no secret).
  final List<String> forgetRefs;

  /// The same transition at [next].
  AccountTransition at(TransitionPhase next) => AccountTransition(
    kind: kind,
    phase: next,
    fromKey: fromKey,
    target: target,
    commitTag: commitTag,
    discard: discard,
    forgetRefs: forgetRefs,
  );

  Map<String, Object?> _toJson() => {
    'kind': kind.name,
    'phase': phase.name,
    'from': fromKey,
    'target': target._toJson(),
    'tag': ?commitTag,
    'discard': ?discard,
    if (forgetRefs.isNotEmpty) 'forget': forgetRefs,
  };

  // A private parser keeps the JSON shape out of the public API.
  // ignore: prefer_constructors_over_static_methods
  static AccountTransition _fromJson(Map<String, Object?> json) =>
      AccountTransition(
        kind: TransitionKind.values.byName(json['kind']! as String),
        phase: TransitionPhase.values.byName(json['phase']! as String),
        fromKey: json['from']! as String,
        target: LocalProfile._fromJson(json['target']! as Map<String, Object?>),
        commitTag: json['tag'] as String?,
        discard: json['discard'] as String?,
        forgetRefs: [
          for (final ref in json['forget'] as List<Object?>? ?? const [])
            ref! as String,
        ],
      );

  @override
  String toString() => 'AccountTransition(${kind.name}, ${phase.name})';
}

/// An account deletion bound to one profile (A35 fix 2): recorded before
/// `DELETE /v1/me` is sent, confirmed (in the same write as the removal
/// journal) once the server answered 204 or the user chose to remove the
/// data. No secret, no raw id.
final class PendingDeletion {
  /// Deletion of [profileKey]; [confirmed] once the local removal started.
  const new({required this.profileKey, this.confirmed = false});

  /// The profile whose account is being deleted.
  final String profileKey;

  /// The local removal was journaled (204, or the user's choice).
  final bool confirmed;

  Map<String, Object?> _toJson() => {'key': profileKey, 'ok': confirmed};

  // A private parser keeps the JSON shape out of the public API.
  // ignore: prefer_constructors_over_static_methods
  static PendingDeletion _fromJson(Map<String, Object?> json) =>
      PendingDeletion(
        profileKey: json['key']! as String,
        confirmed: json['ok'] as bool? ?? false,
      );

  @override
  String toString() => 'PendingDeletion(confirmed: $confirmed)';
}

/// The profiles on this install, the active one, the reserved directories
/// and the open transition (A33 D1, §6): one atomic preference value.
final class ProfilesSnapshot {
  /// [profiles] includes the active one.
  const new({
    required this.activeKey,
    required this.profiles,
    this.reserved = const [],
    this.transition,
    this.guestSeq = 1,
    this.deletion,
  });

  /// A fresh install: one guest profile, `local` (A01's existing file).
  static const initial = ProfilesSnapshot(
    activeKey: ProfileRegistry.guestKey,
    profiles: [
      LocalProfile(
        profileKey: ProfileRegistry.guestKey,
        kind: ProfileKind.guest,
      ),
    ],
  );

  /// The open profile's key.
  final String activeKey;

  /// Every known profile.
  final List<LocalProfile> profiles;

  /// Directories awaiting deletion: never reused as a profile key until
  /// their deletion succeeded (A33 §6).
  final List<String> reserved;

  /// The open account transition journal, if any.
  final AccountTransition? transition;

  /// The last guest profile number handed out (`guest-<n>`).
  final int guestSeq;

  /// An account deletion in progress (A35), if any.
  final PendingDeletion? deletion;

  /// Whether an account transition journal is open.
  bool get transitionPending => transition != null;

  /// The open profile.
  LocalProfile get active => profiles.firstWhere(
    (p) => p.profileKey == activeKey,
    orElse: () => LocalProfile(profileKey: activeKey, kind: ProfileKind.guest),
  );

  /// A new guest profile (`guest-<n>`, n above [guestSeq]) that is neither
  /// listed nor reserved: never `local` and never a directory still awaiting
  /// deletion, so a fresh guest always starts empty (A33 review 1).
  (String key, int seq) nextGuest() {
    final used = {for (final p in profiles) p.profileKey, ...reserved};
    var n = guestSeq + 1;
    while (used.contains('guest-$n')) {
      n++;
    }
    return ('guest-$n', n);
  }

  /// The registered profile of [ownerRef], if one is on this device.
  LocalProfile? ofOwner(String ownerRef) {
    for (final profile in profiles) {
      if (profile.ownerRef == ownerRef) return profile;
    }
    return null;
  }

  /// A modified copy.
  ProfilesSnapshot copyWith({
    String? activeKey,
    List<LocalProfile>? profiles,
    List<String>? reserved,
    AccountTransition? transition,
    bool clearTransition = false,
    int? guestSeq,
    PendingDeletion? deletion,
    bool clearDeletion = false,
  }) => ProfilesSnapshot(
    activeKey: activeKey ?? this.activeKey,
    profiles: profiles ?? this.profiles,
    reserved: reserved ?? this.reserved,
    transition: clearTransition ? null : transition ?? this.transition,
    guestSeq: guestSeq ?? this.guestSeq,
    deletion: clearDeletion ? null : deletion ?? this.deletion,
  );

  /// Replaces or adds [profile].
  ProfilesSnapshot put(LocalProfile profile, {String? activeKey}) => copyWith(
    activeKey: activeKey,
    profiles: [
      for (final p in profiles)
        if (p.profileKey != profile.profileKey) p,
      profile,
    ],
  );

  /// Drops [profileKey] and reserves its directory for deferred deletion.
  ProfilesSnapshot reserve(String profileKey) => copyWith(
    profiles: [
      for (final p in profiles)
        if (p.profileKey != profileKey) p,
    ],
    reserved: {...reserved, profileKey}.toList(),
  );

  /// Releases a reserved key after its directory was deleted.
  ProfilesSnapshot release(String profileKey) => copyWith(
    reserved: [
      for (final key in reserved)
        if (key != profileKey) key,
    ],
  );
}

/// Non-secret registry in `shared_preferences` (A33 D1): no tokens, no raw
/// ids, no email. Local only; read lazily when the database opens.
final class ProfileRegistry {
  /// Reads/writes through [_prefs].
  const new(this._prefs, {required this._namespace});

  final SharedPreferencesAsync _prefs;
  final String _namespace;

  /// The preference key.
  static const storageKey = 'fb.profiles.v1';

  /// The guest profile key: A01's existing `local` file.
  static const guestKey = 'local';

  /// A registered profile's directory name: a hash, not the user id.
  String profileKeyFor(String userId) => 'acct-${ownerRefFor(userId)}';

  /// Opaque account reference: 16 hex chars of sha256(namespace|userId).
  String ownerRefFor(String userId) => sha256
      .convert(utf8.encode('$_namespace|$userId'))
      .toString()
      .substring(0, 16);

  /// The stored registry, or [ProfilesSnapshot.initial]. A malformed value
  /// falls back to the guest profile rather than blocking startup.
  Future<ProfilesSnapshot> read() async {
    final raw = await _prefs.getString(storageKey);
    if (raw == null) return ProfilesSnapshot.initial;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final transition = json['transition'] as Map<String, Object?>?;
      final deletion = json['deletion'] as Map<String, Object?>?;
      return ProfilesSnapshot(
        activeKey: json['active']! as String,
        profiles: [
          for (final p in json['profiles']! as List<Object?>)
            LocalProfile._fromJson(p! as Map<String, Object?>),
        ],
        reserved: [
          for (final key in json['reserved'] as List<Object?>? ?? const [])
            key! as String,
        ],
        transition: transition == null
            ? null
            : AccountTransition._fromJson(transition),
        guestSeq: json['guestSeq'] as int? ?? 1,
        deletion: deletion == null ? null : PendingDeletion._fromJson(deletion),
      );
    } on Object {
      return ProfilesSnapshot.initial;
    }
  }

  /// Persists [snapshot] in one write (registry + journal are atomic).
  Future<void> write(ProfilesSnapshot snapshot) => _prefs.setString(
    storageKey,
    jsonEncode({
      'v': 1,
      'active': snapshot.activeKey,
      'profiles': [for (final p in snapshot.profiles) p._toJson()],
      if (snapshot.reserved.isNotEmpty) 'reserved': snapshot.reserved,
      if (snapshot.transition case final t?) 'transition': t._toJson(),
      'guestSeq': snapshot.guestSeq,
      if (snapshot.deletion case final d?) 'deletion': d._toJson(),
    }),
  );
}
