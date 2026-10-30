import 'dart:io';

import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/db_support.dart';

void main() {
  test('database location: one file per profile key', () async {
    final root = tempDir().path;
    final local = CountingLocation(root).location;
    final guest = CountingLocation(root, profileKey: 'guest-1').location;
    expect(await local.userDatabasePath(), '$root/profiles/local/user.db');
    expect(await guest.userDatabasePath(), '$root/profiles/guest-1/user.db');
  });

  test("AC-003 the database opens the registry's active profile lazily, "
      'and rejects a bad resolved key', () async {
    var reads = 0;
    final location = DatabaseLocation(
      profileKey: 'local',
      root: () async => '/root',
      temporary: () async => '/tmp',
      resolveProfileKey: () async {
        reads++;
        return 'acct-0123456789abcdef';
      },
    );
    expect(reads, 0, reason: 'building a location touches no storage');
    expect(
      await location.userDatabasePath(),
      '/root/profiles/acct-0123456789abcdef/user.db',
    );
    final bad = DatabaseLocation(
      profileKey: 'local',
      root: () async => '/root',
      temporary: () async => '/tmp',
      resolveProfileKey: () async => '../escape',
    );
    await expectLater(bad.userDatabasePath(), throwsArgumentError);
  });

  test('AC-003 the first resolved profile key sticks: later resolutions '
      'reuse it and no future is cached', () async {
    var reads = 0;
    final location = DatabaseLocation(
      profileKey: 'local',
      root: () async => '/root',
      temporary: () async => '/tmp',
      resolveProfileKey: () async => ++reads == 1 ? 'guest-2' : 'acct-x',
    );
    expect(await location.resolvedProfileKey(), 'guest-2');
    expect(await location.resolvedProfileKey(), 'guest-2');
    expect(await location.userDatabasePath(), '/root/profiles/guest-2/user.db');
    expect(reads, 1);
  });

  test('profile keys that are not plain directory names are rejected', () {
    for (final bad in ['', '../x', 'a/b', 'Local', 'a' * 65]) {
      expect(
        () => DatabaseLocation(
          profileKey: bad,
          root: () async => '/',
          temporary: () async => '/',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => '$e',
            'text',
            bad.isEmpty ? anything : isNot(contains(bad)),
          ),
        ),
        reason: bad,
      );
    }
  });

  test('UX-001 open runs no query until first use', () async {
    final root = tempDir().path;
    final counting = CountingLocation(root);
    final db = AppDatabase(openUserDatabase(counting.location));
    addTearDown(db.close);
    await pumpEventQueue();
    expect(counting.resolved, 0);
    expect(Directory('$root/profiles').existsSync(), isFalse);

    await db.select(db.settingsKv).get();
    expect(counting.resolved, 1);
    expect(File('$root/profiles/local/user.db').existsSync(), isTrue);
  });

  test('the connection runs WAL, synchronous NORMAL, busy_timeout 5000 '
      'and trusted_schema OFF in the background isolate', () async {
    final db = backgroundDatabase(tempDir().path);
    // The write guard takes any PRAGMA for a write: read them as tables.
    Future<Object?> pragma(String name) async =>
        (await db.customSelect('SELECT * FROM pragma_$name').getSingle())
            .data
            .values
            .single;
    expect(await pragma('journal_mode'), 'wal');
    expect(await pragma('synchronous'), 1);
    expect(await pragma('busy_timeout'), 5000);
    expect(await pragma('trusted_schema'), 0);
  });

  test('appDatabaseProvider is synchronous and touches no storage', () async {
    final counting = CountingLocation(tempDir().path);
    final container = ProviderContainer(
      overrides: [
        databaseLocationProvider.overrideWithValue(counting.location),
      ],
    );
    final db = container.read(appDatabaseProvider);
    await pumpEventQueue();
    expect(counting.resolved, 0);
    expect(container.read(profileKeyProvider), isNull);

    await db.select(db.syncState).get();
    expect(counting.resolved, 1);
    container.dispose();
  });
}
