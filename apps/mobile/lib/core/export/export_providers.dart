import 'dart:io';

import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/db/export_snapshot.dart';
import 'package:fb_mobile/core/export/export_cache_sweeper.dart';
import 'package:fb_mobile/core/export/export_handoffs.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/core/export/export_sharer.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_providers.g.dart';

/// Share boundary override for host tests.
@Riverpod(keepAlive: true)
ExportSharer exportSharer(Ref ref) => SharePlusExportSharer();

/// The share copies recorded per profile; the account layer deletes a
/// removed profile's copies through it. Construction does no I/O.
@Riverpod(keepAlive: true)
ExportHandoffs exportHandoffs(Ref ref) => ExportHandoffs(
  () async => File(
    '${(await getApplicationSupportDirectory()).path}/export_handoffs.json',
  ),
);

/// Keeps the operation alive through the share sheet, serializing exports.
@Riverpod(keepAlive: true)
DataExportService dataExportService(Ref ref) {
  final reader = ref.watch(exportSnapshotReaderProvider);
  final clock = ref.watch(clockProvider);
  final registry = ref.read(profileRegistryProvider);
  return DataExportService(
    readSnapshot: reader,
    temporaryDirectory: getTemporaryDirectory,
    sharer: ref.watch(exportSharerProvider),
    now: () => clock.nowUtc().toLocal(),
    appInfo: () async {
      final info = await ref.read(packageInfoProvider.future);
      return (version: info.version, build: info.buildNumber);
    },
    handoffs: ref.watch(exportHandoffsProvider),
    // The registry object, not the ref: this provider rebuilds on a profile
    // switch, and a disposed ref must not decide whether copies are kept.
    profileKey: () async => (await registry.read()).activeKey,
    generation: () => ref.read(profileGenerationProvider),
    profileRemoved: (key) async => !(await registry.read()).profiles.any(
      (profile) => profile.profileKey == key,
    ),
  );
}

/// Independent startup cleanup; does not instantiate the snapshot/database.
final exportCacheSweeperProvider = Provider<ExportCacheSweeper>((ref) {
  final clock = ref.watch(clockProvider);
  return ExportCacheSweeper(
    temporaryDirectory: getTemporaryDirectory,
    now: clock.nowUtc,
  );
});
