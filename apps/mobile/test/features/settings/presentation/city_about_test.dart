import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart' show SettingsOp;
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/catalog/support/catalog_support.dart';
import '../../../helpers/pump_app.dart';
import '../../today/presentation/support/today_support.dart';
import 'settings_support.dart';

Finder _rowOf(String title) => find.widgetWithText(FbListRow, title);

Finder _in(Finder of, String text) =>
    find.descendant(of: of, matching: find.text(text));

/// The app on the fixture pack (its cities and credits), at [route].
Future<ProviderContainer> _openAt(
  WidgetTester tester,
  AppRoute route, {
  AppConfig? config,
  String credits = '',
  bool settle = true,
  List<Override> overrides = const [],
}) async {
  final (db, _) = fixtureCatalog(
    extraSql: credits.isEmpty
        ? ''
        : "UPDATE meta SET value = '$credits' WHERE key = 'attribution';",
  );
  final container = await pumpAt(
    tester,
    phone: phoneOf(config ?? devConfig),
    overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
  );
  showRoute(container, route);
  // A loading placeholder animates for ever, so it is never settled.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

/// The settings writer, held at its first write until [gate] completes: the
/// city write stays in flight while the test taps and navigates.
Override _gatedSettingsWrites(Completer<void> gate) =>
    changeSetApplierProvider.overrideWith((ref) {
      final db = ref.watch(appDatabaseProvider);
      final handlers = ref.watch(changeOpHandlersProvider);
      var first = true;
      return ChangeSetApplier(
        db: db,
        tables: db.syncedTables,
        handlers: (db) => [
          for (final handler in handlers(db))
            if (handler is SettingsOpHandler)
              _GatedSettingsHandler(handler, () {
                if (!first) return Future.value();
                first = false;
                return gate.future;
              })
            else
              handler,
        ],
        clock: ref.watch(clockProvider),
        ids: ref.watch(idGeneratorProvider),
        deviceId: ref.watch(deviceIdStoreProvider).deviceId,
        events: ref.watch(domainEventBusProvider),
      );
    });

final class _GatedSettingsHandler extends ChangeOpHandler<SettingsOp> {
  new(this.delegate, this.before);

  final SettingsOpHandler delegate;
  final Future<void> Function() before;

  @override
  String get family => SettingsOp.familyName;

  @override
  Future<OpPlan> plan(SettingsOp op, TxReader tx, ApplyContext context) async {
    await before();
    return await delegate.plan(op, tx, context);
  }
}

final String _credits = jsonEncode([
  for (final name in ['USDA', 'GeoNames', 'Open Food Facts'])
    {
      'id': name,
      'name': name,
      'credit': '$name credit',
      'licence': 'not displayed',
      'note': 'private note',
      'url': '',
      'used_for': '',
      'status': name == 'Open Food Facts' ? 'planned' : 'active',
    },
]);

void main() {
  testWidgets('LC-033 city picker: empty query shows the current city then '
      'PS/JO suggestions; typing "nab" shows Nablus first; a tap sets it, '
      'pops, shows Undo; the row shows "Nablus"', (tester) async {
    final container = await _openAt(tester, const MeRoute());
    expect(_in(_rowOf('City'), 'Not set'), findsOneWidget);

    // Hebron is chosen first, so that it leads the suggestions, checked.
    await tester.tap(_rowOf('City'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hebron');
    await tester.pump();
    await tester.tap(find.text('Hebron · الخليل'));
    await settleWrites(tester);
    expect(_in(_rowOf('City'), 'Hebron · الخليل'), findsOneWidget);
    await tester.tap(_rowOf('City'));
    await tester.pumpAndSettle();
    expect(find.byType(CityPickerScreen), findsOneWidget);
    expect(find.text('Suggested cities'), findsOneWidget);
    final first = find.text('Hebron · الخليل');
    expect(first, findsOneWidget);
    expect(find.byIcon(FbIcons.check), findsOneWidget);
    // The selected row is announced once: one node, selected, and no
    // separate node for the check icon.
    final semantics = tester.ensureSemantics();
    final announced = find.bySemanticsLabel(RegExp('^Hebron'));
    expect(announced, findsOneWidget);
    final node = tester.getSemantics(announced);
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(node.getSemanticsData().label, contains('Palestine'));
    semantics.dispose();
    final y = tester.getTopLeft(first).dy;
    for (final other in [
      'Nablus · نابلس',
      'Ramallah · رام الله',
      'Amman · عمّان',
    ]) {
      expect(find.text(other), findsOneWidget, reason: other);
      expect(tester.getTopLeft(find.text(other)).dy, greaterThan(y));
    }
    // Palestine before Jordan before the rest, by population in each.
    expect(find.text('Cairo · القاهرة'), findsNothing);
    expect(find.text('Palestine'), findsWidgets);

    // Typing finds a city by name; the search field has the keyboard.
    expect(tester.widget<TextField>(find.byType(TextField)).autofocus, isTrue);
    await tester.enterText(find.byType(TextField), 'nab');
    await tester.pump();
    expect(find.text('Nablus · نابلس'), findsOneWidget);
    expect(find.text('Hebron · الخليل'), findsNothing);
    await tester.tap(find.text('Nablus · نابلس'));
    await settleWrites(tester);

    expect(find.byType(CityPickerScreen), findsNothing);
    expect(find.text('City set to Nablus · نابلس'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(_in(_rowOf('City'), 'Nablus · نابلس'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settleWrites(tester);
    expect(_in(_rowOf('City'), 'Hebron · الخليل'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('UX-050 LC-033 no match says "No city found. Try the English or '
      'Arabic name."', (tester) async {
    final container = await _openAt(tester, const CityPickerRoute());
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(
      find.text('No city found. Try the English or Arabic name.'),
      findsOneWidget,
    );
    // The Arabic name finds the city too, folding the marks.
    await tester.enterText(find.byType(TextField), 'عمان');
    await tester.pump();
    expect(find.text('Amman · عمّان'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('UX-052 LC-033 without a city list the picker says so for any '
      'query, never "No city found"', (tester) async {
    // The default test database has no catalog pack attached.
    final container = await pumpAt(tester, phone: phoneOf(devConfig));
    showRoute(container, const CityPickerRoute());
    await tester.pumpAndSettle();
    const unavailable = "The city list isn't available right now.";
    expect(find.text(unavailable), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nab');
    await tester.pump();
    expect(find.text(unavailable), findsOneWidget);
    expect(
      find.text('No city found. Try the English or Arabic name.'),
      findsNothing,
    );
    await unmountApp(tester, container);
  });

  testWidgets('D7 "Use my location" shows only in dev, saying Coming soon', (
    tester,
  ) async {
    final container = await _openAt(tester, const CityPickerRoute());
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    await unmountApp(tester, container);

    final prod = await _openAt(
      tester,
      const CityPickerRoute(),
      config: prodConfig,
    );
    expect(find.text('Use my location'), findsNothing);
    expect(find.text('Coming soon'), findsNothing);
    await unmountApp(tester, prod);
  });

  testWidgets('UX-051 PA6 the city picker shows skeleton rows until the '
      'cities load; a read error shows "Couldn\'t load the city list." with '
      'Try again, which reloads', (tester) async {
    final gate = Completer<CitySearch>();
    var attempts = 0;
    final container = await _openAt(
      tester,
      const CityPickerRoute(),
      settle: false,
      overrides: [
        citySearchProvider.overrideWith((ref) {
          attempts++;
          if (attempts == 1) return gate.future;
          if (attempts == 2) return Future<CitySearch>.error(Exception('x'));
          return Future.value(CitySearch(sampleCities));
        }),
      ],
    );
    // Loading: skeleton rows, no list, no message.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FbSkeleton), findsAtLeastNWidgets(4));
    expect(find.text('Nablus · نابلس'), findsNothing);

    // The read fails: the error, with a way to retry.
    ProviderScope.containerOf(tester.element(find.byType(CityPickerScreen)))
        .invalidate(citySearchProvider);
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load the city list."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(FbSkeleton), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load the city list."), findsNothing);
    expect(find.text('Nablus · نابلس'), findsOneWidget);
    gate.complete(CitySearch(sampleCities));
    await unmountApp(tester, container);
  });

  testWidgets('SF-040 About shows the version, the food data version, the '
      'USDA and GeoNames credits, the licences link and "Fitness Buddy gives '
      'estimates for tracking, not medical advice."', (tester) async {
    final container = await _openAt(
      tester,
      const AboutRoute(),
      config: prodConfig,
      credits: _credits,
    );
    expect(find.text('Fitness Buddy'), findsOneWidget);
    expect(find.text('Version 0.1.0 (1)'), findsOneWidget);
    expect(find.text('Food data version 1'), findsOneWidget);
    expect(find.text('USDA: USDA credit'), findsOneWidget);
    expect(find.text('GeoNames: GeoNames credit'), findsOneWidget);
    // Not active yet, and never the note or the licence text.
    expect(find.textContaining('Open Food Facts'), findsNothing);
    expect(find.textContaining('private note'), findsNothing);
    expect(find.textContaining('not displayed'), findsNothing);
    expect(
      find.text(
        'Fitness Buddy gives estimates for tracking, not medical advice.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Open-source licences'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LicensePage), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('SF-040 outside production About names the build', (
    tester,
  ) async {
    final container = await _openAt(
      tester,
      const AboutRoute(),
      credits: _credits,
    );
    expect(find.text('Version 0.1.0 (1) · dev'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('UX-051 PA6 About shows skeleton lines for the version and '
      'food data until they load; a pack read error shows the '
      'credits-unavailable line and the rest of the page', (tester) async {
    final gate = Completer<AboutInfo>();
    final container = await _openAt(
      tester,
      const AboutRoute(),
      settle: false,
      overrides: [aboutInfoProvider.overrideWith((ref) => gate.future)],
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FbSkeleton), findsAtLeastNWidgets(3));
    expect(find.textContaining('Version'), findsNothing);
    // What needs no data is there from the start.
    expect(find.text('Open-source licences'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);

    gate.complete(
      const AboutInfo(
        version: '0.1.0',
        build: '1',
        flavor: AppFlavor.prod,
        packVersion: null,
        activeCredits: null,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FbSkeleton), findsNothing);
    expect(find.text('Version 0.1.0 (1)'), findsOneWidget);
    expect(find.textContaining('Food data version'), findsNothing);
    expect(
      find.text("Data credits aren't available right now."),
      findsOneWidget,
    );
    expect(container, isNotNull);
    await unmountApp(tester, container);
  });

  testWidgets("UX-052 About says the version isn't available when it can't "
      'be read, and still shows the rest', (tester) async {
    final container = await _openAt(
      tester,
      const AboutRoute(),
      overrides: [
        aboutInfoProvider.overrideWith(
          (ref) => Future<AboutInfo>.error(Exception('x')),
        ),
      ],
    );
    expect(find.text("Version isn't available right now."), findsOneWidget);
    expect(find.byType(FbSkeleton), findsNothing);
    expect(find.textContaining('Version 0'), findsNothing);
    expect(find.text('Open-source licences'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets("UX-052 About without a pack says credits aren't available", (
    tester,
  ) async {
    // The default test database has no catalog pack attached.
    final container = await pumpAt(tester, phone: phoneOf(prodConfig));
    showRoute(container, const AboutRoute());
    await tester.pumpAndSettle();
    expect(find.text('Version 0.1.0 (1)'), findsOneWidget);
    expect(
      find.text("Data credits aren't available right now."),
      findsOneWidget,
    );
    expect(find.text('Open-source licences'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('UX-070 Me and the city picker at text scale 2.0 do not '
      'overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = await _openAt(tester, const MeRoute());
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    showRoute(container, const CityPickerRoute());
    await tester.pumpAndSettle();
    expect(find.byType(CityPickerScreen), findsOneWidget);
    expect(find.byType(FbListRow), findsWidgets);
    await tester.enterText(find.byType(TextField), 'ra');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    showRoute(container, const AboutRoute());
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await unmountApp(tester, container);
  });

  testWidgets('UX-070 Me, the city picker and About at text scale 1.3 do not '
      'overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = await _openAt(tester, const MeRoute(), credits: _credits);
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    showRoute(container, const CityPickerRoute());
    await tester.pumpAndSettle();
    expect(find.byType(FbListRow), findsWidgets);
    await tester.enterText(find.byType(TextField), 'ra');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    showRoute(container, const AboutRoute());
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester, container);
  });

  group('RTL', () {
    final overrides = [
      ...fakeToday(),
      citySearchProvider.overrideWith((ref) async => CitySearch(sampleCities)),
      ...fakeSettings(city: sampleCities.first),
    ];

    Future<void> pumpRtl(WidgetTester tester, Widget screen) async {
      tester.view
        ..physicalSize = const Size(320, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: phoneApp(
            Directionality(textDirection: TextDirection.rtl, child: screen),
            textScale: 1.3,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('UX-070 Me in right-to-left layout does not overflow and '
        'shows the city as "Nablus · نابلس"', (tester) async {
      await pumpRtl(tester, const MeScreen());
      expect(tester.takeException(), isNull);
      expect(_in(_rowOf('City'), 'Nablus · نابلس'), findsOneWidget);
      expect(
        Directionality.of(tester.element(_rowOf('City'))),
        TextDirection.rtl,
      );
    });

    testWidgets('UX-070 the city picker in right-to-left layout does not '
        'overflow and shows "Nablus · نابلس"', (tester) async {
      await pumpRtl(tester, const CityPickerScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('Nablus · نابلس'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'nab');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Nablus · نابلس'), findsOneWidget);
    });
  });

  testWidgets('LC-033 PA6 while the city is being saved the choices are off: '
      'a second tap is ignored and the picker stays until the write is done, '
      'then closes once', (tester) async {
    final gate = Completer<void>();
    final container = await _openAt(
      tester,
      const MeRoute(),
      overrides: [_gatedSettingsWrites(gate)],
    );
    await tester.tap(_rowOf('City'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nablus · نابلس'));
    await tester.pump();
    await tester.tap(find.text('Hebron · الخليل'));
    // Long enough for a pop to finish its transition.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The write is in flight: the picker is still there, nothing else
    // was chosen.
    expect(find.byType(CityPickerScreen), findsOneWidget);

    gate.complete();
    await settleWrites(tester);
    expect(find.byType(CityPickerScreen), findsNothing);
    expect(find.text('City set to Nablus · نابلس'), findsOneWidget);
    expect(_in(_rowOf('City'), 'Nablus · نابلس'), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('LC-033 PA6 a city write that ends after the user has left the '
      'picker does not close the screen they are on now', (tester) async {
    final gate = Completer<void>();
    final container = await _openAt(
      tester,
      const MeRoute(),
      overrides: [_gatedSettingsWrites(gate)],
    );
    await tester.tap(_rowOf('City'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nablus · نابلس'));
    await tester.pump();
    // Another screen opens over the picker while the write is in flight.
    container.read(appNavigatorProvider).push(const AboutRoute());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Open-source licences'), findsOneWidget);

    gate.complete();
    await settleWrites(tester);
    expect(find.text('Open-source licences'), findsOneWidget);
    // The picker is still underneath: it was not the one popped.
    expect(find.byType(CityPickerScreen, skipOffstage: false), findsOneWidget);
    expect(find.text('City set to Nablus · نابلس'), findsOneWidget);
    await unmountApp(tester, container);
  });
}
