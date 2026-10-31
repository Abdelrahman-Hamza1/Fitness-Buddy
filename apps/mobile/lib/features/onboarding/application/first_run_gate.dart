import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/features/onboarding/data/first_run_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'first_run_gate.g.dart';

/// Whether the first run may show at all: off in device and widget tests
/// that start the whole app for something else (TD-110).
@riverpod
bool firstRunEnabled(Ref ref) => true;

/// Decides the first run (D-088, TD-110), after the first frame: only on a
/// phone that has never had it, with one guest profile that has never held
/// any data. A
/// phone that already holds data is marked at once, so an existing install
/// never sees it. Any failure means "no first run": it must never stand in
/// the way of the app.
final class FirstRunGate {
  /// Over [_store] and the profile [_registry]; [enabled] is
  /// [firstRunEnabled].
  const new(this._store, this._registry, {required this.enabled});

  final FirstRunStore _store;
  final ProfileRegistry _registry;

  /// Whether the gate may show the first run at all.
  final bool enabled;

  /// Whether to show the welcome screen now.
  Future<bool> shouldShow() async {
    if (!enabled) return false;
    try {
      if (await _store.seen()) return false;
      final registry = await _registry.read();
      // An account, a kept copy or any other profile on the phone, or data
      // in this one: not a fresh install.
      if (registry.active.kind != ProfileKind.guest ||
          registry.active.readOnly ||
          registry.profiles.length > 1 ||
          await _store.hasLocalData()) {
        await _store.markSeen();
        return false;
      }
      return true;
    } on Object {
      return false;
    }
  }

  /// Records that the first run happened (the welcome screen was left).
  Future<void> markSeen() async {
    try {
      await _store.markSeen();
    } on Object {
      // A preference that can't be written shows the welcome once more.
    }
  }
}

/// The app's [FirstRunGate].
@riverpod
FirstRunGate firstRunGate(Ref ref) => FirstRunGate(
  ref.watch(firstRunStoreProvider),
  ref.watch(profileRegistryProvider),
  enabled: ref.watch(firstRunEnabledProvider),
);
