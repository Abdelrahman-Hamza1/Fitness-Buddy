import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_removed_note_store.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/core/api/request_guard.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/features/account/application/delete_account_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../session/session_fakes.dart' as session;
import 'account_fakes.dart';

/// `DELETE /v1/me` answering from a script: each call takes the next
/// outcome (`null` = 204); a [Completer] holds the call open.
final class _ScriptedAccount implements AccountClient {
  final List<Object?> script = [];
  int calls = 0;

  @override
  Future<void> deleteAccount() async {
    calls++;
    final next = script.isEmpty ? null : script.removeAt(0);
    if (next is Completer<void>) return await next.future;
    if (next is DioException) throw next;
  }

  @override
  Future<CurrentAccount> getMe() => throw UnimplementedError();

  @override
  Future<ClientConfig> getConfig() => throw UnimplementedError();
}

DioException _status(int code) => DioException(
  requestOptions: RequestOptions(path: '/v1/me'),
  response: Response(
    requestOptions: RequestOptions(path: '/v1/me'),
    statusCode: code,
  ),
  type: DioExceptionType.badResponse,
);

DioException _type(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/v1/me'),
  type: type,
);

/// The one-time note in memory (#241), with the guest it is bound to.
final class _Notes implements AccountRemovedNoteStore {
  ({AccountRemovedKind kind, String guest})? stored;

  @override
  Future<void> mark(
    AccountRemovedKind kind, {
    required String guestKey,
  }) async => stored = (kind: kind, guest: guestKey);

  @override
  Future<AccountRemovedKind?> take(
    String activeKey, {
    required bool removalPending,
  }) async => throw UnimplementedError();
}

Matcher _kind(AccountDeletionKind kind) =>
    throwsA(isA<AccountDeletionFailure>().having((f) => f.kind, 'kind', kind));

