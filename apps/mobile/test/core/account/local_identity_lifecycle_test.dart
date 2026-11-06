import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/features/account/application/local_identity.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_fakes.dart';

/// The profile host as `OpenProfileHost` wires it (A63 PA3): the files go,
/// then the profile's device-local state (here: who was signed in). A
/// failing removal fails the deletion step, so the journal retries it.
final class _IdentityHost implements ProfileHost {
  new(this._files, this._store);

  final FakeHost _files;
  final LocalIdentityStore _store;
  Error? failOnDeleted;

  @override
  Future<void> activate(String profileKey) => _files.activate(profileKey);

  @override
  Future<void> deleteFiles(String profileKey) async {
    await _files.deleteFiles(profileKey);
    if (failOnDeleted case final error?) throw error;
    await _store.remove(profileKey);
  }

  @override
  Future<void> quiesce() => _files.quiesce();
}

/// Activation as the app does it (`OpenProfileHost` + the providers'
/// `select`, A63 review): the profile key goes to the files, then
/// [onSelect] starts a new generation (the app's tree, the sign-in screen
/// with it, goes), then the old database takes a while to close.
final class _SwitchingHost implements ProfileHost {
  new(this._files, this.onSelect);

  final FakeHost _files;
  final void Function() onSelect;

  @override
  Future<void> activate(String profileKey) async {
    await _files.activate(profileKey);
    onSelect();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  @override
  Future<void> deleteFiles(String profileKey) => _files.deleteFiles(profileKey);

  @override
  Future<void> quiesce() => _files.quiesce();
}

/// A container with the app's sign-in wiring ([keepSignedIn]) over the
/// fakes, the [transitions] given.
List<Override> _switchOverrides({
  required ProfileRegistry registry,
  required LocalIdentityStore store,
  required FakeIdentity identity,
  required AccountTransitions transitions,
}) => [
  profileRegistryProvider.overrideWithValue(registry),
  localIdentityStoreProvider.overrideWithValue(store),
  accountServiceProvider.overrideWith(
    (ref) => AccountService(
      identity: identity,
      transitions: transitions,
      registry: registry,
      google: FakeGoogle(available: false),
      revoke: (_) async {},
      onSignedIn: keepSignedIn(ref),
    ),
  ),
  accountStatusProvider.overrideWith((ref) async {
    final active = (await ref.watch(profileRegistryProvider).read()).active;
    return active.kind == ProfileKind.guest
        ? AccountStatus.guest
        : AccountStatus.signedIn;
  }),
];

void main() {
  late ProfileRegistry registry;
  late LocalIdentityStore store;
  late _IdentityHost host;
  late AccountTransitions transitions;
  late AccountService service;

  setUp(() {
    final log = EventLog();
    registry = memoryRegistry();
    store = LocalIdentityStore(SharedPreferencesAsync(), namespace: 'dev');
    host = _IdentityHost(FakeHost(log), store);
    transitions = AccountTransitions(
      registry: registry,
      session: FakeSession(log),
      host: host,
      newTag: () => 'tag',
    );
    service = AccountService(
      identity: FakeIdentity(),
      transitions: transitions,
      registry: registry,
      google: FakeGoogle(available: false),
      revoke: (_) async {},
    );
  });

  /// Signs in by email and stores who signed in, as the controller does.
  Future<String> signIn() async {
    final flow = service.newFlow();
    final result = await flow.verifyEmail(
      await flow.startEmail(canaryEmail),
      '123456',
    );
    final who = result.identity!;
    await store.save(who.profileKey, LocalIdentity(email: who.email));
    return who.profileKey;
  }

  test('AC-004 AC-005 T-M6 sign-out removing the copy removes who was signed '
      'in; keeping it keeps the identity on the read-only copy', () async {
    final key = await signIn();
    await service.signOut(SignOutChoice.keep);
    expect((await store.read(key)).email, canaryEmail);
    expect(
      (await registry.read()).profiles.any((p) => p.profileKey == key),
      isTrue,
    );

    final second = await signIn();
    await service.signOut(SignOutChoice.remove);
    expect(await store.read(second), const LocalIdentity());
  });

  test('AC-005 A63 PA3 T-M6 a removal interrupted after the files went is '
      'finished by recovery, identity included', () async {
    final key = await signIn();
    host.failOnDeleted = StateError('preferences');
    try {
      await service.signOut(SignOutChoice.remove);
    } on Object {
      // The cleanup failed; the journal keeps it.
    }
    expect((await store.read(key)).email, canaryEmail);
    host.failOnDeleted = null;
    await transitions.recover();
    expect(await store.read(key), const LocalIdentity());
  });

  test('AC-005 T-M6 a guest never shows another profile identity; an '
      'account shows its own', () async {
    // A leftover under the guest key (a profile signed out and reused).
    await store.save(
      ProfileRegistry.guestKey,
      const LocalIdentity(name: 'Someone else'),
    );
    var status = AccountStatus.guest;
    final container = ProviderContainer(
      overrides: [
        profileRegistryProvider.overrideWithValue(registry),
        localIdentityStoreProvider.overrideWithValue(store),
        accountStatusProvider.overrideWith((ref) async => status),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(meIdentityProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(meIdentityProvider.future), isNull);

    final key = await signIn();
    status = AccountStatus.signedIn;
    container.invalidate(accountStatusProvider);
    final shown = await container.read(meIdentityProvider.future);
    expect(shown?.profileKey, key);
    expect(shown?.identity.email, canaryEmail);
    expect(
      await container.read(meIdentityProvider.notifier).setName('Abood'),
      isTrue,
    );
    expect(
      (await container.read(meIdentityProvider.future))?.identity.name,
      'Abood',
    );
  });

  test('AC-003 AC-005 M2 A63 review an email sign-in whose discard switches '
      'the profile keeps who signed in under the new profile and leaves the '
      'name to ask there, though the switch disposed the screen', () async {
    final log = EventLog();
    final identity = FakeIdentity()..linkConflicts = true;
    late final ProviderContainer container;
    ProviderSubscription<SignInState>? screen;
    final transitions = AccountTransitions(
      registry: registry,
      session: FakeSession(log),
      host: _SwitchingHost(FakeHost(log), () {
        container.read(profileGenerationProvider.notifier).bump();
        screen?.close();
      }),
      newTag: () => 'tag',
    );
    container = ProviderContainer(
      overrides: [
        ..._switchOverrides(
          registry: registry,
          store: store,
          identity: identity,
          transitions: transitions,
        ),
      ],
    );
    addTearDown(container.dispose);
    screen = container.listen(signInControllerProvider, (_, _) {});
    final controller = container.read(signInControllerProvider.notifier);
    await controller.submitEmail(canaryEmail);
    await controller.submitCode('123456');
    expect(container.read(signInControllerProvider).step, SignInStep.conflict);
    await controller.choose(ConflictChoice.discard);
    expect(container.read(signInControllerProvider).step, SignInStep.code);
    // Completes the sign-in; the switch disposes the controller meanwhile.
    await controller.submitCode('123456');

    final key = (await registry.read()).activeKey;
    expect(key, registry.profileKeyFor(userA));
    expect(await store.read(key), const LocalIdentity(email: canaryEmail));
    expect(container.read(recentSignInProvider), (
      profileKey: key,
      askName: true,
    ));
    final me = container.listen(meIdentityProvider, (_, _) {});
    addTearDown(me.close);
    final shown = await container.read(meIdentityProvider.future);
    expect(shown?.profileKey, key);
    expect(shown?.identity.email, canaryEmail);
    // Named on the new profile (Today's prompt): asked once, never again.
    expect(
      await container.read(meIdentityProvider.notifier).setName('Abood'),
      isTrue,
    );
    expect(container.read(recentSignInProvider)?.askName, isFalse);
    expect((await store.read(key)).name, 'Abood');
  });
}
