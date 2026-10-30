import 'dart:async';

import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_fakes.dart';

Matcher _failure(AccountFailureKind kind) =>
    throwsA(isA<AccountFailure>().having((f) => f.kind, 'kind', kind));

void main() {
  final revoked = <String>[];
  setUp(revoked.clear);
  late EventLog log;
  late FakeIdentity identity;
  late FakeSession session;
  late FakeGoogle google;
  late ProfileRegistry registry;
  late AccountService service;

  setUp(() {
    log = EventLog();
    identity = FakeIdentity()..linkConflicts = true;
    session = FakeSession(log);
    google = FakeGoogle();
    registry = memoryRegistry();
    service = AccountService(
      identity: identity,
      transitions: AccountTransitions(
        registry: registry,
        session: session,
        host: FakeHost(log),
        newTag: () => 'tag',
      ),
      registry: registry,
      google: google,
      revoke: (token) async => revoked.add(token),
    );
  });

  test('AC-003 conflict consent is bound to the address that hit the '
      'conflict', () async {
    final flow = service.newFlow();
    final first = await flow.startEmail(canaryEmail);
    expect(
      await flow.verifyEmail(first, '123456'),
      AccountOutcome.needsConflictChoice,
    );
    await flow.chooseOnConflict(ConflictChoice.discard);

    // Another address: the consent doesn't carry over.
    final other = await flow.startEmail('other-$canaryEmail');
    expect(other.link, isTrue);
    // Back to the first address: consent was dropped with the rebind.
    final again = await flow.startEmail(canaryEmail);
    expect(again.link, isTrue);
  });

  test('AC-003 cancel discards consent; a new flow starts clean', () async {
    final flow = service.newFlow();
    await flow.verifyEmail(await flow.startEmail(canaryEmail), '123456');
    await flow.chooseOnConflict(ConflictChoice.merge);
    flow.cancel();

    expect(flow.isOpen, isFalse);
    await expectLater(
      flow.startEmail(canaryEmail),
      _failure(AccountFailureKind.cancelled),
    );
    final fresh = service.newFlow();
    expect((await fresh.startEmail(canaryEmail)).link, isTrue);
  });

  test('AC-003 a new flow cancels the previous one', () async {
    final first = service.newFlow();
    service.newFlow();
    expect(first.isOpen, isFalse);
    await expectLater(
      first.chooseOnConflict(ConflictChoice.discard),
      _failure(AccountFailureKind.cancelled),
    );
  });

  test('AC-004 sign-out discards a pending Google token and consent', () async {
    final flow = service.newFlow();
    expect(await flow.signInWithGoogle(), AccountOutcome.needsConflictChoice);
    await service.signOut(SignOutChoice.keep);
    await expectLater(
      flow.chooseOnConflict(ConflictChoice.discard),
      _failure(AccountFailureKind.cancelled),
    );
    expect(identity.calls.where((c) => c == 'google'), isEmpty);
  });

  test('AC-003 a different Google token drops the earlier consent', () async {
    final flow = service.newFlow();
    await flow.signInWithGoogle();
    google.token = 'another-canary-token';
    expect(await flow.signInWithGoogle(), AccountOutcome.needsConflictChoice);
    expect(identity.calls, ['link:google', 'link:google']);
  });

  test('AC-003 a flow cancelled while the server call is in flight commits '
      'nothing', () async {
    identity
      ..linkConflicts = false
      ..hold = Completer<void>();
    final flow = service.newFlow();
    final challenge = await flow.startEmail(canaryEmail);
    final verifying = flow.verifyEmail(challenge, '123456');
    final check = expectLater(
      verifying,
      _failure(AccountFailureKind.cancelled),
    );
    flow.cancel();
    identity.hold!.complete();
    await check;
    expect(session.accepted, isEmpty);
    expect((await registry.read()).active.kind, ProfileKind.guest);
    await pumpEventQueue();
    expect(revoked, [canaryToken], reason: 'issued then abandoned: revoked');
  });
}
