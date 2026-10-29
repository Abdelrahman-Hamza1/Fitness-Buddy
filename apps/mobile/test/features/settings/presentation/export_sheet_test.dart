import 'dart:async';
import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/export/export_providers.dart';
import 'package:fb_mobile/core/export/export_registry.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/core/export/export_sharer.dart';
import 'package:fb_mobile/core/export/export_snapshot.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';
import '../../today/presentation/support/today_support.dart';
import 'settings_support.dart';

/// A controller stuck in [initial], recording the taps it gets.
class _FixedController extends DataExportController {
  new(this.initial, this.taps);

  final DataExportState initial;
  final List<String> taps;

  @override
  DataExportState build() => initial;

  @override
  Future<void> export() async => taps.add('export');
}

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

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(FbSheet), matching: find.text(text));

/// The app on its Me tab, with the export controller fixed to [state].
Future<(ProviderContainer, List<String>)> _openFixed(
  WidgetTester tester,
  DataExportState state,
) async {
  final taps = <String>[];
  final container = await pumpAt(
    tester,
    phone: phoneOf(prodConfig),
    overrides: [
      dataExportControllerProvider.overrideWith(
        () => _FixedController(state, taps),
      ),
      ...fakeSettings(),
    ],
  );
  await openMe(tester);
  // At text scale 2.0 the row can sit below the fold (the You section, A13).
  final row = find.widgetWithText(FbListRow, 'Export your data');
  await tester.scrollUntilVisible(
    row,
    200,
    scrollable: find.descendant(
      of: find.byType(MeScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(row);
  await tester.pumpAndSettle();
  return (container, taps);
}

void main() {
  testWidgets('AC-030 UX-010 Me shows Your data between Settings and About; '
      'Export your data opens the export sheet', (tester) async {
    final container = await pumpAt(
      tester,
      phone: phoneOf(prodConfig),
      overrides: fakeSettings(),
    );
    await openMe(tester);
    double y(String header) =>
        tester.getTopLeft(find.widgetWithText(FbSectionHeader, header)).dy;
    expect(y('Settings'), lessThan(y('Your data')));
    expect(y('Your data'), lessThan(y('About')));
    expect(find.byType(FbSheet), findsNothing);

    await tester.tap(find.widgetWithText(FbListRow, 'Export your data'));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsOneWidget);
    expect(_inSheet('Export your data'), findsOneWidget);
    expect(
      find.textContaining('Fitness Buddy uploads nothing.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Deleted items and Buddy chats'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Nothing that identifies this phone'),
      findsOneWidget,
    );
    await unmountApp(tester, container);
  });

  testWidgets('AC-030 UX-052 export sheet idle: Export starts the export', (
    tester,
  ) async {
    final (container, taps) = await _openFixed(tester, const ExportIdle());
    expect(find.byType(FbInlineBanner), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pump();
    expect(taps, ['export']);
    await unmountApp(tester, container);
  });

  testWidgets('UX-051 export sheet preparing: a calm banner, the button is '
      'disabled', (tester) async {
    final (container, taps) = await _openFixed(tester, const ExportWorking());
    expect(find.text('Preparing your files…'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Export'),
    );
    expect(button.onPressed, isNull);
    expect(taps, isEmpty);
    await unmountApp(tester, container);
  });

  testWidgets('UX-052 export sheet failure: plain banner with Try again that '
      'repeats the export', (tester) async {
    final (container, taps) = await _openFixed(
      tester,
      const ExportFailed(ExportFailureKind.sharing),
    );
    expect(find.text("Couldn't create the export. Try again."), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Export'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Try again'));
    await tester.pump();
    expect(taps, ['export']);
    await unmountApp(tester, container);
  });

  testWidgets('AC-030 export sheet done: summary with counts, Done closes', (
    tester,
  ) async {
    final (container, _) = await _openFixed(
      tester,
      const ExportDone(Shared(fileCount: 9, rowCount: 1)),
    );
    expect(
      find.text('Handed to the share sheet: 1 entry in 9 files.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('AC-030 export sheet cancelled share: says nothing was sent '
      'and offers Export again', (tester) async {
    final (container, taps) = await _openFixed(
      tester,
      const ExportDone(Dismissed()),
    );
    expect(find.text('Sharing was cancelled. Nothing was sent.'), findsOne);
    await tester.tap(find.widgetWithText(FilledButton, 'Export again'));
    await tester.pump();
    expect(taps, ['export']);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsNothing);
    await unmountApp(tester, container);
  });

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
      for (
        var i = 0;
        i < 100 && find.text(bannerText).evaluate().isEmpty;
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
      i < 100 &&
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
    'UX-070 export sheet actions stay inside 320x640 viewport at 2.0',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (container, _) = await _openFixed(
        tester,
        const ExportFailed(ExportFailureKind.storage),
      );
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final viewport = tester.getRect(find.byType(FbSheet));
      for (final finder in [
        find.byType(FbInlineBanner),
        find.widgetWithText(TextButton, 'Try again'),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThanOrEqualTo(viewport.top));
        expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
        expect(rect.bottom, lessThanOrEqualTo(640));
      }
      await unmountApp(tester, container);
    },
  );

  for (final state in const <DataExportState>[
    ExportIdle(),
    ExportWorking(),
    ExportDone(Shared(fileCount: 9, rowCount: 20000)),
    ExportDone(Dismissed()),
  ]) {
    testWidgets('UX-070 export primary actions stay visible at 2.0: '
        '${state.runtimeType} '
        '${state is ExportDone ? state.outcome.runtimeType : ""}', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (container, _) = await _openFixed(tester, state);
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final viewport = tester.getRect(find.byType(FbSheet));
      for (final element
          in find
              .descendant(
                of: find.byType(FbSheet),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is FilledButton ||
                      w is TextButton ||
                      w is FbInlineBanner,
                ),
              )
              .evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.top, greaterThanOrEqualTo(viewport.top));
        expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
        expect(rect.bottom, lessThanOrEqualTo(640));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
      await unmountApp(tester, container);
    });
  }

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
