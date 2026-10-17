import 'package:fb_mobile/core/catalog/catalog_pack_installer.dart';
import 'package:fb_mobile/core/catalog/offline_catalog.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_providers.g.dart';

/// The installer of the bundled pack, under the application support
/// directory (`files/catalog/`, excluded from backups). The app scope makes
/// it the database's `catalogPackSource`.
@Riverpod(keepAlive: true)
CatalogPackInstaller catalogPackInstaller(Ref ref) => CatalogPackInstaller(
  root: () async => (await getApplicationSupportDirectory()).path,
  loadAsset: (key) async => (await rootBundle.load(key)).buffer.asUint8List(),
);

/// Reads the attached offline catalog.
@Riverpod(keepAlive: true)
OfflineCatalog offlineCatalog(Ref ref) => OfflineCatalog(
  ref.watch(appDatabaseProvider),
  onError: (error) => ref.read(errorReportingProvider).reportKind(error),
);