void main() {
  late EventLog log;
  late FakeSession sessionFake;
  late FakeHost host;
  late ProfileRegistry registry;
  late _ScriptedAccount account;
  late AccountService service;
  late AccountTransitions transitions;
  late FakeGoogle google;
  late String accountKey;

  AccountTransitions newTransitions() {
    var tags = 0;
    return AccountTransitions(
      registry: registry,
      session: sessionFake,
      host: host,
      newTag: () => 'tag-${++tags}',
    );
  }

  AccountService newService(AccountClient client) => AccountService(
    identity: FakeIdentity(),
    transitions: transitions,
    registry: registry,
    google: google,
    revoke: (_) async {},
    account: client,
  );

  setUp(() async {
    log = EventLog();
    sessionFake = FakeSession(log);
    host = FakeHost(log);
    registry = memoryRegistry();
    account = _ScriptedAccount();
    google = FakeGoogle(available: false);
    transitions = newTransitions();
    service = newService(account);
    final flow = service.newFlow();
    await flow.verifyEmail(await flow.startEmail(canaryEmail), '123456');
    accountKey = (await registry.read()).activeKey;
  });

  // covers: AC-031
  test('204: exactly the confirmed profile, its files and credentials go; '
      'a new empty guest opens; the record is cleared', () async {
    await service.deleteAccount(accountKey);
    final after = await registry.read();
    expect(after.active.kind, ProfileKind.guest);
    expect(after.profiles.any((p) => p.profileKey == accountKey), isFalse);
    expect(host.deleted, [accountKey]);
    expect(sessionFake.ended, greaterThan(0));
    expect(after.deletion, isNull);
    expect(after.transition, isNull);
    expect(google.signOuts, 1);
  });

  test('outcomes: offline, uncertain, needsSignIn; after an unconfirmed '
      'attempt a 401 or an expired session is sessionEnded', () async {
    final first = {
      _type(DioExceptionType.connectionError): AccountDeletionKind.offline,
      _type(DioExceptionType.cancel): AccountDeletionKind.offline,
      _status(401): AccountDeletionKind.needsSignIn,
    };
    for (final MapEntry(key: error, value: kind) in first.entries) {
      account.script.add(error);
      await expectLater(service.deleteAccount(accountKey), _kind(kind));
      expect(
        (await registry.read()).deletion,
        isNull,
        reason: 'nothing reached the server: no record kept',
      );
    }
    account.script.add(_type(DioExceptionType.receiveTimeout));
    await expectLater(
      service.deleteAccount(accountKey),
      _kind(AccountDeletionKind.uncertain),
    );
    expect((await registry.read()).deletion?.profileKey, accountKey);
    for (final (error, kind) in [
      (_status(500), AccountDeletionKind.uncertain),
      (_type(DioExceptionType.connectionError), AccountDeletionKind.offline),
      (_status(401), AccountDeletionKind.sessionEnded),
      (
        DioException(
          requestOptions: RequestOptions(path: '/v1/me'),
          error: const SessionFailure(SessionFailureKind.sessionExpired),
        ),
        AccountDeletionKind.sessionEnded,
      ),
    ]) {
      account.script.add(error);
      await expectLater(service.deleteAccount(accountKey), _kind(kind));
      expect(
        (await registry.read()).deletion,
        isNotNull,
        reason: 'an earlier attempt may have reached the server',
      );
    }
    expect((await registry.read()).active.kind, ProfileKind.registered);
  });

  test('while DELETE is in flight no other transition can change the '
      'profile, and the wipe touches only the confirmed one', () async {
    final held = Completer<void>();
    account.script.add(held);
    final deleting = service.deleteAccount(accountKey);
    await pumpEventQueue();
    expect(transitions.deleting, isTrue);
    await expectLater(
      transitions.signOut(keep: true),
      throwsA(isA<DeletionRefused>()),
    );
    await expectLater(
      transitions.continueAsGuest(),
      throwsA(isA<DeletionRefused>()),
    );
    expect((await registry.read()).activeKey, accountKey);
    held.complete();
    await deleting;
    expect(host.deleted, [accountKey]);
    expect(transitions.deleting, isFalse);
  });

  test(
    '#241 the note is recorded only once the removal is journaled, for '
    'the guest it switches to; a refused or unconfirmed one records none',
    () async {
      final notes = _Notes();
      AccountService withNotes() => AccountService(
        identity: FakeIdentity(),
        transitions: transitions,
        registry: registry,
        google: google,
        revoke: (_) async {},
        account: account,
        removedNote: notes,
      );
      // Refused before any journal (a crash there is the same: no note).
      await expectLater(
        withNotes().removeLocalData('guest-9'),
        throwsA(isA<DeletionRefused>()),
      );
      expect(notes.stored, isNull);
      account.script.add(_type(DioExceptionType.connectionError));
      await expectLater(
        withNotes().deleteAccount(accountKey),
        _kind(AccountDeletionKind.offline),
      );
      expect(notes.stored, isNull);
      await withNotes().deleteAccount(accountKey);
      final guest = (await registry.read()).activeKey;
      expect(notes.stored, (kind: AccountRemovedKind.account, guest: guest));
      // The new guest removes its own data: bound to the next guest.
      await withNotes().removeLocalData(guest);
      final next = (await registry.read()).activeKey;
      expect(next, isNot(guest));
      expect(notes.stored, (kind: AccountRemovedKind.local, guest: next));
    },
  );

  test('a removal is refused for a profile that is not active', () async {
    await expectLater(
      transitions.removeProfile('guest-9'),
      throwsA(isA<DeletionRefused>()),
    );
    await expectLater(
      service.deleteAccount('acct-other'),
      throwsA(isA<DeletionRefused>()),
    );
    expect(host.deleted, isEmpty);
    expect(account.calls, 0);
  });

  test(
    'a deletion is refused while another transition journal is open',
    () async {
      final snapshot = await registry.read();
      await registry.write(
        snapshot.copyWith(
          transition: AccountTransition(
            kind: TransitionKind.switchProfile,
            phase: TransitionPhase.preparing,
            fromKey: accountKey,
            target: snapshot.active,
          ),
        ),
      );
      await expectLater(
        service.deleteAccount(accountKey),
        throwsA(isA<DeletionRefused>()),
      );
      expect(account.calls, 0);
    },
  );

  test('a crash after 204 during the local removal is finished by '
      'recovery for that exact profile', () async {
    host.failDelete = StateError('crash while deleting files');
    await expectLater(
      service.deleteAccount(accountKey),
      _kind(AccountDeletionKind.localRemovalFailed),
    );
    expect((await registry.read()).deletion?.confirmed, isTrue);
    // Restart: a new lifecycle over the same registry.
    host.failDelete = null;
    transitions = newTransitions();
    await transitions.recover();
    final after = await registry.read();
    expect(host.deleted, [accountKey]);
    expect(after.deletion, isNull);
    expect(after.transition, isNull);
    expect(after.active.kind, ProfileKind.guest);
  });

  test('an unconfirmed attempt survives a restart; then a 401 lets the '
      'user remove the data here', () async {
    account.script.add(_type(DioExceptionType.unknown));
    await expectLater(
      service.deleteAccount(accountKey),
      _kind(AccountDeletionKind.uncertain),
    );
    transitions = newTransitions();
    service = newService(account);
    await transitions.recover();
    account.script.add(_status(401));
    await expectLater(
      service.deleteAccount(accountKey),
      _kind(AccountDeletionKind.sessionEnded),
    );
    await service.removeLocalData(accountKey);
    expect(host.deleted, [accountKey]);
    expect((await registry.read()).deletion, isNull);
  });

  // A35 fix round 1, finding 3: through the real auth interceptor and
  // session service.
  test('real auth stack: a lost 204, then a revoked session, ends in the '
      'explicit "remove data from this phone" choice', () async {
    final f = session.Fixture();
    await f.seed(registered: true);
    f.auth.rotate = (_) async => session.tokens(anonymous: false, suffix: '2');
    await f.service.startAfterFirstFrame();
    var deleteCalls = 0;
    final adapter = FakeHttpAdapter(
      respond: (request) {
        if (request.method == 'DELETE') {
          deleteCalls++;
          // First attempt: committed by the server, response lost.
          if (deleteCalls == 1) return timeout(request);
          // The old bearer is revoked now.
          return json(null, status: 401)(request);
        }
        return json(null)(request);
      },
    );
    final base = Uri.parse('https://api.example.test');
    final dio = createApiDio(baseUrl: base, adapter: adapter, interceptors: []);
    dio.interceptors
      ..add(
        AuthInterceptor(apiBaseUrl: base, dio: dio, session: () => f.service),
      )
      ..add(const RequestGuardInterceptor());
    addTearDown(() => dio.close(force: true));
    // B06 revoked the refresh token too.
    f.auth.rotate = (_) async =>
        throw const AuthFailure(AuthFailureKind.unauthorized);
    final real = newService(AccountClient(dio));
    await expectLater(
      real.deleteAccount(accountKey),
      _kind(AccountDeletionKind.uncertain),
    );
    await expectLater(
      real.deleteAccount(accountKey),
      _kind(AccountDeletionKind.sessionEnded),
    );
    // Another retry meets the expired session before sending: still the
    // same choice, never "couldn't confirm" forever.
    await expectLater(
      real.deleteAccount(accountKey),
      _kind(AccountDeletionKind.sessionEnded),
    );
    final c = ProviderContainer(
      overrides: [
        accountServiceProvider.overrideWithValue(real),
        profileRegistryProvider.overrideWithValue(registry),
      ],
    );
    addTearDown(c.dispose);
    c.listen(deleteAccountControllerProvider, (_, _) {});
    await pumpEventQueue();
    expect(c.read(deleteAccountControllerProvider), DeletePhase.uncertain);
    await c.read(deleteAccountControllerProvider.notifier).removeLocal();
    expect(host.deleted, [accountKey]);
    expect((await registry.read()).active.kind, ProfileKind.guest);
  });

  // A35 fix round 2: the same lifecycle instance recovers and signs in.
  test('a failed cleanup releases the in-flight marker: recovery and a new '
      'sign-in work on the same instance', () async {
    host.failDelete = StateError('crash while deleting files');
    await expectLater(
      service.deleteAccount(accountKey),
      _kind(AccountDeletionKind.localRemovalFailed),
    );
    expect(transitions.deleting, isFalse);
    host.failDelete = null;
    await transitions.recover();
    expect(host.deleted, [accountKey]);
    expect((await registry.read()).deletion, isNull);
    final flow = service.newFlow();
    expect(
      await flow.verifyEmail(await flow.startEmail(canaryEmail), '123456'),
      isNot(AccountOutcome.mergeBlocked),
    );
    expect((await registry.read()).active.kind, ProfileKind.registered);
  });

  group('DeleteAccountController (A35 D19):', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          accountServiceProvider.overrideWithValue(service),
          profileRegistryProvider.overrideWithValue(registry),
        ],
      );
      addTearDown(c.dispose);
      c.listen(deleteAccountControllerProvider, (_, _) {});
      return c;
    }

    test('offline, then a retry that completes and wipes', () async {
      final c = container();
      final controller = c.read(deleteAccountControllerProvider.notifier);
      account.script.add(_type(DioExceptionType.connectionError));
      await controller.delete(guest: false);
      expect(c.read(deleteAccountControllerProvider), DeletePhase.offline);
      await controller.delete(guest: false);
      expect((await registry.read()).active.kind, ProfileKind.guest);
    });

    test('the deletion finishes after the screen is gone', () async {
      final c = container();
      final held = Completer<void>();
      account.script.add(held);
      unawaited(
        c.read(deleteAccountControllerProvider.notifier).delete(guest: false),
      );
      await pumpEventQueue();
      c.dispose();
      held.complete();
      await pumpEventQueue();
      expect(host.deleted, [accountKey]);
      expect((await registry.read()).active.kind, ProfileKind.guest);
    });

    test('keep the account drops the unconfirmed record', () async {
      final c = container();
      final controller = c.read(deleteAccountControllerProvider.notifier);
      account.script.add(_status(503));
      await controller.delete(guest: false);
      expect(c.read(deleteAccountControllerProvider), DeletePhase.uncertain);
      await controller.keepAccount();
      expect((await registry.read()).deletion, isNull);
      expect(c.read(deleteAccountControllerProvider), DeletePhase.ready);
    });

    test('a guest removes only this phone (no server call)', () async {
      await transitions.signOut(keep: false);
      final c = container();
      await c
          .read(deleteAccountControllerProvider.notifier)
          .delete(guest: true);
      expect(account.calls, 0);
      expect((await registry.read()).active.kind, ProfileKind.guest);
      expect(host.deleted, hasLength(2));
    });
  });
}
