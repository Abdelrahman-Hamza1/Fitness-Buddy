import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/changes/write_gate.dart';

/// The registry-backed write gate (A33 §6). [_suspended] is the account
/// transition's synchronous in-memory flag; the registry adds the durable
/// view (journal, read-only copy, active profile).
final class ProfileWriteGate implements WriteGate {
  /// Reads [_registry] on every check: local prefs, no network.
  const new(
    this._registry, {
    required this._suspended,
    this._currentGeneration,
  });

  final ProfileRegistry _registry;
  final bool Function() _suspended;
  final int Function()? _currentGeneration;

  @override
  Future<String?> denial(String? profileKey, {int? generation}) async {
    if (_suspended()) return 'transition';
    // A command bound to an older profile generation (e.g. a form opened
    // before a recovery switched profiles) never writes the new profile.
    if (generation != null &&
        _currentGeneration != null &&
        generation != _currentGeneration()) {
      return 'staleProfile';
    }
    final snapshot = await _registry.read();
    if (_suspended() || snapshot.transitionPending) return 'transition';
    if (profileKey != null && snapshot.activeKey != profileKey) {
      return 'inactiveProfile';
    }
    if (snapshot.active.readOnly) return 'readOnlyProfile';
    return null;
  }
}
