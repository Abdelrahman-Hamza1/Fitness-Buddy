import 'dart:async';
import 'dart:io';

import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/export/export_cache_sweeper.dart';
import 'package:fb_mobile/core/export/export_handoffs.dart';
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
  bool failAfterCopy = false;
  List<File> files = [];
  final copies = <File>[];

  /// Runs as the sheet opens, before the platform has copied anything.
  Future<void> Function()? beforeCopy;
  @override
  Future<ExportShareResult> share(List<File> files) async {
    if (fail) throw const FileSystemException('private canary');
    this.files = files;
    await beforeCopy?.call();
    for (final file in files) {
      expect(await file.length(), greaterThan(0));
      final copy = File(
        '${file.parent.parent.path}/share_plus/${file.uri.pathSegments.last}',
      );
      await copy.parent.create(recursive: true);
      copies.add(await file.copy(copy.path));
    }
    if (failAfterCopy) throw const FileSystemException('private canary');
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
  test(
    'AC-030 overlapping preparation reports busy, never dismissed',
    () async {
      wait = Completer<void>();
      final first = service.export(settingNames: []);
      await Future<void>.delayed(Duration.zero);
      expect(await service.export(settingNames: []), isA<ExportBusy>());
      wait!.complete();
      expect(await first, isA<Shared>());
      expect(sharer.files, hasLength(exportRegistryV1.length + 1));
    },
  );
  test('AC-030 receiver reads shared copies after share returns', () async {
    expect(await service.export(settingNames: []), isA<Shared>());
    expect(sharer.files.every((f) => !f.existsSync()), isTrue);
    for (final copy in sharer.copies) {
      expect(await copy.readAsBytes(), isNotEmpty);
    }
  });
  test(
    'AC-030 next export sweeps only handoff copies older than 24 hours',
    () async {
      final cache = Directory('${root.path}/share_plus')..createSync();
      final date = DateTime(2026, 10, 24);
      final old = File('${cache.path}/old.csv')
        ..writeAsStringSync('private')
        ..setLastModifiedSync(date.subtract(const Duration(hours: 25)));
      final boundary = File('${cache.path}/boundary.csv')
        ..writeAsStringSync('private')
        ..setLastModifiedSync(date.subtract(const Duration(hours: 24)));
      final fresh = File('${cache.path}/fresh.csv')
        ..writeAsStringSync('private')
        ..setLastModifiedSync(date.subtract(const Duration(hours: 23)));
      final unrelated = File('${root.path}/keep.csv')
        ..writeAsStringSync('private')
        ..setLastModifiedSync(date.subtract(const Duration(days: 2)));
      expect(await service.export(settingNames: []), isA<Shared>());
      expect(old.existsSync(), isFalse);
      expect(boundary.existsSync(), isTrue);
      expect(fresh.existsSync(), isTrue);
      expect(unrelated.existsSync(), isTrue);
    },
  );
  test('AC-030 cache sweep is bounded and never follows links', () async {
    final cache = Directory('${root.path}/share_plus')..createSync();
    final outside = File('${root.path}/outside.csv')
      ..writeAsStringSync('private')
      ..setLastModifiedSync(DateTime(2020));
    Link('${cache.path}/link.csv').createSync(outside.path);
    Directory('${cache.path}/nested').createSync();
    final nested = File('${cache.path}/nested/keep.csv')
      ..writeAsStringSync('private')
      ..setLastModifiedSync(DateTime(2020));
    for (var i = 0; i < 260; i++) {
      File('${cache.path}/$i.csv')
        ..writeAsStringSync('private')
        ..setLastModifiedSync(DateTime(2020));
    }
    await ExportCacheSweeper(
      temporaryDirectory: () async => root,
      now: () => DateTime(2026),
    ).sweep();
    expect(cache.listSync().whereType<File>().length, greaterThanOrEqualTo(4));
    expect(outside.existsSync(), isTrue);
    expect(nested.existsSync(), isTrue);
    expect(Link('${cache.path}/link.csv').existsSync(), isTrue);
  });
  test('AC-030 cache sweep never throws storage or clock errors', () async {
    for (final sweeper in [
      ExportCacheSweeper(
        temporaryDirectory: () async => throw StateError('private canary'),
        now: DateTime.now,
      ),
      ExportCacheSweeper(
        temporaryDirectory: () async => root,
        now: () => throw StateError('private canary'),
      ),
      ExportCacheSweeper(
        temporaryDirectory: () async => root,
        now: DateTime.now,
      ),
    ]) {
      await expectLater(sweeper.sweep(), completes);
    }
    File('${root.path}/share_plus').writeAsStringSync('not a directory');
    await expectLater(
      ExportCacheSweeper(
        temporaryDirectory: () async => root,
        now: DateTime.now,
      ).sweep(),
      completes,
    );
  });
  testWidgets('AC-030 hung cache storage never blocks or throws', (
    tester,
  ) async {
    final storage = Completer<Directory>();
    var completed = false;
    final sweep = ExportCacheSweeper(
      temporaryDirectory: () => storage.future,
      now: DateTime.now,
    ).sweep().then((_) => completed = true);
    await tester.pump(const Duration(seconds: 3));
    expect(completed, isFalse, reason: 'the caller is never awaiting it');
    expect(tester.takeException(), isNull);
    storage.completeError(StateError('private canary'));
    await sweep;
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });
  group('AC-030 export copies go with their profile (audit 2026-11-07)', () {
    late ExportHandoffs handoffs;
    late int generation;
    late bool removed;
    late DataExportService scoped;
    setUp(() {
      removed = false;
      handoffs = ExportHandoffs(
        () async => File('${root.path}/support/export_handoffs.json'),
      );
      generation = 0;
      scoped = DataExportService(
        readSnapshot: ({required settingNames}) async {
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
        handoffs: handoffs,
        profileKey: () async => 'p1',
        generation: () => generation,
        profileRemoved: (_) async => removed,
      );
    });
    List<File> shareCache() {
      final dir = Directory('${root.path}/share_plus');
      return dir.existsSync() ? dir.listSync().whereType<File>().toList() : [];
    }

    test('removing the profile deletes its share copies at once', () async {
      final unrelated = File('${root.path}/share_plus/not-ours.csv')
        ..createSync(recursive: true)
        ..writeAsStringSync('keep');
      expect(await scoped.export(settingNames: []), isA<Shared>());
      expect(sharer.copies, hasLength(exportRegistryV1.length + 1));
      await handoffs.removeProfile('other');
      expect(sharer.copies.every((f) => f.existsSync()), isTrue);
      await handoffs.removeProfile('p1');
      expect(sharer.copies.any((f) => f.existsSync()), isFalse);
      expect(shareCache().map((f) => f.path), [unrelated.path]);
    });

    test('an export in flight when the profile goes writes nothing', () async {
      wait = Completer<void>();
      final running = scoped.export(settingNames: []);
      await Future<void>.delayed(Duration.zero);
      // The removal: a new generation, then the profile's cleanup.
      generation++;
      await handoffs.removeProfile('p1');
      wait!.complete();
      expect(await running, isA<ExportAbandoned>());
      expect(sharer.files, isEmpty);
      expect(shareCache(), isEmpty);
      expect(Directory('${root.path}/export').existsSync(), isFalse);
    });

    test('a removal before the platform copied still deletes them', () async {
      sharer.beforeCopy = () async {
        generation++;
        removed = true;
        await handoffs.removeProfile('p1');
      };
      expect(await scoped.export(settingNames: []), isA<ExportAbandoned>());
      expect(sharer.copies, isNotEmpty);
      expect(shareCache(), isEmpty);
    });

    test('a removal and then a failing share still deletes them', () async {
      sharer
        ..beforeCopy = () async {
          generation++;
          removed = true;
          await handoffs.removeProfile('p1');
        }
        ..failAfterCopy = true;
      expect(await scoped.export(settingNames: []), isA<Failed>());
      expect(sharer.copies, isNotEmpty);
      expect(shareCache(), isEmpty);
    });

    test('a plain switch keeps the copies the recipient reads', () async {
      sharer.beforeCopy = () async => generation++;
      expect(await scoped.export(settingNames: []), isA<ExportAbandoned>());
      expect(sharer.copies.every((f) => f.existsSync()), isTrue);
    });

    test('an unreadable generation counts as stale', () async {
      sharer.beforeCopy = () async => generation = -1;
      final throwing = DataExportService(
        readSnapshot: ({required settingNames}) async => ExportSnapshot(
          schemaVersion: 4,
          rows: {for (final spec in exportRegistryV1) spec.entity: []},
        ),
        temporaryDirectory: () async => root,
        sharer: sharer,
        now: () => DateTime(2026, 10, 24),
        appInfo: () async => (version: '0.1.0', build: '1'),
        handoffs: handoffs,
        profileKey: () async => 'p1',
        generation: () =>
            generation < 0 ? throw StateError('disposed') : generation,
        profileRemoved: (_) async => throw StateError('disposed'),
      );
      expect(await throwing.export(settingNames: []), isA<ExportAbandoned>());
      expect(shareCache(), isEmpty);
    });
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
    expect((done.outcome as Shared).fileCount, exportRegistryV1.length + 1);
    expect((done.outcome as Shared).rowCount, 0);
    expect(offlineClient.requests, isEmpty);
    expect(sharer.files, hasLength(exportRegistryV1.length + 1));
    expect(seenKeys, [
      ...AppSettings.all.map((k) => k.name),
      // A41a: the per-date fasting keys of every Ramadan in the table.
      ...AppSettings.fastingKeyNames,
      // A68: the per-week Buddy review keys.
      ...AppSettings.weeklyReviewKeyNames,
    ]);
  });
  test('export dir is wiped before each export', () async {
    final dir = Directory('${root.path}/export')..createSync();
    File('${dir.path}/old-sensitive.json').writeAsStringSync('canary');
    expect(await service.export(settingNames: []), isA<Shared>());
    expect(File('${dir.path}/old-sensitive.json').existsSync(), isFalse);
    dir.createSync();
    File('${dir.path}/stale.csv').writeAsStringSync('canary');
    sharer.result = ExportShareResult.dismissed;
    expect(await service.export(settingNames: []), isA<Dismissed>());
    expect(File('${dir.path}/stale.csv').existsSync(), isFalse);
    expect(dir.existsSync(), isFalse);
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
