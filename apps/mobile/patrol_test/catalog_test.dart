import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/connection.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

/// A05 WP5 on the device: the pack bundled in the APK installs under the app
/// directory, attaches read-only, and a basic is found by English, Arabic and
/// Arabizi. Dishes are drafts until the owner reviews them, so the proof uses
/// the rice basics (shipped without a skim).
void main() {
  patrolTest(
    'A05 the bundled pack installs, attaches, and finds rice by EN, AR and '
    'Arabizi',
    ($) async {
      final temp = await getTemporaryDirectory();
      final root = await temp.createTemp('fb_catalog');
      addTearDown(() => root.deleteSync(recursive: true));

      final installer = CatalogPackInstaller(
        root: () async => root.path,
        loadAsset: (key) async =>
            (await rootBundle.load(key)).buffer.asUint8List(),
      );
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        openUserDatabase(
          DatabaseLocation(
            profileKey: 'catalog-it',
            root: () async => root.path,
            temporary: () async => root.path,
          ),
        ),
        catalog: installer,
      );
      addTearDown(db.close);

      // First run: nothing installed, nothing attached; the app still works.
      expect(await installer.currentPackPath(), isNull);
      expect(await db.isCatalogAttached(), isFalse);

      await installAndAttachCatalog(installer, db);
      expect(await db.isCatalogAttached(), isTrue);

      final catalog = OfflineCatalog(db);
      expect(await catalog.packVersion(), isNotNull);
      for (final query in ['rice', 'رز', 'ruz']) {
        final found = await catalog.search(query);
        expect(
          found.map((f) => f.id),
          contains(startsWith('usda:rice')),
          reason: query,
        );
        expect(found.first.badge, isNotNull);
      }
      expect(await catalog.yieldFactors(), isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
