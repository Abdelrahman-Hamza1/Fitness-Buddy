import 'dart:async';

import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_identity.g.dart';

/// Who is signed in on the open profile (AC-005, D-097, A63 D11): its
/// local key and the stored name and email. `null` for a guest (a guest
/// never shows another profile's identity). Reads only this phone's
/// preferences (TD-115); nothing else reads them. Building also prunes the
/// identities of profiles the registry no longer has (A63 PA3), best
/// effort.
@riverpod
class MeIdentity extends _$MeIdentity {
  @override
  Future<({String profileKey, LocalIdentity identity})?> build() async {
    // Rebuilt after a sign-in, sign-out or profile switch.
    // A sign-in's identity is stored by the account service after the
    // switch, so its record is watched too (A63 review).
    ref
      ..watch(accountStatusProvider)
      ..watch(profileGenerationProvider)
      ..watch(recentSignInProvider);
    final registry = ref.watch(profileRegistryProvider);
    final snapshot = await registry.read();
    final store = ref.watch(localIdentityStoreProvider);
    unawaited(
      store
          .prune(() async {
            final now = await registry.read();
            return {
              for (final p in now.profiles) p.profileKey,
              ...now.reserved,
            };
          })
          .then<void>((_) {}, onError: (Object _) {}),
    );
    final active = snapshot.active;
    if (active.kind == ProfileKind.guest) return null;
    return (
      profileKey: active.profileKey,
      identity: await store.read(active.profileKey),
    );
  }

  /// Sets the name shown on Me (Account & data › Name); an empty [name]
  /// removes it. A confirmed edit of this phone's account metadata, not
  /// user data, so no undo (TD-115). Returns whether it was stored.
  Future<bool> setName(String? name) async {
    final recent = ref.read(recentSignInProvider.notifier);
    final current = await future;
    if (current == null) return false;
    try {
      await ref
          .read(localIdentityStoreProvider)
          .setName(current.profileKey, name);
    } on Exception {
      return false;
    }
    recent.nameAsked();
    if (ref.mounted) ref.invalidateSelf();
    return true;
  }
}
