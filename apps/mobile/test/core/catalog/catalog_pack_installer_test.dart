import 'dart:convert';
import 'dart:io';

import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../db/support/db_support.dart';
import 'support/catalog_support.dart';

List<int> _manifest(int version, {int schema = 1, int? bytes}) => utf8.encode(
  jsonEncode({
    'catalog_version': version,
    'schema_version': schema,
    'pack': {'bytes': ?bytes},
  }),
);

/// An installer whose "bundle" is [assets]; `reads` counts pack reads.
({CatalogPackInstaller installer, Directory root, List<String> reads}) _setup(
  Map<String, List<int>> Function() assets,
) {
  final root = tempDir();
  final reads = <String>[];
  final installer = CatalogPackInstaller(
    root: () async => root.path,
    loadAsset: (key) async {
      final bytes = assets()[key];
      if (bytes == null) throw StateError('no asset $key');
      if (key == CatalogPackInstaller.packAsset) reads.add(key);
      return bytes;
    },
  );
  return (installer: installer, root: root, reads: reads);
}

List<String> _files(Directory root) {
  final dir = Directory('${root.path}/catalog');
  if (!dir.existsSync()) return const [];
  return [for (final e in dir.listSync()) e.uri.pathSegments.last]..sort();
}

void main() {
  const pack = CatalogPackInstaller.packAsset;
  const manifest = CatalogPackInstaller.manifestAsset;

  test(
    'currentPackPath is null before an install and never installs',
    () async {
      final s = _setup(
        () => {
          manifest: _manifest(1),
          pack: [1, 2, 3],
        },
      );
      expect(await s.installer.currentPackPath(), isNull);
      expect(s.reads, isEmpty);
      expect(_files(s.root), isEmpty);
    },
  );

  test('installer copies once per version, atomically', () async {
    final s = _setup(
      () => {
        manifest: _manifest(1),
        pack: [1, 2, 3],
      },
    );
    final first = (await s.installer.install())!;
    expect(first.copied, isTrue);
    expect(first.path, '${s.root.path}/catalog/catalog-1.db');
    expect(File(first.path).readAsBytesSync(), [1, 2, 3]);
    expect(_files(s.root), ['catalog-1.db'], reason: 'no temp file left');
    expect(await s.installer.currentPackPath(), first.path);

    final again = (await s.installer.install())!;
    expect(again.copied, isFalse);
    expect(s.reads, hasLength(1));
  });

  test(
    'installer removes older versions and temp leftovers on upgrade',
    () async {
      var version = 1;
      final s = _setup(
        () => {
          manifest: _manifest(version),
          pack: [version],
        },
      );
      await s.installer.install();
      File('${s.root.path}/catalog/catalog-9.db.tmp').writeAsStringSync('half');
      version = 2;
      final upgraded = (await s.installer.install())!;
      expect(upgraded.copied, isTrue);
      expect(_files(s.root), ['catalog-2.db']);
      expect(await s.installer.currentPackPath(), upgraded.path);
    },
  );

  test('a truncated installed file is copied again', () async {
    final s = _setup(
      () => {
        manifest: _manifest(1, bytes: 3),
        pack: [1, 2, 3],
      },
    );
    await s.installer.install();
    File('${s.root.path}/catalog/catalog-1.db').writeAsBytesSync([1]);
    final repaired = (await s.installer.install())!;
    expect(repaired.copied, isTrue);
    expect(File(repaired.path).readAsBytesSync(), [1, 2, 3]);
  });

  test(
    'wrong schema_version → no pack, nothing copied, app keeps working',
    () async {
      final s = _setup(
        () => {
          manifest: _manifest(1, schema: 99),
          pack: [1, 2, 3],
        },
      );
      expect(await s.installer.install(), isNull);
      expect(_files(s.root), isEmpty);
      expect(s.reads, isEmpty);
    },
  );

  test(
    'a build without the asset installs nothing and keeps an old pack',
    () async {
      final s = _setup(() => {});
      expect(await s.installer.install(), isNull);

      Directory('${s.root.path}/catalog').createSync(recursive: true);
      File('${s.root.path}/catalog/catalog-3.db').writeAsStringSync('x');
      final kept = (await s.installer.install())!;
      expect(kept.copied, isFalse);
      expect(kept.path, endsWith('catalog-3.db'));
    },
  );

  test(
    'installAndAttachCatalog attaches a new pack, then a later upgrade',
    () async {
      final dir = tempDir().path;
      final packBytes = File(writeFixturePack('$dir/src.db')).readAsBytesSync();
      var version = 1;
      final installer = CatalogPackInstaller(
        root: () async => dir,
        loadAsset: (key) async => key == CatalogPackInstaller.manifestAsset
            ? _manifest(version)
            : packBytes,
      );
      final db = fileDatabase('$dir/user.db', catalog: installer);
      expect(await db.isCatalogAttached(), isFalse);

      await installAndAttachCatalog(installer, db);
      expect(await db.isCatalogAttached(), isTrue);
      expect(
        await OfflineCatalog(db).byId('usda:rice_white_long_grain_raw'),
        isNotNull,
      );

      version = 2;
      await installAndAttachCatalog(installer, db);
      expect(Directory('$dir/catalog').listSync().map((e) => e.path), [
        '$dir/catalog/catalog-2.db',
      ]);
      expect(
        await OfflineCatalog(db).byId('usda:rice_white_long_grain_raw'),
        isNotNull,
      );
    },
  );

  test('an attach failure is tolerated and reported', () async {
    final dir = tempDir().path;
    final installer = CatalogPackInstaller(
      root: () async => dir,
      loadAsset: (key) async => key == CatalogPackInstaller.manifestAsset
          ? _manifest(1)
          : utf8.encode('this is not a sqlite file at all, just text'),
    );
    final db = fileDatabase('$dir/user.db');
    final errors = <Object>[];
    await installAndAttachCatalog(
      installer,
      db,
      onError: (e, _) => errors.add(e),
    );
    expect(errors, hasLength(1));
    expect(await OfflineCatalog(db).search('rice'), isEmpty);
    // The user database still works.
    expect(await db.isCatalogAttached(), isFalse);
  });
}
