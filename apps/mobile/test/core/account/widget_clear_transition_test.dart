import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_fakes.dart';

void main() {
  late EventLog log;
  late ProfileRegistry registry;
  late FakeSession session;
  late AccountTransitions transitions;

  /// What the registry said when the widgets were cleared.
  late List<({String active, bool readOnly})> seen;
  Error? failClear;

  setUp(() {
    log = EventLog();
    registry = memoryRegistry();
    session = FakeSession(log);
    seen = [];
    failClear = null;
    var tags = 0;
    transitions = AccountTransitions(
      registry: registry,
      session: session,
      host: FakeHost(log),
      newTag: () => 'tag-${++tags}',
      beforeSwitch: () async {
        if (failClear case final error?) throw error;
        final active = (await registry.read()).active;
        seen.add((active: active.profileKey, readOnly: active.readOnly));
        log.events.add('widgets-cleared');
      },
    );
  });

  Future<String> signedInA() async {
    await transitions.signIn(
      tokens: issued(userA),
      plan: (_) => (
        target: LocalProfile(
          profileKey: registry.profileKeyFor(userA),
          kind: ProfileKind.registered,
          ownerRef: registry.ownerRefFor(userA),
        ),
        discard: null,
      ),
      stillValid: () => true,
    );
    seen.clear();
    log.events.clear();
    return registry.profileKeyFor(userA);
  }

  test('UX-085 A71 review: a profile switch clears the widgets before the '
      'new profile is active', () async {
    final key = await signedInA();
    await transitions.continueAsGuest();
    expect(seen, [(active: key, readOnly: false)]);
    expect(
      log.events.indexOf('widgets-cleared'),
      lessThan(log.events.indexWhere((e) => e.startsWith('activate:'))),
    );
  });

  test('UX-085 A71 review: sign-out keep clears before the profile turns '
      'read-only', () async {
    final key = await signedInA();
    await transitions.signOut(keep: true);
    expect(seen, [(active: key, readOnly: false)]);
    expect((await registry.read()).active.readOnly, isTrue);
  });

  test('UX-085 A71 review: sign-out remove and a removal (account deletion) '
      'clear before the switch to the new guest', () async {
    final key = await signedInA();
    await transitions.signOut(keep: false);
    expect(seen, [(active: key, readOnly: false)]);
    expect(log.events.first, 'quiesce');
    expect(log.events[1], 'widgets-cleared');
    expect(log.events[2], startsWith('activate:'));

    seen.clear();
    final guest = (await registry.read()).activeKey;
    await transitions.removeProfile(guest);
    expect(seen, [(active: guest, readOnly: false)]);
    expect((await registry.read()).activeKey, isNot(guest));
  });

  test('UX-085 A71 review: a removal interrupted before its switch clears '
      'the widgets when recovery resumes it', () async {
    final key = await signedInA();
    final snapshot = await registry.read();
    await registry.write(
      snapshot.copyWith(
        transition: AccountTransition(
          kind: TransitionKind.signOut,
          phase: TransitionPhase.preparing,
          fromKey: key,
          target: const LocalProfile(
            profileKey: 'guest-9',
            kind: ProfileKind.guest,
          ),
          discard: key,
        ),
        deletion: PendingDeletion(profileKey: key, confirmed: true),
      ),
    );
    await transitions.recover();
    expect(seen, [(active: key, readOnly: false)]);
    expect((await registry.read()).activeKey, 'guest-9');
  });

  test('A71 review: a clear that fails stops the switch (fail closed); the '
      'profile stays as it was', () async {
    final key = await signedInA();
    failClear = StateError('not committed');
    await expectLater(transitions.signOut(keep: true), throwsStateError);
    final active = (await registry.read()).active;
    expect(active.profileKey, key);
    expect(active.readOnly, isFalse);
  });
}
