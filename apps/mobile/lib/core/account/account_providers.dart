import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
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

/// Google ID tokens: unconfigured until the owner sets up OAuth (A33 D7).
@Riverpod(keepAlive: true)
GoogleIdTokenSource googleIdTokenSource(Ref ref) =>
    const UnconfiguredGoogleIdTokenSource();

/// The account transition lifecycle (A33 §6). Construction does no I/O.
@Riverpod(keepAlive: true)
AccountTransitions accountTransitions(Ref ref) => AccountTransitions(
  registry: ref.watch(profileRegistryProvider),
  session: _SessionAdapter(ref.watch(sessionServiceProvider)),
  host: _RiverpodProfileHost(ref),
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

/// Switches the open database by key; deletes a closed profile's files.
final class _RiverpodProfileHost implements ProfileHost {
  new(this._ref);

  final Ref _ref;
  final _closing = <Future<void>>[];

  // Never read the database, location or applier providers from here: they
  // depend on the account transitions (resolver, write gate), so that would
  // be a circular dependency. They register themselves in the handles.
  OpenProfileHandles get _handles => _ref.read(openProfileHandlesProvider);

  @override
  Future<void> activate(String profileKey) async {
    final old = _handles.database;
    // A new generation first: everything bound to the old profile (appliers,
    // open forms, the app's widget tree) is stale from here on.
    _ref.read(profileGenerationProvider.notifier).bump();
    _ref.read(profileKeyProvider.notifier).select(profileKey);
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
    final location =
        _handles.location ?? DatabaseLocation.appSupport(profileKey);
    await location.deleteOtherProfile(profileKey);
  }

  @override
  Future<void> quiesce() async {
    if (_handles.idle case final idle?) await idle();
  }
}
