import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_fakes.dart';

void main() {
  final revoked = <String>[];
  setUp(revoked.clear);
  late EventLog log;
  late FakeIdentity identity;
  late FakeSession session;
  late FakeHost host;
  late ProfileRegistry registry;
  late AccountService service;
  var tags = 0;
  SignInFlow? current;

  /// The open sign-in flow, or a new one once the last completed.
  SignInFlow flow() {
    final open = current;
    if (open != null && open.isOpen) return open;
    return current = service.newFlow();
  }

  AccountService build({GoogleIdTokenSource? google}) => AccountService(
    identity: identity,
    transitions: AccountTransitions(
      registry: registry,
      session: session,
      host: host,
      newTag: () => 'tag-${++tags}',
    ),
    registry: registry,
    google: google ?? FakeGoogle(available: false),
    revoke: (token) async => revoked.add(token),
  );

  Future<AccountOutcome> emailSignIn([String email = canaryEmail]) async {
    final f = service.newFlow();
    return await f.verifyEmail(await f.startEmail(email), '123456');
  }

  setUp(() {
    current = null;
    log = EventLog();
    identity = FakeIdentity();
    session = FakeSession(log);
    host = FakeHost(log);
    registry = memoryRegistry();
    service = build();
  });

  test('AC-003 email link keeps the same user id and re-owns the guest '
      'profile', () async {
    final challenge = await flow().startEmail(canaryEmail);
    expect(challenge.link, isTrue);
    final outcome = await flow().verifyEmail(challenge, '123456');

    expect(outcome, AccountOutcome.upgraded);
    expect(identity.calls, ['start:link', 'link:email']);
    expect(session.accepted, [userA]);
    final active = (await registry.read()).active;
    expect(active.profileKey, ProfileRegistry.guestKey);
    expect(active.kind, ProfileKind.registered);
    expect(active.ownerRef, registry.ownerRefFor(userA));
    expect(host.activated, isEmpty, reason: 'same database stays open');
  });

  test(
    'AC-003 409 offers merge or discard; merge keeps the guest rows',
    () async {
      identity.linkConflicts = true;
      final first = await flow().startEmail(canaryEmail);
      expect(
        await flow().verifyEmail(first, '123456'),
        AccountOutcome.needsConflictChoice,
      );
      expect(session.accepted, isEmpty);

      expect(await flow().chooseOnConflict(ConflictChoice.merge), isNull);
      final second = await flow().startEmail(canaryEmail);
      expect(second.link, isFalse);
      expect(await flow().verifyEmail(second, '654321'), AccountOutcome.merged);

      final active = (await registry.read()).active;
      expect(active.profileKey, ProfileRegistry.guestKey);
      expect(active.kind, ProfileKind.registered);
      expect(host.deleted, isEmpty);
    },
  );

  test('AC-003 discard deletes the guest database only after the token is '
      'stored and the account opened', () async {
    identity.linkConflicts = true;
    service = build(google: FakeGoogle());
    expect(await flow().signInWithGoogle(), AccountOutcome.needsConflictChoice);
    expect(
      await flow().chooseOnConflict(ConflictChoice.discard),
      AccountOutcome.switched,
    );

    final key = registry.profileKeyFor(userA);
    expect(log.events, [
      'quiesce',
      'accept',
      'activate:$key',
      'delete:${ProfileRegistry.guestKey}',
    ]);
    expect((await registry.read()).activeKey, key);
  });

  test('AC-003 merge is blocked when a kept copy of the account is already '
      'on the phone: nothing changes, both copies stay', () async {
    // A kept read-only copy of the account, then a new guest with data.
    await emailSignIn();
    await service.signOut(SignOutChoice.keep);
    await service.continueAsGuest();
    final guestKey = (await registry.read()).activeKey;
    expect(guestKey, 'guest-2');
    final before = await registry.read();
    final accepted = session.accepted.length;
    identity.linkConflicts = true;

    final f = service.newFlow();
    expect(
      await f.verifyEmail(await f.startEmail(canaryEmail), '1'),
      AccountOutcome.needsConflictChoice,
    );
    await f.chooseOnConflict(ConflictChoice.merge);
    expect(
      await f.verifyEmail(await f.startEmail(canaryEmail), '2'),
      AccountOutcome.mergeBlocked,
    );
    final after = await registry.read();
    expect(after.activeKey, guestKey);
    expect(
      after.profiles.map((p) => p.profileKey).toSet(),
      before.profiles.map((p) => p.profileKey).toSet(),
    );
    expect(session.accepted.length, accepted, reason: 'tokens dropped');
    await pumpEventQueue();
    expect(revoked, [canaryToken], reason: 'abandoned session revoked');
    expect(host.deleted, isEmpty);
    expect(f.isOpen, isTrue);

    // Discard is still possible: it opens the kept copy for editing.
    await f.chooseOnConflict(ConflictChoice.discard);
    expect(
      await f.verifyEmail(await f.startEmail(canaryEmail), '3'),
      AccountOutcome.switched,
    );
    final opened = await registry.read();
    expect(opened.activeKey, ProfileRegistry.guestKey);
    expect(opened.active.readOnly, isFalse);
    expect(host.deleted, [guestKey]);
  });

  test('AC-003 a failure before the credentials are committed revokes the '
      'issued session', () async {
    final f = service.newFlow();
    final challenge = await f.startEmail(canaryEmail);
    registryPreferences.failNthWrite(1); // The transition's journal write.
    await expectLater(
      f.verifyEmail(challenge, '123456'),
      throwsA(
        isA<AccountFailure>().having(
          (e) => e.kind,
          'kind',
          AccountFailureKind.rejected,
        ),
      ),
    );
    await pumpEventQueue();
    expect(revoked, [canaryToken]);
    expect(session.accepted, isEmpty);
  });

  test('AC-004 sign out keep marks the profile read-only', () async {
    await emailSignIn();
    await service.signOut(SignOutChoice.keep);

    expect((await registry.read()).active.readOnly, isTrue);
    expect(session.ended, 1);
    expect(host.deleted, isEmpty);
    expect(identity.calls.last, 'logout');
  });

  test('AC-004 remove after an in-place upgrade never reuses local: it stays '
      'reserved until deleted and a distinct empty guest opens', () async {
    await emailSignIn();
    expect((await registry.read()).activeKey, ProfileRegistry.guestKey);
    log.events.clear();
    session.onEnd = () async {
      final snapshot = await registry.read();
      expect(snapshot.activeKey, 'guest-2');
      expect(snapshot.reserved, [ProfileRegistry.guestKey]);
    };

    await service.signOut(SignOutChoice.remove);

    expect(log.events, [
      'quiesce',
      'activate:guest-2',
      'end',
      'delete:${ProfileRegistry.guestKey}',
    ]);
    final snapshot = await registry.read();
    expect(snapshot.activeKey, 'guest-2');
    expect(snapshot.active.kind, ProfileKind.guest);
    expect(snapshot.reserved, isEmpty);
    expect(
      snapshot.profiles.map((p) => p.profileKey),
      isNot(contains(ProfileRegistry.guestKey)),
    );

    // A later fresh guest is again new, never a recycled directory.
    session.onEnd = null;
    await emailSignIn();
    await service.signOut(SignOutChoice.remove);
    expect((await registry.read()).activeKey, 'guest-3');
  });

  test(
    'AC-004 sign out works offline (server logout is best effort)',
    () async {
      await emailSignIn();
      identity.offline = true;
      await service.signOut(SignOutChoice.keep);
      expect((await registry.read()).active.readOnly, isTrue);
    },
  );

  test('AC-001 session expired: signing in again keeps the same profile and '
      'database', () async {
    await emailSignIn();
    final before = (await registry.read()).active.profileKey;

    final challenge = await flow().startEmail(canaryEmail);
    expect(challenge.link, isFalse);
    expect(
      await flow().verifyEmail(challenge, '2'),
      AccountOutcome.sameAccount,
    );
    expect((await registry.read()).active.profileKey, before);
    expect(host.activated, isEmpty);
    expect(session.accepted, [userA, userA]);
  });

  test('AC-001 Google is unavailable until configured', () async {
    expect(service.googleAvailable, isFalse);
    await expectLater(
      flow().signInWithGoogle(),
      throwsA(
        isA<AccountFailure>().having(
          (f) => f.kind,
          'kind',
          AccountFailureKind.googleUnavailable,
        ),
      ),
    );
  });

  test('AC-003 google link keeps the same user id and re-owns the guest '
      'profile', () async {
    service = build(google: FakeGoogle());
    expect(service.googleAvailable, isTrue);

    expect(await flow().signInWithGoogle(), AccountOutcome.upgraded);

    expect(identity.calls, ['link:google']);
    expect(session.accepted, [userA]);
    final active = (await registry.read()).active;
    expect(active.profileKey, ProfileRegistry.guestKey);
    expect(active.kind, ProfileKind.registered);
    expect(active.ownerRef, registry.ownerRefFor(userA));
    expect(host.activated, isEmpty, reason: 'same database stays open');
  });

  test('AC-002 a Google failure leaves the guest untouched', () async {
    final google = FakeGoogle();
    service = build(google: google);
    final before = await registry.read();
    for (final (kind, expected) in [
      (GoogleIdTokenFailure.unavailable, AccountFailureKind.googleUnavailable),
      (
        GoogleIdTokenFailure.misconfigured,
        AccountFailureKind.googleUnavailable,
      ),
      (GoogleIdTokenFailure.failed, AccountFailureKind.rejected),
    ]) {
      google.failure = GoogleIdTokenException(kind);
      await expectLater(
        service.newFlow().signInWithGoogle(),
        throwsA(isA<AccountFailure>().having((f) => f.kind, 'kind', expected)),
      );
    }

    expect(identity.calls, isEmpty, reason: 'no server call');
    expect(session.accepted, isEmpty);
    expect(log.events, isEmpty);
    final after = await registry.read();
    expect(after.activeKey, before.activeKey);
    expect(after.active.kind, ProfileKind.guest);
  });

  test('AC-001 a Google token the server refuses is a sign-in failure, not a '
      'wrong code', () async {
    service = build(google: FakeGoogle());
    for (final status in [400, 401]) {
      identity.refuse = problem(status, '/errors/unauthorized');
      await expectLater(
        service.newFlow().signInWithGoogle(),
        throwsA(
          isA<AccountFailure>().having(
            (f) => f.kind,
            'kind',
            AccountFailureKind.rejected,
          ),
        ),
      );
    }
    // Email keeps its own meaning for the same status.
    final f = service.newFlow();
    final challenge = await f.startEmail(canaryEmail);
    await expectLater(
      f.verifyEmail(challenge, '000000'),
      throwsA(
        isA<AccountFailure>().having(
          (e) => e.kind,
          'kind',
          AccountFailureKind.invalidCode,
        ),
      ),
    );
    expect(session.accepted, isEmpty);
  });

  test('AC-004 sign-out completes when Google sign-out throws', () async {
    final google = FakeGoogle()..signOutError = StateError('plugin fault');
    service = build(google: google);
    await flow().signInWithGoogle();

    await service.signOut(SignOutChoice.keep);

    expect(google.signOuts, 1);
    expect(session.ended, 1);
    expect((await registry.read()).active.readOnly, isTrue);
  });

  test('Rule:09.4-no-content-logging failures, challenges and the registry '
      'carry no email, id or token', () async {
    identity.offline = true;
    Object? error;
    try {
      await flow().startEmail(canaryEmail);
    } on Object catch (e) {
      error = e;
    }
    expect(error.toString(), 'AccountFailure(offline)');

    identity.offline = false;
    final challenge = await flow().startEmail(canaryEmail);
    expect(challenge.toString(), isNot(contains(challenge.challengeId)));
    await flow().verifyEmail(challenge, '1');
    final raw =
        await SharedPreferencesAsync().getString(ProfileRegistry.storageKey) ??
        '';
    for (final secret in [userA, canaryToken, canaryEmail]) {
      expect(raw, isNot(contains(secret)));
    }
  });
}
