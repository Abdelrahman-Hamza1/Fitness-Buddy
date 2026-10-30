import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/design_preview/design_preview.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

/// A phone-sized screen, so nothing is laid out for the 800 x 600 default.
void _phoneSize(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = const Size(360 * 3, 800 * 3);
  addTearDown(tester.view.reset);
}

TestPhone _phone(AppFlavor flavor) => TestPhone(
  config: AppConfig(
    flavor: flavor,
    apiBaseUrl: Uri.parse('https://api.example.test'),
    sentryDsn: '',
  ),
);

Finder _meTab() =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text('Me'));

void main() {
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  testWidgets("the design preview row and route don't exist in staging and "
      'prod', (tester) async {
    _phoneSize(tester);
    for (final flavor in [AppFlavor.staging, AppFlavor.prod]) {
      final container = await pumpApp(tester, phone: _phone(flavor));
      await tester.tap(_meTab());
      await tester.pumpAndSettle();
      expect(find.byType(MeScreen), findsOneWidget, reason: flavor.name);
      expect(find.text('Design preview'), findsNothing, reason: flavor.name);

      // The location is unknown, so it goes to Today.
      container.read(appRouterProvider).config.go(DesignPreviewRoute.path);
      await tester.pumpAndSettle();
      expect(find.byType(DesignPreviewScreen), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget, reason: flavor.name);
      // Leaves this app's providers before the next one starts.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    }
  });
}
