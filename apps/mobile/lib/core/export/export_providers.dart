import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/db/export_snapshot.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/core/export/export_sharer.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_providers.g.dart';

/// Share boundary override for host tests.
@riverpod
ExportSharer exportSharer(Ref ref) => SharePlusExportSharer();

/// Keeps the operation alive through the share sheet, serializing exports.
@Riverpod(keepAlive: true)
DataExportService dataExportService(Ref ref) {
  final reader = ref.watch(exportSnapshotReaderProvider);
  final clock = ref.watch(clockProvider);
  return DataExportService(
    readSnapshot: reader,
    temporaryDirectory: getTemporaryDirectory,
    sharer: ref.watch(exportSharerProvider),
    now: () => clock.nowUtc().toLocal(),
    appInfo: () async {
      final info = await ref.read(packageInfoProvider.future);
      return (version: info.version, build: info.buildNumber);
    },
  );
}
