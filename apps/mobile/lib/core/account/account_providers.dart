import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/account/account_removed_note_store.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/google_plugin_id_token_source.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/account/open_profile_host.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/account/profile_write_gate.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/export/export_providers.dart';
import 'package:fb_mobile/core/home_widget/home_widget_store.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_providers.g.dart';

/// The non-secret profile registry (A33 D1).
@Riverpod(keepAlive: true)
ProfileRegistry profileRegistry(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return ProfileRegistry(
    ref.watch(sharedPreferencesProvider),
    namespace: '${config.flavor.name}|${config.apiBaseUrl}',
  );
}

/// Google ID tokens (A33 D7, A50 D4/D6): the plugin when this build has the
/// web client ID and runs on Android, else hidden. Construction does nothing:
/// the plugin initializes on the first sign-in.
@Riverpod(keepAlive: true)
GoogleIdTokenSource googleIdTokenSource(Ref ref) {
  final clientId = ref.watch(appConfigProvider).googleServerClientId;
  final source = PluginGoogleIdTokenSource(serverClientId: clientId);
  return source.isAvailable ? source : const UnconfiguredGoogleIdTokenSource();
}

/// The account transition lifecycle (A33 §6). Construction does no I/O.
@Riverpod(keepAlive: true)
AccountTransitions accountTransitions(Ref ref) => AccountTransitions(
  registry: ref.watch(profileRegistryProvider),
  session: _SessionAdapter(ref.watch(sessionServiceProvider)),
  host: OpenProfileHost(
    handles: ref.watch(openProfileHandlesProvider),
    select: (key) {
      // A new generation first: everything bound to the old profile
      // (appliers, open forms, the app's widget tree) is stale from here on.
      ref.read(profileGenerationProvider.notifier).bump();
      ref.read(profileKeyProvider.notifier).select(key);
    },
    fallbackRoot: () => DatabaseLocation.appSupport('local'),
    activeKey: () async =>
        (await ref.read(profileRegistryProvider).read()).activeKey,
    // A28a review fix 1: a deleted profile's pending scans go with it,
    // who was signed in on it (A63 PA3) and its export copies. A scan or
    // identity failure fails the deletion step, so the journal retries.
    onDeleted: (key) async {
      final config = ref.read(appConfigProvider);
      await ref
          .read(sharedPreferencesProvider)
          .remove(
            PreferenceKeys.pendingScansFor(
              '${config.flavor.name}|${config.apiBaseUrl}',
              key,
            ),
          );
      await ref.read(localIdentityStoreProvider).remove(key);
      // Security audit 2026-11-07: its export share copies go at once
      // (best effort; the 24-hour sweep is the backstop).
      await ref.read(exportHandoffsProvider).removeProfile(key);
      // A71 D6 (UX-085): the home-screen widgets drop its numbers, unless
      // the new profile already wrote its own. Best effort: the switch
      // already cleared them, so a failure never holds up the deletion.
      try {
        await ref
            .read(homeWidgetStoreProvider)
            .clearFor(homeWidgetProfileTag(key));
      } on Object {
        // No widgets on this platform, or the channel failed.
      }
    },
  ),
  newTag: ref.watch(idGeneratorProvider).next,
  onBusy: ({required busy}) {
    // A71: the widgets accept snapshots again once the transition ended
    // (the coordinator then writes the new state).
    if (!busy) ref.read(homeWidgetStoreProvider).release();
    ref.read(accountBusyProvider.notifier).publish(busy: busy);
  },
  // A71 review (security 1): the widgets' numbers go, durably, before the
  // open profile or its sign-out state changes.
  beforeSwitch: () => ref.read(homeWidgetStoreProvider).clearAndHold(),
);

/// True while an account transition with a journal runs (sign-in, sign-out,
/// recovery of an interrupted one): the app shows a calm blocking state so
/// no profile-dependent UI opens until the profile generation switched
/// (A33 re-check 3).
@Riverpod(keepAlive: true)
class AccountBusy extends _$AccountBusy {
  @override
  bool build() => false;

