import 'dart:async';
import 'dart:io';

import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/export/export_providers.dart';
import 'package:fb_mobile/core/export/export_registry.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/core/export/export_sharer.dart';
import 'package:fb_mobile/core/export/export_snapshot.dart';
import 'package:fb_mobile/features/settings/application/app_settings.dart';
import 'package:fb_mobile/features/settings/application/data_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../db/support/db_support.dart';

final class _Sharer implements ExportSharer {
  ExportShareResult result = ExportShareResult.shared;
  bool fail = false;
  List<File> files = [];
  @override
  Future<ExportShareResult> share(List<File> files) async {
    if (fail) throw const FileSystemException('private canary');
    this.files = files;
    for (final file in files) {
      expect(await file.length(), greaterThan(0));
    }
    return result;
  }
}

void main() {
  late Directory root;
  late _Sharer sharer;
  late DataExportService service;
  var reads = 0;
  var seenKeys = <String>[];
  Completer<void>? wait;
  setUp(() {
    root = tempDir();
    sharer = _Sharer();
    reads = 0;
    seenKeys = [];
    wait = null;
    service = DataExportService(
      readSnapshot: ({required settingNames}) async {
        reads++;
        seenKeys = settingNames.toList();
        await wait?.future;
        return ExportSnapshot(
          schemaVersion: 4,
          rows: {for (final spec in exportRegistryV1) spec.entity: []},
        );
      },
      temporaryDirectory: () async => root,
      sharer: sharer,
      now: () => DateTime(2026, 10, 24),
      appInfo: () async => (version: '0.1.0', build: '1'),
    );
  });
  test('export works with no network', () async {
    final offlineClient = FakeHttpAdapter();
    final container = ProviderContainer(
      overrides: [
        dataExportServiceProvider.overrideWithValue(service),
        httpClientAdapterProvider.overrideWithValue(offlineClient),
        dioProvider.overrideWith(
          (ref) => throw StateError('Export requested HTTP'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(dataExportControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(dataExportControllerProvider.notifier).export();
    final done = container.read(dataExportControllerProvider) as ExportDone;
    expect((done.outcome as Shared).fileCount, 9);
    expect((done.outcome as Shared).rowCount, 0);
    expect(offlineClient.requests, isEmpty);
    expect(sharer.files, hasLength(9));
    expect(seenKeys, AppSettings.all.map((k) => k.name));
  });
  test('export dir is wiped before each export', () async {
    final dir = Directory('${root.path}/export')..createSync();
    File('${dir.path}/old-sensitive.json').writeAsStringSync('canary');
    expect(await service.export(settingNames: []), isA<Shared>());
    expect(File('${dir.path}/old-sensitive.json').existsSync(), isFalse);
    File('${dir.path}/stale.csv').writeAsStringSync('canary');
    sharer.result = ExportShareResult.dismissed;
    expect(await service.export(settingNames: []), isA<Dismissed>());
    expect(File('${dir.path}/stale.csv').existsSync(), isFalse);
    expect(dir.listSync(), hasLength(9));
  });
  test('DataExportController: working → done/failed; second tap ignored while working', () async {
    final container = ProviderContainer(
      overrides: [dataExportServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final states = <DataExportState>[];
    final sub = container.listen(
      dataExportControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(sub.close);
    final controller = container.read(dataExportControllerProvider.notifier);
    wait = Completer<void>();
    final first = controller.export();
    expect(container.read(dataExportControllerProvider), isA<ExportWorking>());
    await controller.export();
    wait!.complete();
    await first;
    expect(reads, 1);
    expect(states, [
      isA<ExportIdle>(),
      isA<ExportWorking>(),
      isA<ExportDone>(),
    ]);
    sharer.fail = true;
    await controller.export();
    final failure =
        container.read(dataExportControllerProvider) as ExportFailed;
    expect(failure.kind, ExportFailureKind.sharing);
    expect(failure.toString(), isNot(contains('canary')));
    sharer.fail = false;
    await controller.export();
    expect(container.read(dataExportControllerProvider), isA<ExportDone>());
  });
  test(
    'export failures expose only categories and release the in-flight guard',
    () async {
      final broken = DataExportService(
        readSnapshot: ({required settingNames}) async =>
            throw StateError('private canary'),
        temporaryDirectory: () async => root,
        sharer: sharer,
        now: () => DateTime(2026),
        appInfo: () async => (version: '1', build: '1'),
      );
      for (var i = 0; i < 2; i++) {
        final result = await broken.export(settingNames: []);
        expect((result as Failed).kind, ExportFailureKind.snapshot);
        expect(result.toString(), isNot(contains('canary')));
      }
    },
  );
}
