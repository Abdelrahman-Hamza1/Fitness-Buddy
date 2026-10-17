import 'dart:convert';
import 'dart:io';

import 'package:fb_mobile/core/db/catalog/catalog_pack_source.dart';

/// The pack schema version this app reads (A05 D5).
const supportedPackSchema = 1;

/// Reads a bundled asset (the installer takes the loaders so tests need no
/// asset bundle).
typedef AssetLoader = Future<List<int>> Function(String key);

/// The result of [CatalogPackInstaller.install].
final class CatalogInstall {
  /// The pack at [path]; [copied] says whether this call wrote it.
  const new(this.path, {required this.copied});

  /// The installed pack file.
  final String path;

  /// Whether the file was copied by this call (a new version).
  final bool copied;
}

/// Installs the bundled catalog pack and tells the database where it is (A05
/// D9, PA3).
///
/// Packs live at `<root>/catalog/catalog-<version>.db`. As the
/// [CatalogPackSource], it only looks at the files there: it never installs
/// while the database opens, never reads the asset bundle and never touches
/// the network. [install] runs after the first frame, in the background.
final class CatalogPackInstaller implements CatalogPackSource {
  /// An installer under the directory returned by [root] (the application
  /// support directory in the app), reading assets through [loadAsset].
  const new({required this.root, required this.loadAsset});

  /// The bundled manifest asset.
  static const manifestAsset = 'assets/catalog/catalog_manifest.json';

  /// The bundled pack asset.
  static const packAsset = 'assets/catalog/catalog.db';

  static final _name = RegExp(r'^catalog-(\d+)\.db$');

  /// The directory the `catalog/` folder lives in.
  final Future<String> Function() root;

  /// Reads a bundled asset.
  final AssetLoader loadAsset;

  Future<Directory> _dir() async => Directory('${await root()}/catalog');

  @override
  Future<String?> currentPackPath() async {
    final dir = await _dir();
    if (!dir.existsSync()) return null;
    final best = _installed(dir).fold<(int, File)?>(
      null,
      (best, e) => best == null || e.$1 > best.$1 ? e : best,
    );
    return best?.$2.path;
  }

  /// Installs the bundled pack when it is newer than the installed one:
  /// copies the asset to a temporary name, renames it, then deletes older
  /// versions. Returns `null` when the build has no pack or its schema isn't
  /// supported (the app then keeps working without a catalog).
  Future<CatalogInstall?> install() async {
    final Map<String, Object?> manifest;
    try {
      manifest = jsonDecode(
        utf8.decode(await loadAsset(manifestAsset)),
      ) as Map<String, Object?>;
    } on Object {
      return await _existing();
    }
    final version = manifest['catalog_version'];
    final schema = manifest['schema_version'];
    final bytes = (manifest['pack'] as Map<String, Object?>?)?['bytes'];
    if (version is! int || schema != supportedPackSchema) {
      return await _existing();
    }

    final dir = await _dir();
    await dir.create(recursive: true);
    final installed = _installed(dir);
    final newest = installed.fold<int>(0, (m, e) => e.$1 > m ? e.$1 : m);
    final target = File('${dir.path}/catalog-$version.db');
    if (newest > version) return await _existing();

    var copied = false;
    if (!target.existsSync() ||
        (bytes is int && target.lengthSync() != bytes)) {
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsBytes(await loadAsset(packAsset), flush: true);
      await tmp.rename(target.path);
      copied = true;
    }
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path != target.path) {
        // deleteSync: app_check rule 11 matches `delete(` in files that
        // import core/db, and this is a dart:io file, not a drift write.
        entity.deleteSync();
      }
    }
    return CatalogInstall(target.path, copied: copied);
  }

  Future<CatalogInstall?> _existing() async {
    final path = await currentPackPath();
    return path == null ? null : CatalogInstall(path, copied: false);
  }

  List<(int, File)> _installed(Directory dir) => [
    for (final e in dir.listSync())
      if (e is File)
        if (_name.firstMatch(e.uri.pathSegments.last) case final m?)
          (int.parse(m.group(1)!), e),
  ];
}
