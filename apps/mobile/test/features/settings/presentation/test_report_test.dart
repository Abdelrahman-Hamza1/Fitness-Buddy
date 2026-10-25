import 'dart:ui' show SemanticsAction;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';
import '../../today/presentation/support/today_support.dart';
import 'settings_support.dart';

/// About on [config]'s flavor, with a sender that counts its reports.
Future<(ProviderContainer, List<String>)> _openAbout(
  WidgetTester tester,
  AppConfig config, {
  required bool enabled,
}) async {
  final sent = <String>[];
  final container = await pumpAt(
    tester,
    phone: phoneOf(config),
    overrides: [
      aboutInfoProvider.overrideWith(
        (ref) async => AboutInfo(
          version: '0.1.0',
          build: '1',
          flavor: config.flavor,
          packVersion: null,
          activeCredits: null,
        ),
      ),
      testReportSenderProvider.overrideWithValue(
        TestReportSender(enabled: enabled, send: () async => sent.add('sent')),
      ),
    ],
  );
  showRoute(container, const AboutRoute());
  await tester.pumpAndSettle();
  return (container, sent);
}

Finder _version(AppConfig config) => find.textContaining('Version 0.1.0');

void main() {
  testWidgets('PR-11 About: a long press on the version line asks first; '
      'Send sends the test report and says so', (tester) async {
    final (container, sent) = await _openAbout(
      tester,
      prodConfig,
      enabled: true,
    );
    // A normal tap does nothing.
    await tester.tap(_version(prodConfig));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsNothing);

    await tester.longPress(_version(prodConfig));
    await tester.pumpAndSettle();
    expect(find.text('Send a test error report?'), findsOneWidget);
    expect(sent, isEmpty);
    expect(find.textContaining('app and device information'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(sent, ['sent']);
    expect(find.text('Test report queued'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('PR-11 About version exposes a full-width semantic long press', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final (container, _) = await _openAbout(tester, prodConfig, enabled: true);
    expect(
      tester
          .getSemantics(_version(prodConfig))
          .getSemanticsData()
          .hasAction(SemanticsAction.longPress),
      isTrue,
    );
    final y = tester.getCenter(_version(prodConfig)).dy;
    await tester.longPressAt(Offset(300, y));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsOneWidget);
    await unmountApp(tester, container);
    semantics.dispose();
  });
  testWidgets('PR-11 About: Cancel on the confirm sheet sends nothing', (
    tester,
  ) async {
    final (container, sent) = await _openAbout(
      tester,
      prodConfig,
      enabled: true,
    );
    await tester.longPress(_version(prodConfig));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsNothing);
    expect(sent, isEmpty);
    expect(find.text('Test report queued'), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('PR-11 About: without a crash-report address the dev build says '
      'reports are off and asks nothing', (tester) async {
    final (container, sent) = await _openAbout(
      tester,
      devConfig,
      enabled: false,
    );
    await tester.longPress(_version(devConfig));
    await tester.pumpAndSettle();
    expect(find.byType(FbSheet), findsNothing);
    expect(sent, isEmpty);
    expect(
      find.text('Crash reports are off in dev builds, so nothing was sent.'),
      findsOneWidget,
    );
    await unmountApp(tester, container);
  });

  testWidgets('PR-11 About: a prod build with no address says it is not set '
      'up', (tester) async {
    final (container, sent) = await _openAbout(
      tester,
      prodConfig,
      enabled: false,
    );
    await tester.longPress(_version(prodConfig));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
    expect(
      find.text(
        "Crash reports aren't set up in this build, so nothing was sent.",
      ),
      findsOneWidget,
    );
    await unmountApp(tester, container);
  });

  test('PR-11 TestReportSender is inert when disabled and sends once when '
      'enabled', () async {
    var calls = 0;
    final off = TestReportSender(enabled: false, send: () async => calls++);
    expect(await off.sendReport(), TestReportOutcome.unavailable);
    expect(calls, 0);
    final on = TestReportSender(enabled: true, send: () async => calls++);
    expect(await on.sendReport(), TestReportOutcome.sent);
    expect(calls, 1);
  });
}
