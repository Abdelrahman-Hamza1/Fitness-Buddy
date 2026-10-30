import 'dart:io';

import 'package:fb_mobile/core/account/open_profile_host.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('fb_host_');
    addTearDown(() => root.deleteSync(recursive: true));
  });

  DatabaseLocation locationOf(String key) => DatabaseLocation(
    profileKey: 'local',
    root: () async => root.path,
    temporary: () async => root.path,
    resolveProfileKey: () async => key,
  );

  test('AC-004 crash point: cleanup right after a switch, before the new '
      "profile's providers build, deletes the discarded profile even though "
      'the registered location still belongs to it', () async {
    // The discarded profile was open: its location resolved to its own key.
    final old = locationOf('local');
    expect(await old.resolvedProfileKey(), 'local');
    final dir = Directory('${root.path}/profiles/local')
      ..createSync(recursive: true);
    File('${dir.path}/user.db').writeAsStringSync('x');

    final handles = OpenProfileHandles()..location = old;
    final _ = handles.registerIdle(() async {});
    final selected = <String>[];
    final host = OpenProfileHost(
      handles: handles,
      select: selected.add,
      fallbackRoot: () => locationOf('local'),
      activeKey: () async => 'guest-2',
    );

    await host.activate('guest-2');
    expect(selected, ['guest-2']);
    expect(handles.idle, isNull, reason: 'the old applier is unregistered');
    // No provider rebuilt (no listeners): the stale location is still the
    // registered one, and cleanup must not ask it which profile is open.
    expect(identical(handles.location, old), isTrue);
    await host.deleteFiles('local');
    expect(dir.existsSync(), isFalse);
  });

  test(
    'AC-004 cleanup with no location ever built uses the fallback root',
    () async {
      final dir = Directory('${root.path}/profiles/acct-0123456789abcdef')
        ..createSync(recursive: true);
      final deleted = <String>[];
      final host = OpenProfileHost(
        handles: OpenProfileHandles(),
        select: (_) {},
        fallbackRoot: () => locationOf('local'),
        activeKey: () async => 'local',
        // A28a review fix 1: per-profile device state goes with the files.
        onDeleted: (key) async => deleted.add(key),
      );
      await host.deleteFiles('acct-0123456789abcdef');
      expect(dir.existsSync(), isFalse);
      expect(deleted, ['acct-0123456789abcdef']);
      await expectLater(host.deleteFiles('../escape'), throwsArgumentError);
    },
  );

  test("AC-004 defence in depth: the registry's current active profile is "
      'never deleted, whatever the location says', () async {
    final dir = Directory('${root.path}/profiles/guest-2')
      ..createSync(recursive: true);
    final host = OpenProfileHost(
      handles: OpenProfileHandles()..location = locationOf('local'),
      select: (_) {},
      fallbackRoot: () => locationOf('local'),
      activeKey: () async => 'guest-2',
    );
    await expectLater(host.deleteFiles('guest-2'), throwsStateError);
    expect(dir.existsSync(), isTrue);
  });

  test('AC-004 a disposed applier clears only its own registration', () {
    final handles = OpenProfileHandles();
    Future<void> oldIdle() async {}
    Future<void> newIdle() async {}
    final oldOwner = handles.registerIdle(oldIdle);
    final _ = handles.registerIdle(newIdle);
    handles.unregisterIdle(oldOwner);
    expect(handles.idle, same(newIdle));
  });
}