  /// Transition coordinator publication only.
  // A command method keeps the value on Riverpod's state property.
  // ignore: use_setters_to_change_properties
  void publish({required bool busy}) => state = busy;
}

/// The registry-backed write gate, suspended during live transitions.
@Riverpod(keepAlive: true)
ProfileWriteGate accountWriteGate(Ref ref) {
  final transitions = ref.watch(accountTransitionsProvider);
  return ProfileWriteGate(
    ref.watch(profileRegistryProvider),
    suspended: () => transitions.suspended,
    currentGeneration: () => ref.read(profileGenerationProvider),
  );
}

/// Sign-in, upgrade and sign-out (A33 D4–D6, §6).
@Riverpod(keepAlive: true)
AccountService accountService(Ref ref) => AccountService(
  identity: ref.watch(fbApiProvider).identity,
  transitions: ref.watch(accountTransitionsProvider),
  registry: ref.watch(profileRegistryProvider),
  google: ref.watch(googleIdTokenSourceProvider),
  revoke: ref.watch(abandonedSessionRevokerProvider),
  account: ref.watch(fbApiProvider).account,
  removedNote: ref.watch(accountRemovedNoteStoreProvider),
  onSignedIn: keepSignedIn(ref),
);

/// The service's `onSignedIn`: stores who signed in for the committed
/// profile, then records the sign-in in [RecentSignIn] (A63 review). The
/// store and the record are taken from [ref] now, so the hand-off never
/// depends on the screen or a ref a profile switch disposed.
Future<void> Function(SignedInIdentity who, {required bool askName})
keepSignedIn(Ref ref) {
  final store = ref.watch(localIdentityStoreProvider);
  final recent = ref.watch(recentSignInProvider.notifier);
  return (who, {required askName}) async {
    try {
      await store.save(
        who.profileKey,
        LocalIdentity(name: who.displayName, email: who.email),
      );
    } finally {
      recent.record(who.profileKey, askName: askName);
    }
  };
}

/// The last sign-in on this run (A63 review): the profile it committed to
/// and whether that profile's name is still to be asked (an email sign-in,
/// M2). Memory only and kept alive, so it outlives the sign-in screen and
/// the profile switch; a change tells Me to read the stored identity again.
@Riverpod(keepAlive: true)
class RecentSignIn extends _$RecentSignIn {
  @override
  ({String profileKey, bool askName})? build() => null;

  /// A sign-in committed to [profileKey], its identity stored.
  void record(String profileKey, {required bool askName}) =>
      state = (profileKey: profileKey, askName: askName);

  /// The name was asked (answered, skipped or set elsewhere): never again.
  void nameAsked() {
    final current = state;
    if (current == null || !current.askName) return;
    state = (profileKey: current.profileKey, askName: false);
  }
}

/// Who is signed in, per local profile, on this phone only (AC-005, TD-115).
@Riverpod(keepAlive: true)
LocalIdentityStore localIdentityStore(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return LocalIdentityStore(
    ref.watch(sharedPreferencesProvider),
    namespace: '${config.flavor.name}|${config.apiBaseUrl}',
  );
}

/// The one-time "account deleted" note's device store (#241).
@Riverpod(keepAlive: true)
AccountRemovedNoteStore accountRemovedNoteStore(Ref ref) =>
    PreferencesAccountRemovedNoteStore(ref.watch(sharedPreferencesProvider));

final class _SessionAdapter implements AccountSession {
  const new(this._service);

  final SessionService _service;

  @override
  Future<void> accept(AuthTokens tokens, {required String commitTag}) =>
      _service.acceptAuthenticatedSession(tokens, commitTag: commitTag);

  @override
  Future<List<String>> storedCredentialRefs() =>
      _service.storedCredentialRefs();

  @override
  Future<void> end(List<String> refs) => _service.endSession(alsoForget: refs);

  @override
  void Function() suspend() => _service.suspend();

  @override
  Future<String?> activeCommitTag() => _service.activeCommitTag();

  @override
  Future<void> reconcile() => _service.reconcileStorage();
}
