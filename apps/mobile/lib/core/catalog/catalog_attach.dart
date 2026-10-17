import 'package:fb_mobile/core/catalog/catalog_pack_installer.dart';
import 'package:fb_mobile/core/db/app_database.dart';

/// Installs the bundled pack and attaches it to [db] (A05 D9). Run after the
/// first frame, never while the database opens.
///
/// Attaches when the pack was just installed or nothing is attached yet. A
/// pack that can't be installed or attached is handed to [onError] (the
/// error only, no paths) and the app goes on without a catalog.
Future<void> installAndAttachCatalog(
  CatalogPackInstaller installer,
  AppDatabase db, {
  void Function(Object error, StackTrace stack)? onError,
}) async {
  try {
    final install = await installer.install();
    if (install == null) return;
    if (install.copied || !await db.isCatalogAttached()) {
      await db.reattachCatalog(install.path);
    }
  } on Object catch (error, stack) {
    onError?.call(error, stack);
  }
}
