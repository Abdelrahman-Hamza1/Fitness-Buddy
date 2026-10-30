import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:fb_api_client/fb_api_client.dart' as api;
import 'package:fb_mobile/core/catalog/catalog_pack_installer.dart';
import 'package:fb_mobile/core/db/catalog/catalog_pack_validator.dart';

/// What one [CatalogPackUpdater.checkForUpdate] did.
enum CatalogUpdate {
  /// The installed pack is the latest (or newer).
  upToDate,

  /// The latest pack's schema isn't one this app reads.
  unsupported,

  /// The download didn't match the published size or SHA-256, or isn't a
  /// readable pack of the published version and schema.
  rejected,

  /// A newer pack was verified, swapped in and attached.
  installed,
}

/// Background offline pack update (FD-023, `07` §6, A24 D5).
///
/// `GET /v1/catalog/packs/latest` → download → verify size and SHA-256 →
/// write a temporary file → validate it as a pack (real SQLite: integrity,
/// tables, schema and catalog version) → rename it (atomic in one directory)
/// → reattach → delete older packs. Any failure leaves the current pack
/// attached: a partial or corrupt download never replaces it. Never runs on
/// the startup path (the bootstrap starts it after the first frame).
final class CatalogPackUpdater {
  /// An updater for the packs [installer] manages, reading the server through
  /// [client] and attaching through [reattach].
  const new({
    required this.installer,
    required this.client,
    required this.reattach,
  });

  /// Owns the pack directory and reports the installed pack.
  final CatalogPackInstaller installer;

  /// Generated catalog client.
  final api.CatalogClient client;

  /// Swaps the attached pack (`AppDatabase.reattachCatalog`).
  final Future<void> Function(String? path) reattach;

  static final _name = RegExp(r'catalog-(\d+)\.db$');

  /// Checks for, verifies and installs a newer pack. Network and server
  /// errors propagate to the caller (who ignores them); the pack directory
  /// is left as it was.
  Future<CatalogUpdate> checkForUpdate() async {
    final latest = await client.getLatestCatalogPack();
    if (latest.schemaVersion != supportedPackSchema) {
      return CatalogUpdate.unsupported;
    }
    final current = await installer.currentPackPath();
    final currentVersion = current == null
        ? 0
        : int.parse(_name.firstMatch(current)!.group(1)!);
    if (latest.version <= currentVersion) return CatalogUpdate.upToDate;

    final dir = Directory('${await installer.root()}/catalog');
    await dir.create(recursive: true);
    final target = File('${dir.path}/catalog-${latest.version}.db');
    final tmp = File('${target.path}.download');
    try {
      final bytes = await client.downloadCatalogPack(version: latest.version);
      if (bytes.length != latest.sizeBytes ||
          sha256.convert(bytes).toString() != latest.sha256.toLowerCase()) {
        return CatalogUpdate.rejected;
      }
      await tmp.writeAsBytes(bytes, flush: true);
      final path = tmp.path;
      final version = latest.version;
      // Off the UI isolate; captures only the path and version.
      final problem = await Isolate.run(
        () => validateCatalogPack(
          path,
          version: version,
          schema: supportedPackSchema,
        ),
      );
      if (problem != null) return CatalogUpdate.rejected;
      await tmp.rename(target.path);
    } finally {
      // deleteSync: see CatalogPackInstaller (app_check rule 11).
      if (tmp.existsSync()) tmp.deleteSync();
    }

    try {
      await reattach(target.path);
    } on Object {
      // The new pack can't be attached: put the previous one back.
      if (target.existsSync()) target.deleteSync();
      await reattach(current);
      rethrow;
    }
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path != target.path) entity.deleteSync();
    }
    return CatalogUpdate.installed;
  }
}
