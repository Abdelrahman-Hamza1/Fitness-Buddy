import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fb_api_client/fb_api_client.dart' as api;
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/catalog_support.dart';

final class FakePackClient implements api.CatalogClient {
  new(this.latest, this.bytes);

  api.CatalogPack latest;
  List<int> bytes;
  final downloads = <int>[];

  @override
  Future<api.CatalogPack> getLatestCatalogPack() async => latest;

  @override
  Future<List<int>> downloadCatalogPack({required int version}) async {
    downloads.add(version);
    return bytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

api.CatalogPack packFor(
  List<int> bytes, {
  int version = 7,
  int schema = supportedPackSchema,
  String? sha,
  int? size,
}) => api.CatalogPack(
  version: version,
  url: '/v1/catalog/packs/$version',
  sha256: sha ?? sha256.convert(bytes).toString(),
  sizeBytes: size ?? bytes.length,
  schemaVersion: schema,
);

/// The bytes of a real fixture pack whose meta says [version] and [schema].
/// [extraSql] runs last (to damage the pack on purpose).
List<int> packBytes({
  int version = 7,
  int schema = supportedPackSchema,
  String extraSql = '',
}) {
  final dir = Directory.systemTemp.createTempSync('pack_src');
  try {
    final path = writeFixturePack(
      '${dir.path}/p.db',
      extraSql:
          "UPDATE meta SET value = '$version' WHERE key = 'catalog_version'; "
          "UPDATE meta SET value = '$schema' WHERE key = 'schema_version'; "
          '$extraSql',
    );
    return File(path).readAsBytesSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

/// A valid SQLite file without any catalog table.
List<int> foreignSqliteBytes() {
  final dir = Directory.systemTemp.createTempSync('pack_src');
  try {
    final path = '${dir.path}/x.db';
    sqlite3.open(path)
      ..execute('CREATE TABLE notes (a TEXT); INSERT INTO notes VALUES (1);')
      ..close();
    return File(path).readAsBytesSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main() {
  late Directory root;
  late CatalogPackInstaller installer;
  late List<String?> attached;
  late File current;

  setUp(() {
    root = Directory.systemTemp.createTempSync('pack_updater');
    addTearDown(() => root.deleteSync(recursive: true));
    installer = CatalogPackInstaller(
      root: () async => root.path,
      loadAsset: (_) => throw StateError('unused'),
    );
    current = File('${root.path}/catalog/catalog-6.db')
      ..createSync(recursive: true)
      ..writeAsBytesSync([6, 6, 6]);
    attached = [];
  });

  CatalogPackUpdater updater(
    FakePackClient client, {
    Future<void> Function(String? path)? reattach,
  }) => CatalogPackUpdater(
    installer: installer,
    client: client,
    reattach: reattach ?? (path) async => attached.add(path),
  );

  List<String> files() => [
    for (final f in Directory('${root.path}/catalog').listSync())
      f.uri.pathSegments.last,
  ]..sort();

  test(
    'FD-023 installs a newer verified pack, reattaches, drops the old',
    () async {
      final bytes = packBytes();
      final result = await updater(FakePackClient(packFor(bytes), bytes))
          .checkForUpdate();
      expect(result, CatalogUpdate.installed);
      expect(files(), ['catalog-7.db']);
      expect(
        File('${root.path}/catalog/catalog-7.db').readAsBytesSync(),
        bytes,
      );
      expect(attached, ['${root.path}/catalog/catalog-7.db']);
      expect(await installer.currentPackPath(), endsWith('catalog-7.db'));
    },
  );

  test(
    'FD-023 a corrupted download is rejected and the old pack stays',
    () async {
      final good = List<int>.filled(64, 1);
      final corrupt = [...good]..[10] = 2;
      final result = await updater(FakePackClient(packFor(good), corrupt))
          .checkForUpdate();
      expect(result, CatalogUpdate.rejected);
      expect(files(), ['catalog-6.db']);
      expect(current.readAsBytesSync(), [6, 6, 6]);
      expect(attached, isEmpty);
    },
  );

  test('FD-023 a valid SQLite file with the right hash but no catalog tables '
      'is rejected and the old pack stays', () async {
    final bytes = foreignSqliteBytes();
    final result = await updater(FakePackClient(packFor(bytes), bytes))
        .checkForUpdate();
    expect(result, CatalogUpdate.rejected);
    expect(files(), ['catalog-6.db']);
    expect(attached, isEmpty);
  });

  test('FD-023 a pack whose meta version differs from the manifest is '
      'rejected', () async {
    final bytes = packBytes(version: 1);
    final result = await updater(FakePackClient(packFor(bytes), bytes))
        .checkForUpdate();
    expect(result, CatalogUpdate.rejected);
    expect(files(), ['catalog-6.db']);
  });

  test('FD-023 a pack with every table but a missing column is rejected '
      'and the old pack stays', () async {
    final bytes = packBytes(
      extraSql: 'ALTER TABLE servings DROP COLUMN range_hi;',
    );
    final result = await updater(FakePackClient(packFor(bytes), bytes))
        .checkForUpdate();
    expect(result, CatalogUpdate.rejected);
    expect(files(), ['catalog-6.db']);
    expect(current.readAsBytesSync(), [6, 6, 6]);
    expect(attached, isEmpty);
  });

  test('FD-023 a pack whose meta schema is unsupported is rejected', () async {
    final bytes = packBytes(schema: 99);
    final result = await updater(FakePackClient(packFor(bytes), bytes))
        .checkForUpdate();
    expect(result, CatalogUpdate.rejected);
    expect(files(), ['catalog-6.db']);
  });

  test('FD-023 a truncated download is rejected', () async {
    final good = List<int>.filled(64, 1);
    final result = await updater(
      FakePackClient(packFor(good), good.sublist(0, 32)),
    ).checkForUpdate();
    expect(result, CatalogUpdate.rejected);
    expect(files(), ['catalog-6.db']);
  });

  test('FD-023 same or older version is a no-op without download', () async {
    for (final version in [5, 6]) {
      final client = FakePackClient(packFor([1], version: version), [1]);
      expect(await updater(client).checkForUpdate(), CatalogUpdate.upToDate);
      expect(client.downloads, isEmpty);
    }
    expect(files(), ['catalog-6.db']);
  });

  test('FD-023 an unsupported schema is skipped', () async {
    final client = FakePackClient(packFor([1], schema: 99), [1]);
    expect(await updater(client).checkForUpdate(), CatalogUpdate.unsupported);
    expect(client.downloads, isEmpty);
  });

  test(
    'FD-023 a pack that fails to attach restores the previous one',
    () async {
      final bytes = packBytes();
      final paths = <String?>[];
      final run = updater(
        FakePackClient(packFor(bytes), bytes),
        reattach: (path) async {
          paths.add(path);
          if (path != null && path.endsWith('catalog-7.db')) {
            throw StateError('not a database');
          }
        },
      ).checkForUpdate();
      await expectLater(run, throwsStateError);
      expect(paths.last, current.path);
      expect(files(), ['catalog-6.db']);
    },
  );

  test('FD-023 a failed download leaves no temporary file', () async {
    final client = _ThrowingDownload(packFor([1, 2, 3]));
    await expectLater(
      updater(client).checkForUpdate(),
      throwsA(isA<SocketException>()),
    );
    expect(files(), ['catalog-6.db']);
  });
}

final class _ThrowingDownload extends FakePackClient {
  new(api.CatalogPack latest) : super(latest, const []);

  @override
  Future<List<int>> downloadCatalogPack({required int version}) async =>
      throw const SocketException('offline');
}
