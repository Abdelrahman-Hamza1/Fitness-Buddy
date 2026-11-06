import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesAsync preferences;
  late LocalIdentityStore store;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    store = LocalIdentityStore(preferences, namespace: 'dev|local');
  });

  Future<Set<String>> live(Set<String> keys) async => keys;

  test('AC-005 T-M1 identities round-trip per profile; trimmed, one line, '
      'at most 40 characters; empty is none', () async {
    await store.save(
      'acct-a',
      const LocalIdentity(name: '  Abood\nH  ', email: ' a@example.invalid '),
    );
    await store.save('acct-b', const LocalIdentity(email: 'b@example.invalid'));
    expect(
      await store.read('acct-a'),
      const LocalIdentity(name: 'Abood H', email: 'a@example.invalid'),
    );
    expect(
      await store.read('acct-b'),
      const LocalIdentity(email: 'b@example.invalid'),
    );
    expect(await store.read('guest'), const LocalIdentity());

    await store.setName('acct-b', 'ع' * 50);
    final b = await store.read('acct-b');
    expect(b.name!.runes, hasLength(LocalIdentity.nameMax));
    expect(b.email, 'b@example.invalid');
    await store.setName('acct-b', '   ');
    expect(
      await store.read('acct-b'),
      const LocalIdentity(email: 'b@example.invalid'),
    );
    await store.save('acct-b', const LocalIdentity(name: ' ', email: ''));
    expect(
      await preferences.getString(
        PreferenceKeys.identityFor('dev|local', 'acct-b'),
      ),
      isNull,
    );
    await preferences.setString(
      PreferenceKeys.identityFor('dev|local', 'acct-c'),
      'not json',
    );
    expect(await store.read('acct-c'), const LocalIdentity());
  });

  test('AC-005 T-M1 prune removes only removed profiles of this '
      'environment; remove drops one', () async {
    final other = LocalIdentityStore(preferences, namespace: 'prod|api');
    await store.save('acct-a', const LocalIdentity(name: 'A'));
    await store.save('acct-b', const LocalIdentity(name: 'B'));
    await other.save('acct-a', const LocalIdentity(name: 'Other'));
    await store.prune(() => live({'acct-a', 'guest'}));
    expect((await store.read('acct-a')).name, 'A');
    expect(await store.read('acct-b'), const LocalIdentity());
    expect((await other.read('acct-a')).name, 'Other');
    await store.remove('acct-a');
    expect(await store.read('acct-a'), const LocalIdentity());
  });

  test('AC-005 A63 PA3 T-M6 a prune queued after a save reads the live keys '
      'after it; a failed write never blocks later ones', () async {
    var registry = <String>{};
    final saving = store.save('acct-new', const LocalIdentity(name: 'New'));
    // The sign-in committed (the registry has the key) before the prune
    // reads it.
    registry = {'acct-new'};
    final pruning = store.prune(() async => registry);
    await Future.wait([saving, pruning]);
    expect((await store.read('acct-new')).name, 'New');

    await expectLater(
      store.prune(() async => throw StateError('registry')),
      throwsStateError,
    );
    await store.setName('acct-new', 'Newer');
    expect((await store.read('acct-new')).name, 'Newer');
  });

  test('AC-041 rule 6 T-M4 LocalIdentity text says only whether parts are '
      'set', () {
    const identity = LocalIdentity(name: 'Abood', email: 'a@example.invalid');
    expect('$identity', 'LocalIdentity(name: set, email: set)');
    expect(
      '${const LocalIdentity()}',
      'LocalIdentity(name: none, email: none)',
    );
  });
}
