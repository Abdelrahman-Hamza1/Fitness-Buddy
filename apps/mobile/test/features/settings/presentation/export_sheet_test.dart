import 'dart:async';
import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/export/export_providers.dart';
import 'package:fb_mobile/core/export/export_registry.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/core/export/export_sharer.dart';
import 'package:fb_mobile/core/export/export_snapshot.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';
import '../../today/presentation/support/today_support.dart';
import 'settings_support.dart';

final class _Sharer implements ExportSharer {
  ExportShareResult result = ExportShareResult.shared;
  bool fail = false;
  List<File> files = [];

  @override
  Future<ExportShareResult> share(List<File> files) async {
    if (fail) throw const FileSystemException('canary');
    this.files = files;
    return result;
  }
}

void main() {
  testWidgets('AC-030 UX-052 Export builds the files and shares them through '
      'the sharer; a share failure shows the banner, then Try again '
      'succeeds', (tester) async {
    final root = Directory.systemTemp.createTempSync('fb_export_sheet');
    addTearDown(() => root.deleteSync(recursive: true));
    final sharer = _Sharer();
    final service = DataExportService(
      readSnapshot: ({required settingNames}) async => ExportSnapshot(
        schemaVersion: 4,
        rows: {for (final spec in exportRegistryV1) spec.entity: []},
      ),
      temporaryDirectory: () async => root,
      sharer: sharer,
      now: () => DateTime(2026, 10, 24),
      appInfo: () async => (version: '0.1.0', build: '1'),
    );
    final container = await pumpAt(
      tester,
      phone: phoneOf(prodConfig),
      overrides: [
        dataExportServiceProvider.overrideWithValue(service),
        ...fakeSettings(),
      ],
    );
    await openMe(tester);
    await tester.tap(find.widgetWithText(FbListRow, 'Export your data'));
    await tester.pumpAndSettle();

    // The files are written on the real event loop, off a fake-async test.
    Future<void> exportAndWait(String bannerText) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      await tester.pump();
      // Up to 20 s of real time: the encoding isolate and the file writes
      // grow with the export tables (A36 added several) and a loaded runner.
      for (
        var i = 0;
        i < 400 && find.text(bannerText).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
    }

    sharer.fail = true;
    await exportAndWait("Couldn't create the export. Try again.");
    expect(find.text("Couldn't create the export. Try again."), findsOneWidget);
    expect(find.textContaining('canary'), findsNothing);

    sharer.fail = false;
    await tester.tap(find.widgetWithText(TextButton, 'Try again'));
    await tester.pump();
    for (
      var i = 0;
      i < 400 &&
          find.textContaining('Handed to the share sheet:').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pump();
    expect(sharer.files, hasLength(exportRegistryV1.length + 1));
    expect(
      find.text(
        'Handed to the share sheet: 0 entries in '
        '${exportRegistryV1.length + 1} files.',
      ),
      findsOneWidget,
    );
    await unmountApp(tester, container);
  });

  testWidgets(
    'AC-030 close and reopen during preparation skips sharing; retry succeeds',
    (tester) async {
      final gate = Completer<void>();
      final root = Directory.systemTemp.createTempSync('fb_export_sheet');
      addTearDown(() => root.deleteSync(recursive: true));
      final sharer = _Sharer();
      final service = DataExportService(
        readSnapshot: ({required settingNames}) async {
          await gate.future;
          return ExportSnapshot(
            schemaVersion: 4,
            rows: {
              for (final spec in exportRegistryV1) spec.entity: [],
              'setting': [
                {
                  'id': 'test-setting',
                  'value_json': 'true',
                  'created_at': 1,
                  'edited_by_user': true,
                  'version': 1,
                  'origin': 'direct',
                },
              ],
            },
          );
        },
        temporaryDirectory: () async => root,
        sharer: sharer,
        now: () => DateTime(2026, 10, 24),
        appInfo: () async => (version: '0.1.0', build: '1'),
      );
      final container = await pumpAt(
        tester,
        phone: phoneOf(prodConfig),
        overrides: [
          dataExportServiceProvider.overrideWithValue(service),
          ...fakeSettings(),
        ],
      );
      await openMe(tester);
      await tester.tap(find.widgetWithText(FbListRow, 'Export your data'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(FbSheet), findsNothing);
      await tester.tap(find.widgetWithText(FbListRow, 'Export your data'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      await tester.pump();
      expect(
        find.text('Sharing was cancelled. Nothing was sent.'),
        findsNothing,
      );
      gate.complete();
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (!Directory('${root.path}/export').existsSync()) break;
      }
      expect(tester.takeException(), isNull);
      expect(sharer.files, isEmpty);
      expect(Directory('${root.path}/export').existsSync(), isFalse);
      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      for (
        var i = 0;
        i < 300 &&
            find
                .textContaining('Handed to the share sheet:')
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (container.read(dataExportControllerProvider) is ExportIdle) {
          await tester.tap(find.widgetWithText(FilledButton, 'Export'));
          await tester.pump();
        }
      }
      final finalState = container.read(dataExportControllerProvider);
      expect(
        sharer.files,
        hasLength(exportRegistryV1.length + 1),
        reason: finalState is ExportFailed
            ? finalState.kind.name
            : finalState.runtimeType.toString(),
      );
      await unmountApp(tester, container);
    },
  );
}
