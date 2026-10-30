import 'dart:async';

import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_fakes.dart';

void main() {
  late EventLog log;
  late ProfileRegistry registry;
  late FakeSession session;
  late FakeHost host;
  late AccountTransitions transitions;
  late List<bool> busyLog;
  var logBusy = false;

  setUp(() {
    log = EventLog();
    registry = memoryRegistry();
    session = FakeSession(log);
    host = FakeHost(log);
    var tags = 0;
    busyLog = [];
    logBusy = false;
    transitions = AccountTransitions(
      registry: registry,
      session: session,
      host: host,
      newTag: () => 'tag-${++tags}',
      onBusy: ({required busy}) {
        busyLog.add(busy);
        if (logBusy) log.events.add('busy:$busy');
      },
    );
  });

  LocalProfile account(String userId) => LocalProfile(
    profileKey: registry.profileKeyFor(userId),
    kind: ProfileKind.registered,
    ownerRef: registry.ownerRefFor(userId),
  );

  Future<void> signIn(
    String userId, {
    String? discard,
    bool Function()? stillValid,
  }) => transitions.signIn(
    tokens: issued(userId),
    plan: (_) => (target: account(userId), discard: discard),
    stillValid: stillValid ?? () => true,
  );

  test('AC-003 sign-in stores the tokens durably before any profile change '
      'or deletion, with writes suspended', () async {
    session.onAccept = () async {
      final snapshot = await registry.read();
      expect(snapshot.activeKey, ProfileRegistry.guestKey);
      expect(snapshot.transition!.phase, TransitionPhase.preparing);
      expect(transitions.suspended, isTrue);
      expect(session.suspensions, 1);
    };
    await signIn(userB, discard: ProfileRegistry.guestKey);

    final key = registry.profileKeyFor(userB);
    expect(log.events, [
      'quiesce',
      'accept',
      'activate:$key',
      'delete:${ProfileRegistry.guestKey}',
    ]);
    final snapshot = await registry.read();
    expect(snapshot.activeKey, key);
    expect(snapshot.transition, isNull);
    expect(snapshot.reserved, isEmpty);
    expect(transitions.suspended, isFalse);
    expect(session.suspensions, 0);
  });

  test('AC-003 a failed token commit rolls back: guest untouched, journal '
      'cleared', () async {
    session.failAccept = StateError('storage');
    await expectLater(
      signIn(userB, discard: ProfileRegistry.guestKey),
      throwsA(
        isA<SignInNotCommitted>().having(
          (e) => e.cancelled,
          'cancelled',
          false,
        ),
      ),
    );
    final snapshot = await registry.read();
    expect(snapshot.activeKey, ProfileRegistry.guestKey);
    expect(snapshot.transition, isNull);
    expect(host.deleted, isEmpty);
    expect(host.activated, isEmpty);
  });

  test('AC-003 an accept that fails after committing keeps the journal, and '
      'recovery rolls forward', () async {
    session
      ..commitThenFail = true
      ..failAccept = StateError('lost-ack');
    await expectLater(
      signIn(userB, discard: ProfileRegistry.guestKey),
      throwsStateError,
    );
    expect(
      (await registry.read()).transition!.phase,
      TransitionPhase.preparing,
    );
    expect(host.deleted, isEmpty);

    await transitions.recover();
    expect((await registry.read()).activeKey, registry.profileKeyFor(userB));
    expect(host.deleted, [ProfileRegistry.guestKey]);
  });

  test('AC-003 crash point: a flow cancelled while its sign-in waits for the '
      'lock commits neither credentials nor ownership', () async {
    host.holdQuiesce = Completer<void>();
    final earlier = transitions.continueAsGuest();
    var valid = true;
    final waiting = signIn(userB, stillValid: () => valid);
    final check = expectLater(
      waiting,
      throwsA(
        isA<SignInNotCommitted>().having((e) => e.cancelled, 'cancelled', true),
      ),
    );
    valid = false; // e.g. sign-out cancelled the flow meanwhile
    host.holdQuiesce!.complete();
    await earlier;
    await check;
    expect(session.accepted, isEmpty);
    final snapshot = await registry.read();
    expect(snapshot.transition, isNull);
    expect(snapshot.ofOwner(registry.ownerRefFor(userB)), isNull);
  });

  test('AC-003 crash point: a cancellation during the journal write rolls '
      'the preparation back before token acceptance', () async {
    var checks = 0;
    // Valid for the two checks before the write, cancelled right after it.
    await expectLater(
      signIn(userB, stillValid: () => ++checks <= 2),
      throwsA(
        isA<SignInNotCommitted>().having((e) => e.cancelled, 'cancelled', true),
      ),
    );
    expect(checks, 3);
    expect(session.accepted, isEmpty);
    expect((await registry.read()).transition, isNull);
    expect(session.suspensions, 0);
  });

  test('AC-003 a pre-commit failure is reported as not committed; a failure '
      'after the commit is not', () async {
    registryPreferences.failNthWrite(1); // The preparing journal write.
    await expectLater(
      signIn(userB),
      throwsA(
        isA<SignInNotCommitted>().having(
          (e) => e.cancelled,
          'cancelled',
          false,
        ),
      ),
    );
    expect(session.accepted, isEmpty);

    session
      ..commitThenFail = true
      ..failAccept = StateError('lost-ack');
    await expectLater(signIn(userB), throwsStateError);
  });

  test('AC-003 the app is blocked while a transition switches profiles, and '
      'released only after the switch', () async {
    logBusy = true;
    await signIn(userB, discard: ProfileRegistry.guestKey);
    final key = registry.profileKeyFor(userB);
    expect(log.events, [
      'busy:true',
      'quiesce',
      'accept',
      'activate:$key',
      'delete:${ProfileRegistry.guestKey}',
      'busy:false',
    ]);
  });

  test(
    'AC-002 startup recovery blocks the app only when a journal exists',
    () async {
      await transitions.recover();
      expect(busyLog, isEmpty);
      await registry.write(
        (await registry.read()).copyWith(
          transition: const AccountTransition(
            kind: TransitionKind.signOut,
            phase: TransitionPhase.preparing,
            fromKey: ProfileRegistry.guestKey,
            target: LocalProfile(
              profileKey: ProfileRegistry.guestKey,
              kind: ProfileKind.guest,
            ),
          ),
        ),
      );
      await transitions.recover();
      expect(busyLog, [true, false]);
    },
  );

  test('AC-003 crash point: a known-uncommitted sign-in whose rollback '
      'fails keeps the journal and the hold, and is still reported as not '
      'committed (revocable)', () async {
    session.failAccept = StateError('storage');
    registryPreferences.failNthWrite(2); // 1 = preparing, 2 = the rollback.
    await expectLater(
      signIn(userB),
      throwsA(
        isA<SignInNotCommitted>().having(
          (e) => e.cancelled,
          'cancelled',
          false,
        ),
      ),
    );
    expect(
      (await registry.read()).transition!.phase,
      TransitionPhase.preparing,
    );
    expect(session.suspensions, 1);
    expect(transitions.holdsSession, isTrue);

    session.failAccept = null;
    await transitions.recover();
    expect((await registry.read()).transition, isNull);
    expect(session.suspensions, 0);
  });

  test('UX-001 a normal start (no journal) suspends no writes and holds no '
      'session while recovering', () async {
    var suspendedDuring = true;
    session.onReconcile = () => suspendedDuring = transitions.suspended;
    await transitions.recover();
    expect(suspendedDuring, isFalse);
    expect(session.suspensions, 0);
    expect(session.reconciles, 1);
    expect(log.events, isNot(contains('quiesce')));
  });

  test('AC-003 a refused plan changes nothing', () async {
    await transitions.signIn(
      tokens: issued(userB),
      plan: (_) => null,
      stillValid: () => true,
    );
    expect(session.accepted, isEmpty);
    expect((await registry.read()).transition, isNull);
  });

  test('AC-004 sign-out keep persists the read-only state before clearing '
      'the credentials', () async {
    await signIn(userA);
    session.onEnd = () async {
      expect((await registry.read()).active.readOnly, isTrue);
    };
    await transitions.signOut(keep: true);
    final snapshot = await registry.read();
    expect(snapshot.active.readOnly, isTrue);
    expect(snapshot.transition, isNull);
    expect(session.ended, 1);
  });

  test('AC-004 sign-out remove switches to a new guest, clears credentials, '
      'and deletes the old profile last', () async {
    await signIn(userA);
    final key = registry.profileKeyFor(userA);
    log.events.clear();
    session.onEnd = () async {
      final snapshot = await registry.read();
      expect(snapshot.activeKey, 'guest-2');
      expect(snapshot.reserved, [key]);
    };
    await transitions.signOut(keep: false);
    expect(log.events, ['quiesce', 'activate:guest-2', 'end', 'delete:$key']);
    expect((await registry.read()).reserved, isEmpty);
  });

  test('AC-004 a failed credential clear fails closed: the journal stays and '
      'nothing is deleted', () async {
    await signIn(userA);
    session.failEnd = StateError('storage');
    await expectLater(transitions.signOut(keep: false), throwsStateError);
    final snapshot = await registry.read();
    expect(snapshot.transition!.phase, TransitionPhase.profileSwitched);
    expect(snapshot.reserved, [registry.profileKeyFor(userA)]);
    expect(host.deleted, isEmpty);
  });

  test('AC-003 recovery: a sign-in interrupted after the token commit rolls '
      'forward', () async {
    final snapshot = await registry.read();
    final journal = AccountTransition(
      kind: TransitionKind.signIn,
      phase: TransitionPhase.preparing,
      fromKey: ProfileRegistry.guestKey,
      target: account(userB),
      commitTag: 'tag-journal',
      discard: ProfileRegistry.guestKey,
    );
    await registry.write(snapshot.copyWith(transition: journal));
    session
      ..active = session.credentialRef(userB)
      ..activeTag = 'tag-journal';

    await transitions.recover();
    final after = await registry.read();
    expect(after.activeKey, registry.profileKeyFor(userB));
    expect(after.transition, isNull);
    expect(host.deleted, [ProfileRegistry.guestKey]);
    expect(host.activated, [registry.profileKeyFor(userB)]);
  });

  test('AC-003 crash point: an interrupted guest upgrade (same user id) '
      'with the old guest envelope still selected rolls back', () async {
    // The guest's envelope has the same key as the upgraded account (the
    // user id is unchanged) but no matching tag: not a commit.
    session
      ..active = session.credentialRef(userA)
      ..activeTag = null;
    final snapshot = await registry.read();
    await registry.write(
      snapshot.copyWith(
        transition: AccountTransition(
          kind: TransitionKind.signIn,
          phase: TransitionPhase.preparing,
          fromKey: ProfileRegistry.guestKey,
          target: account(userA).copyWith(),
          commitTag: 'tag-upgrade',
        ),
      ),
    );
    await transitions.recover();
    final after = await registry.read();
    expect(after.transition, isNull);
    expect(after.active.kind, ProfileKind.guest);
    expect(after.activeKey, ProfileRegistry.guestKey);
  });

  test('AC-003 recovery: a sign-in interrupted before the token commit rolls '
      'back', () async {
    final snapshot = await registry.read();
    await registry.write(
      snapshot.copyWith(
        transition: AccountTransition(
          kind: TransitionKind.signIn,
          phase: TransitionPhase.preparing,
          fromKey: ProfileRegistry.guestKey,
          target: account(userB),
          commitTag: 'tag-journal',
          discard: ProfileRegistry.guestKey,
        ),
      ),
    );
    await transitions.recover();
    expect((await registry.read()).activeKey, ProfileRegistry.guestKey);
    expect((await registry.read()).transition, isNull);
    expect(host.deleted, isEmpty);
  });

  test('AC-004 recovery: a sign-out interrupted after the profile switch '
      'clears credentials and finishes cleanup', () async {
    final key = registry.profileKeyFor(userA);
    final snapshot = ProfilesSnapshot(
      activeKey: 'guest-2',
      profiles: const [
        LocalProfile(profileKey: 'guest-2', kind: ProfileKind.guest),
      ],
      reserved: [key],
      transition: AccountTransition(
        kind: TransitionKind.signOut,
        phase: TransitionPhase.profileSwitched,
        fromKey: key,
        target: const LocalProfile(
          profileKey: 'guest-2',
          kind: ProfileKind.guest,
        ),
        discard: key,
      ),
    );
    await registry.write(snapshot);
    session.active = 'cred';

    await transitions.recover();
    expect((await registry.read()).activeKey, 'guest-2');
    expect(log.events, ['quiesce', 'end', 'delete:$key']);
    final after = await registry.read();
    expect(after.transition, isNull);
    expect(after.reserved, isEmpty);
  });

  test('AC-004 crash point: recovery deletes the journaled credential keys '
      'even when the pointer is already gone', () async {
    final key = registry.profileKeyFor(userA);
    session
      ..active = null
      ..stored.add('cred-orphan');
    await registry.write(
      ProfilesSnapshot(
        activeKey: 'guest-2',
        profiles: const [
          LocalProfile(profileKey: 'guest-2', kind: ProfileKind.guest),
        ],
        reserved: [key],
        transition: AccountTransition(
          kind: TransitionKind.signOut,
          phase: TransitionPhase.profileSwitched,
          fromKey: key,
          target: const LocalProfile(
            profileKey: 'guest-2',
            kind: ProfileKind.guest,
          ),
          discard: key,
          forgetRefs: const ['cred-orphan'],
        ),
      ),
    );
    await transitions.recover();
    expect(session.forgotten, ['cred-orphan']);
    expect(session.stored, isEmpty);
  });

  test(
    'AC-004 sign-out journals the credential keys before clearing them',
    () async {
      await signIn(userA);
      final ref = session.active;
      session.onEnd = () async {
        expect((await registry.read()).transition!.forgetRefs, [ref]);
      };
      await transitions.signOut(keep: false);
      expect(session.forgotten, [ref]);
    },
  );

  test('AC-004 crash point: a failed step keeps session acquisition '
      'suspended until recovery clears the journal', () async {
    await signIn(userA);
    expect(session.suspensions, 0);
    session.failEnd = StateError('storage');
    await expectLater(transitions.signOut(keep: false), throwsStateError);
    expect(session.suspensions, 1);
    expect(transitions.holdsSession, isTrue);

    session.failEnd = null;
    await transitions.recover();
    expect((await registry.read()).transition, isNull);
    expect(session.suspensions, 0);
  });

  test('AC-004 crash point: a failed journal write keeps acquisition '
      'suspended', () async {
    await signIn(userA);
    // preparing is written, then the profile-switch write fails.
    registryPreferences.failNthWrite(2);
    await expectLater(transitions.signOut(keep: true), throwsStateError);
    expect(
      (await registry.read()).transition!.phase,
      TransitionPhase.preparing,
    );
    expect(session.suspensions, 1);
    expect(session.ended, 0, reason: 'credentials untouched');

    await transitions.recover();
    expect(session.suspensions, 0);
  });

  test('AC-002 startup recovery holds acquisition while it runs and after it '
      'fails', () async {
    await registry.write(
      ProfilesSnapshot.initial.copyWith(reserved: ['acct-0123456789abcdef']),
    );
    await registry.write(
      (await registry.read()).copyWith(
        transition: const AccountTransition(
          kind: TransitionKind.signOut,
          phase: TransitionPhase.cleanupPending,
          fromKey: 'acct-0123456789abcdef',
          target: LocalProfile(
            profileKey: ProfileRegistry.guestKey,
            kind: ProfileKind.guest,
          ),
        ),
      ),
    );
    host.failDelete = StateError('io');
    await expectLater(transitions.recover(), throwsStateError);
    expect(session.suspensions, 1);
    host.failDelete = null;
    await transitions.recover();
    expect(session.suspensions, 0);
  });

  test(
    'AC-003 crash point: recovery reconciles an interrupted secure save '
    'first, and an unreadable store keeps the journal and the hold',
    () async {
      session.failReconcile = StateError('keystore');
      await registry.write(
        (await registry.read()).copyWith(
          transition: const AccountTransition(
            kind: TransitionKind.signOut,
            phase: TransitionPhase.preparing,
            fromKey: ProfileRegistry.guestKey,
            target: LocalProfile(
              profileKey: ProfileRegistry.guestKey,
              kind: ProfileKind.guest,
            ),
          ),
        ),
      );
      await expectLater(transitions.recover(), throwsStateError);
      expect((await registry.read()).transition, isNotNull);
      expect(session.suspensions, 1);

      session.failReconcile = null;
      await transitions.recover();
      expect(session.reconciles, greaterThanOrEqualTo(1));
      expect((await registry.read()).transition, isNull);
      expect(session.suspensions, 0);
    },
  );

  test('AC-003 crash point: suspension starts when a transition is enqueued, '
      'and the resolver never waits for the transition lock', () async {
    host.holdQuiesce = Completer<void>();
    final first = transitions.continueAsGuest();
    expect(transitions.suspended, isTrue);
    final second = transitions.signOut(keep: true);
    expect(transitions.suspended, isTrue);

    // A queued write reaches the resolver while both transitions wait.
    expect(
      await transitions.resolveActiveProfile().timeout(
        const Duration(seconds: 1),
      ),
      ProfileRegistry.guestKey,
    );
    host.holdQuiesce!.complete();
    await first;
    await second;
    expect(transitions.suspended, isFalse);
    expect(session.suspensions, 0);
  });

  test('AC-003 the second queued transition keeps the session hold while the '
      'first finishes', () async {
    host.holdQuiesce = Completer<void>();
    final first = transitions.continueAsGuest();
    final secondStarted = Completer<int>();
    session.onEnd = () async => secondStarted.complete(session.suspensions);
    final second = transitions.signOut(keep: true);
    host.holdQuiesce!.complete();
    await first;
    await second;
    expect(await secondStarted.future, 1);
    expect(session.suspensions, 0);
  });

  test('AC-002 the resolver runs no recovery: a pending journal stays for '
      'the bootstrap', () async {
    await registry.write(
      (await registry.read()).copyWith(
        transition: const AccountTransition(
          kind: TransitionKind.signOut,
          phase: TransitionPhase.preparing,
          fromKey: ProfileRegistry.guestKey,
          target: LocalProfile(
            profileKey: ProfileRegistry.guestKey,
            kind: ProfileKind.guest,
          ),
        ),
      ),
    );
    expect(await transitions.resolveActiveProfile(), ProfileRegistry.guestKey);
    expect((await registry.read()).transition, isNotNull);
    expect(session.reconciles, 0);
  });

  test('AC-004 recovery: a failed deletion keeps the directory reserved and '
      'retries next launch', () async {
    await registry.write(
      ProfilesSnapshot.initial.copyWith(reserved: ['acct-0123456789abcdef']),
    );
    host.failDelete = StateError('io');
    await expectLater(transitions.recover(), throwsStateError);
    expect((await registry.read()).reserved, ['acct-0123456789abcdef']);
    host.failDelete = null;
    await transitions.recover();
    expect((await registry.read()).reserved, isEmpty);
    expect(host.deleted, ['acct-0123456789abcdef']);
  });

  test(
    'Rule:09.4-no-content-logging the journal holds no raw id or token',
    () async {
      session.onAccept = () async {
        final raw = await SharedPreferencesAsync().getString(
          ProfileRegistry.storageKey,
        );
        expect(raw, contains('"transition"'));
        expect(raw, isNot(contains(userB)));
        expect(raw, isNot(contains(canaryToken)));
      };
      await signIn(userB);
      final snapshot = await registry.read();
      for (final p in snapshot.profiles) {
        expect(p.profileKey, isNot(contains(userB)));
      }
    },
  );
}
