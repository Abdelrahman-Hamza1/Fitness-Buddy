import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/diary/support/diary_fixtures.dart';
import '../../helpers/fake_http.dart';
import '../db/support/db_support.dart';
import 'catalog_pack_updater_test.dart' show packBytes;

/// A24 exit criteria 2–3 on the host: the real generated client over a fake
/// HTTP transport serving real pack bytes, the real installer directory and
/// the real ATTACH. The laptop-server run is an owner/A55 check (card).
void main() {
  late Directory root;
  late CatalogPackInstaller installer;
  late AppDatabase db;
  late FakeHttpAdapter adapter;
  late CatalogPackUpdater updater;

  FakeResponder serve(List<int> bytes, {String? sha, int version = 7}) =>
      (request) {
        if (request.path == '/v1/catalog/packs/latest') {
          return json({
            'version': version,
            'url': '/v1/catalog/packs/$version',
            'sha256': sha ?? sha256.convert(bytes).toString(),
            'sizeBytes': bytes.length,
            'schemaVersion': supportedPackSchema,
          })(request);
        }
        if (request.path == '/v1/catalog/packs/$version') {
          return ResponseBody.fromBytes(
            bytes,
            200,
            headers: {
              Headers.contentTypeHeader: ['application/octet-stream'],
            },
          );
        }
        return offline(request);
      };

  setUp(() async {
    root = tempDir();
    File('${root.path}/catalog/catalog-6.db')
      ..createSync(recursive: true)
      ..writeAsBytesSync(packBytes(version: 6));
    installer = CatalogPackInstaller(
      root: () async => root.path,
      loadAsset: (_) => throw StateError('unused'),
    );
    db = fileDatabase('${root.path}/user.db', catalog: installer);
    await insertEntries(db, [
      entryRow(1, date: '2026-10-17', slotId: 'a'),
      entryRow(2, date: '2026-10-17', slotId: 'a'),
    ]);
    adapter = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    updater = CatalogPackUpdater(
      installer: installer,
      client: FbApi(dio).catalog,
      reattach: db.reattachCatalog,
    );
  });

  Future<int?> attachedVersion() => OfflineCatalog(db).packVersion();
  Future<int> entries() async =>
      (await db.select(db.diaryEntries).get()).length;

  test('FD-023 downloads, verifies, swaps and attaches a newer pack; diary '
      'entries are unaffected', () async {
    expect(await attachedVersion(), 6);
    adapter.respond = serve(packBytes());
    expect(await updater.checkForUpdate(), CatalogUpdate.installed);
    expect(await attachedVersion(), 7);
    expect(await installer.currentPackPath(), endsWith('catalog-7.db'));
    expect(File('${root.path}/catalog/catalog-6.db').existsSync(), isFalse);
    expect(await entries(), 2);
    expect(adapter.requests.map((r) => r.path), [
      '/v1/catalog/packs/latest',
      '/v1/catalog/packs/7',
    ]);
  });
}
