import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import '../db/support/db_support.dart';

/// The real bundled pack on the host (the Patrol test runs the same on the
/// device). Needs `make catalog-pack`; skipped when the pack isn't built.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A05 the bundled pack installs, attaches and finds rice by EN, AR and '
      'Arabizi', () async {
    try {
      await rootBundle.load(CatalogPackInstaller.packAsset);
    } on Object {
      markTestSkipped('run `make catalog-pack` first');
      return;
    }
    final root = tempDir().path;
    final installer = CatalogPackInstaller(
      root: () async => root,
      loadAsset: (key) async =>
          (await rootBundle.load(key)).buffer.asUint8List(),
    );
    final db = fileDatabase('$root/user.db', catalog: installer);
    await installAndAttachCatalog(installer, db);
    expect(await db.isCatalogAttached(), isTrue);

    final catalog = OfflineCatalog(db);
    for (final query in ['rice', 'رز', 'ruz']) {
      final ids = [for (final f in await catalog.search(query)) f.id];
      expect(ids, contains(startsWith('usda:rice')), reason: query);
    }
    expect(await catalog.yieldFactors(), isNotEmpty);
  });
}
