import 'dart:async';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_clock.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';

final class FakeClock implements SessionClock {
  @override
  DateTime wallNow = DateTime.utc(2026, 10, 23);
  @override
  Duration elapsed = Duration.zero;

  void advance(Duration duration) => elapsed += duration;
}

AuthTokens tokens({
  String id = 'synthetic-guest',
  bool anonymous = true,
  String suffix = '1',
  DateTime? expires,
}) => AuthTokens(
  userId: id,
  isAnonymous: anonymous,
  accessToken: 'synthetic-access-$suffix',
  refreshToken: 'synthetic-refresh-$suffix',
  expiresAt: expires ?? DateTime.utc(2026, 10, 23, 0, 15),
  refreshExpiresAt: DateTime.utc(2026, 11, 23),
);

final class FakeAuth implements AuthTransport {
  int creates = 0;
  int refreshes = 0;
  final consumed = <String>[];
  Future<AuthTokens> Function()? create;
  Future<AuthTokens> Function(String)? rotate;

  @override
  Future<AuthTokens> createAnonymous() async {
    creates++;
    return create == null ? tokens() : await create!();
  }

  @override
  Future<AuthTokens> refresh(String value) async {
    refreshes++;
    consumed.add(value);
    return rotate == null ? tokens(suffix: '2') : await rotate!(value);
  }
}

final class MemorySecrets implements SessionSecretStorage {
  final values = <String, String>{};
  int reads = 0;
  int writes = 0;
  int deletes = 0;
  bool failRead = false;
  String? failReadKey;

  @override
  Future<String?> read(String key) async {
    reads++;
    if (failRead || key == failReadKey) {
      throw StateError('synthetic-content-canary');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletes++;
    values.remove(key);
  }
}

final class MemoryBarrier implements SessionStorageDurability {
  int commits = 0;
  int? failAt;
  Completer<void>? hold;

  @override
  Future<void> commit() async {
    commits++;
    await hold?.future;
    if (commits == failAt) throw StateError('synthetic-content-canary');
  }
}

final class Fixture {
  final clock = FakeClock();
  final auth = FakeAuth();
  final secrets = MemorySecrets();
  final barrier = MemoryBarrier();
  final states = <SessionState>[];
  late final SecureSessionStore store = newStore();
  late final SessionService service = newService();

  SecureSessionStore newStore() => SecureSessionStore(
    flavor: 'dev',
    origin: Uri.parse('https://api.example.test'),
    storage: secrets,
    durability: barrier,
  );

  SessionService newService({SecureSessionStore? storage}) => SessionService(
    store: storage ?? store,
    transport: auth,
    clock: clock,
    onState: states.add,
  );

  Future<void> seed({bool registered = false, bool pending = false}) async {
    final pair = tokens(anonymous: !registered);
    await store.save(
      SessionEnvelope(
        userId: pair.userId,
        kind: registered ? SessionKind.registered : SessionKind.anonymous,
        rotationPending: pending,
        credentials: SessionCredentials(
          accessToken: pair.accessToken,
          refreshToken: pair.refreshToken,
          expiresAt: pair.expiresAt,
          refreshExpiresAt: pair.refreshExpiresAt,
        ),
      ),
    );
  }
}
