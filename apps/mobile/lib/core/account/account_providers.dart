import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/google_plugin_id_token_source.dart';
import 'package:fb_mobile/core/account/open_profile_host.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/account/profile_write_gate.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
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
    // A28a review fix 1: a deleted profile's pending scans go with it.
    onDeleted: (key) {
      final config = ref.read(appConfigProvider);
      return ref
          .read(sharedPreferencesProvider)
          .remove(
            PreferenceKeys.pendingScansFor(
              '${config.flavor.name}|${config.apiBaseUrl}',
              key,
            ),
          );
    },
  ),
  newTag: ref.watch(idGeneratorProvider).next,
  onBusy: ({required busy}) =>
      ref.read(accountBusyProvider.notifier).publish(busy: busy),
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
);

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
