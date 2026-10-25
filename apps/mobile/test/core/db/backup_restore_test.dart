import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/system.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../changes/support/test_db.dart';
import 'support/db_support.dart';

void main() {
  test(
    'AT-006 backup claims disclose historical install IDs and sync bookkeeping',
    () {
      final root = Directory.current.parent.parent;
      for (final path in [
        'apps/mobile/android/app/src/main/res/xml/data_extraction_rules.xml',
        'docs/runbooks/install-a-build.md',
        'docs/export-format.md',
      ]) {
        final text = File('${root.path}/$path').readAsStringSync();
        expect(text, contains('historical install IDs'), reason: path);
        expect(text, contains('sync bookkeeping'), reason: path);
      }
    },
  );

  test('AT-006 restored DB uses fresh active ID, advances HLC '
      'and preserves historical outbox', () async {
    final oldId = naturalId('setting', 'units.system');
    final newId = naturalId('setting', 'appearance.theme');
    final root = tempDir();
    final original = fileDatabase('${root.path}/old.db');
    await insertSetting(
      original,
      settingRow(oldId, wall: 2000000000000, valueJson: '"metric"'),
    );
    final oldHlc = hlcAt(2000000000000);
    await runAuthorizedWrite(
      () => original.customStatement(
        "INSERT INTO sync_state (key, value) VALUES ('hlc.last', ?)",
        [oldHlc],
      ),
    );
    final originalRow = await original.select(original.settingsKv).getSingle();
    final originalOutbox = await outbox(original);
    await original.close();
    await File('${root.path}/old.db').copy('${root.path}/restored.db');
    final restored = fileDatabase('${root.path}/restored.db');
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesAsync();
    final container = ProviderContainer.test(
      overrides: [
        appDatabaseProvider.overrideWithValue(restored),
        sharedPreferencesProvider.overrideWithValue(prefs),
        idGeneratorProvider.overrideWithValue(systemUuidV7Generator()),
        clockProvider.overrideWithValue(
          ManualClock(DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true)),
        ),
        changeOpHandlersProvider.overrideWithValue(
          (_) => const [ScriptHandler()],
        ),
      ],
    );
    final fresh = await container.read(deviceIdStoreProvider).deviceId();
    expect(fresh, isNot(testDevice));
    expect(await prefs.getString(PreferenceKeys.deviceId), fresh);
    expect(await outbox(restored), originalOutbox);
    final result = await container
        .read(changeSetApplierProvider)
        .apply(
          ChangeSet([
            ScriptOp.rows([
              UpsertRow(
                restored.settingsKv,
                SettingsKvCompanion(
                  id: Value(newId),
                  valueJson: const Value('true'),
                ),
              ),
            ]),
          ], origin: Origin.direct),
        );
    expect(result, isA<Applied>());
    final rows = await restored.select(restored.settingsKv).get();
    final historical = rows.singleWhere((r) => r.id == oldId);
    final added = rows.singleWhere((r) => r.id == newId);
    expect(historical, originalRow);
    expect(added.deviceId, fresh);
    expect(added.updatedHlc, endsWith(fresh));
    expect(added.updatedHlc.compareTo(oldHlc), greaterThan(0));
    final pending = await outbox(restored);
    expect(pending.take(originalOutbox.length), originalOutbox);
    expect(pending.last, ('setting', newId, added.updatedHlc, false));
    // Pending historical tuples retain the same row/HLC identity for A34 push.
    expect(pending.first.$3, oldHlc);
    final last = await restored
        .customSelect("SELECT value FROM sync_state WHERE key = 'hlc.last'")
        .getSingle();
    expect(last.read<String>('value'), added.updatedHlc);
    expect(await container.read(deviceIdStoreProvider).deviceId(), fresh);
  });
}
