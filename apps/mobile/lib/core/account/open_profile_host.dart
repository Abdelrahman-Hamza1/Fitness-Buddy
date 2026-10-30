import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';

/// The account transitions' [ProfileHost] over the open profile's
/// [OpenProfileHandles] (A33). It never reads the database, location or
/// applier providers (they depend on the transitions: a circular
/// dependency), and its cleanup never depends on when the replacement
/// profile's providers build.
final class OpenProfileHost implements ProfileHost {
  /// `select` starts a new profile generation and selects the profile key;
  /// `fallbackRoot` gives a location for the profiles directory when no
  /// location was ever built; `activeKey` reads the registry's active
  /// profile, which is never deleted.
  new({
    required this._handles,
    required this._select,
    required this._fallbackRoot,
    required this._activeKey,
    this._onDeleted,
  });

  /// Removes device-local state kept per profile outside its directory
  /// (A28a review fix 1: the pending-scan list), after the files went.
  final Future<void> Function(String profileKey)? _onDeleted;

  final OpenProfileHandles _handles;
  final void Function(String profileKey) _select;
  final DatabaseLocation Function() _fallbackRoot;

  /// The registry's current active profile key.
  final Future<String> Function() _activeKey;
  final _closing = <Future<void>>[];

  @override
  Future<void> activate(String profileKey) async {
    final old = _handles.database;
    // Unregister the old profile at once: until the new providers build,
    // nothing may reach the closing database or its applier.
    _handles
      ..database = null
      ..clearIdle();
    _select(profileKey);
    if (old == null) return;
    // The same future the provider's dispose uses (one close per database).
    final closing = closeDatabase(old);
    _closing.add(closing);
    await closing;
  }

  @override
  Future<void> deleteFiles(String profileKey) async {
    // Never delete under an open SQLite connection.
    await Future.wait(_closing);
    // Only the root is taken from the registered location: it may still be
    // the discarded profile's own location (its replacement builds lazily),
    // so it is never asked whether [profileKey] is open. The transitions
    // never delete the registry's active profile.
    // Defence in depth at the delete boundary: never the registry's current
    // active profile, whatever the caller believes (a read failure fails
    // closed: nothing is deleted).
    if (profileKey == await _activeKey()) throw StateError('active_profile');
    final root = _handles.location ?? _fallbackRoot();
    await root.deleteProfileDirectory(profileKey);
    await _onDeleted?.call(profileKey);
  }

  @override
  Future<void> quiesce() async {
    if (_handles.idle case final idle?) await idle();
  }
}
