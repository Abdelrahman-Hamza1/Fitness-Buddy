import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/design_preview/application/mockup_entry.dart';
import 'package:fb_mobile/features/design_preview/design_preview.dart';
import 'package:fb_mobile/features/design_preview/presentation/gallery/gallery_registry.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
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

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(TabBar), matching: find.text(label)),
  );
  // Not pumpAndSettle: skeletons in the gallery animate forever.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  testWidgets('UX-010 the design preview is reachable from Me in the dev '
      'flavor', (tester) async {
    _phoneSize(tester);
    final container = await pumpApp(tester);

    await tester.tap(_meTab());
    await tester.pumpAndSettle();
    expect(find.byType(MeScreen), findsOneWidget);
    // The Developer section is the last on the long Me list.
    await tester.scrollUntilVisible(
      find.text('Design preview'),
      200,
      scrollable: find.descendant(
        of: find.byType(MeScreen),
        matching: find.byType(Scrollable),
      ),
    );
    // Past the bottom bar that overlaps the end of the list.
    await tester.drag(
      find.descendant(
        of: find.byType(MeScreen),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design preview'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignPreviewScreen), findsOneWidget);
    expect(
      container.read(appRouterProvider).config.state.matchedLocation,
      DesignPreviewRoute.path,
    );
    // Nested in the Me tab: the tab bar stays.
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final tab in ['Mockups', 'Components', 'Tokens']) {
      expect(find.text(tab), findsOneWidget);
    }

    // AppNavigator.pop returns to the Me tab.
    container.read(appNavigatorProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(DesignPreviewScreen), findsNothing);
    expect(find.byType(MeScreen), findsOneWidget);
  });

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

  testWidgets('AppNavigator.push shows the route on top and pop returns', (
    tester,
  ) async {
    _phoneSize(tester);
    final container = await pumpApp(tester);
    container.read(appNavigatorProvider).pop(); // nothing to pop: no-op
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);

    container.read(appRouterProvider).go(const MeRoute());
    await tester.pumpAndSettle();
    container.read(appNavigatorProvider).push(const DesignPreviewRoute());
    await tester.pumpAndSettle();
    expect(find.byType(DesignPreviewScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MeScreen), findsOneWidget);
  });

  testWidgets('the preview switch changes the theme setting and the app '
      'theme between light, dark and system; the palette is "Warm"', (
    tester,
  ) async {
    _phoneSize(tester);
    final container = await pumpApp(tester);
    showRoute(container, const DesignPreviewRoute());
    await tester.pumpAndSettle();

    ThemeData current() => Theme.of(tester.element(find.byType(Scaffold).last));
    expect(
      container.read(themePreferenceProvider).value,
      anyOf(isNull, ThemePreference.system),
    );
    // The test platform is light.
    expect(current().colorScheme.primary, FbPalette.of(Brightness.light).brand);

    await tester.tap(find.text('Dark'));
    await settleWrites(tester);
    expect(
      await tester.runAsync(
        () => container.read(themePreferenceProvider.future),
      ),
      ThemePreference.dark,
    );
    expect(current().brightness, Brightness.dark);
    expect(current().colorScheme.primary, FbPalette.of(Brightness.dark).brand);

    await tester.tap(find.text('Light'));
    await settleWrites(tester);
    expect(current().brightness, Brightness.light);

    await tester.tap(find.text('System'));
    await settleWrites(tester);
    expect(
      await tester.runAsync(
        () => container.read(themePreferenceProvider.future),
      ),
      ThemePreference.system,
    );
    await unmountApp(tester, container);
  });

  // Today has a diary and Me has foods; the other tabs still have placeholders.
  testWidgets('UX-050 tab placeholders use the design-system empty state', (
    tester,
  ) async {
    _phoneSize(tester);
    final container = await pumpApp(tester);
    final screens = {
      const ProgressRoute(): ProgressScreen,
      const WorkoutsRoute(): WorkoutsScreen,
    };
    for (final MapEntry(key: route, value: screen) in screens.entries) {
      showRoute(container, route);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(screen),
          matching: find.byType(FbEmptyState),
        ),
        findsOneWidget,
        reason: route.location,
      );
    }
    // Today has no plain title bar (backlog #35).
    showRoute(container, const TodayRoute());
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(TodayScreen),
        matching: find.byType(AppBar),
      ),
      findsNothing,
    );
  });

  testWidgets('the Mockups tab has an entry for each mockup', (tester) async {
    _phoneSize(tester);
    final container = await pumpApp(tester);
    showRoute(container, const DesignPreviewRoute());
    await tester.pumpAndSettle();

    expect(MockupEntry.values, hasLength(5));
    for (final entry in MockupEntry.values) {
      expect(
        find.byKey(ValueKey('mockup.${entry.name}')),
        findsOneWidget,
        reason: entry.name,
      );
    }
  });

  group('gallery', () {
    test('every public design-system component has a gallery section', () {
      // The same source scan the design system's barrel test does: every
      // public Fb class or enum of components/ and charts/. A new component
      // without a section fails here.
      final declared = <String>{};
      for (final dir in ['components', 'charts']) {
        final files = Directory('../../packages/fb_design_system/lib/src/$dir')
            .listSync()
            .whereType<File>();
        for (final f in files) {
          declared.addAll(
            RegExp(
              r'^(?:abstract |final |sealed )*(?:class|enum) (Fb\w+)',
              multiLine: true,
            ).allMatches(f.readAsStringSync()).map((m) => m.group(1)!),
          );
        }
      }
      // Not in the barrel: the progress bars' building block and the two
      // sheet bodies (public for the design system's goldens only).
      const internal = {
        'FbBarTrack',
        'FbSourceLegendBody',
        'FbEstimateRangeBody',
      };
      final covered = {
        for (final section in gallerySections)
          // A generic component prints as `FbOption<dynamic>`.
          for (final type in section.covers) type.toString().split('<').first,
      };
      expect(declared.difference(internal).difference(covered), isEmpty);
      final names = gallerySections.map((s) => s.name).toList();
      expect(names.toSet(), hasLength(names.length), reason: 'unique names');
    });

    // RTL is covered by the design system's golden matrices; R1's app is
    // English only.
    for (final (name, mode, scale) in [
      ('light', Brightness.light, 1.0),
      ('dark, text x2', Brightness.dark, 2.0),
    ]) {
      testWidgets('shows every section without errors: $name', (tester) async {
        _phoneSize(tester);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher
          ..platformBrightnessTestValue = mode
          ..textScaleFactorTestValue = scale;
        final container = await pumpApp(tester);
        showRoute(container, const DesignPreviewRoute());
        await tester.pumpAndSettle();

        await _openTab(tester, 'Components');
        for (final section in gallerySections) {
          expect(
            find.byKey(ValueKey('gallery.${section.name}')),
            findsOneWidget,
            reason: section.name,
          );
        }

        // The tokens page lists the contrast of the palette on screen.
        await _openTab(tester, 'Tokens');
        final palette = FbPalette.of(mode);
        expect(find.text(fbContrastPairs(palette).first.name), findsOneWidget);
      });
    }
  });
}
