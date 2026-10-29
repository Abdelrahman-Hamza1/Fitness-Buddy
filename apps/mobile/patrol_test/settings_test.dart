import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';
import 'support/today_test_support.dart';

const _banana = 'usda:banana_raw';
const _bananaName = 'Banana, raw';

/// The tab [label] of the bottom bar.
Future<void> _openTab(WidgetTester tester, String label) => tapExactly(
  tester,
  find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  'the $label tab',
);

/// Waits until no snackbar is left (an Undo snackbar can cover a control on a
/// small phone).
Future<void> _waitNoSnackBar(WidgetTester tester) => waitUntil(
  tester,
  () => find.byType(SnackBar).evaluate().isEmpty,
  'the undo snackbar to go',
  timeout: const Duration(seconds: 20),
);

/// Waits for a snackbar that says [prefix]... (a prefix match only).
Future<void> _waitForSnackBar(WidgetTester tester, String prefix) => waitUntil(
  tester,
  () => find
      .descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(prefix),
      )
      .evaluate()
      .isNotEmpty,
  'the snackbar "$prefix..."',
);

/// Brings [target], which a lazy list may not have built yet, on screen:
/// scrolls the list of the screen [screen] until it exists. Bounded.
Future<void> _reveal(WidgetTester tester, Finder target, Finder screen) async {
  final scrollable = find
      .descendant(of: screen, matching: find.byType(Scrollable))
      .first;
  for (var attempt = 0; attempt < 20; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await pumpFor(tester, const Duration(milliseconds: 100));
      return;
    }
    await tester.drag(scrollable, const Offset(0, -150));
    await pumpFor(tester, const Duration(milliseconds: 100));
  }
  fail(
    'Could not reveal $target after 20 scrolls; on screen: ${screenSummary()}',
  );
}

/// Opens Me and its row titled [title], and waits for [arrived].
Future<void> _openMeRow(
  WidgetTester tester,
  String title,
  bool Function() arrived,
  String reason,
) async {
  await _openTab(tester, 'Me');
  final me = find.byType(MeScreen);
  await waitUntil(tester, () => me.evaluate().isNotEmpty, 'the Me screen');
  final row = find.widgetWithText(FbListRow, title);
  await _reveal(tester, row, me);
  await tapExactly(tester, row.first, 'the "$title" row');
  await waitUntil(tester, arrived, reason);
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// Chooses [label] in the option sheet that is open, and waits for it to go.
Future<void> _chooseOption(WidgetTester tester, String label) async {
  final sheet = find.byType(BottomSheet);
  final option = find.descendant(
    of: sheet,
    matching: find.widgetWithText(ListTile, label),
  );
  await tapExactly(tester, option, 'the "$label" option');
  await waitUntil(
    tester,
    () => find.byType(BottomSheet).evaluate().isEmpty,
    'the option sheet to close',
  );
}

/// Sets Units to [label] ("Imperial" or "Metric") through Me.
Future<void> _setUnits(WidgetTester tester, String label) async {
  await _openMeRow(
    tester,
    'Units',
    () => find.byType(BottomSheet).evaluate().isNotEmpty,
    'the Units sheet',
  );
  await _chooseOption(tester, label);
  await _waitForSnackBar(tester, 'Units set to ${label.toLowerCase()}');
  final row = find.widgetWithText(FbListRow, 'Units');
  await waitUntil(
    tester,
    () => tester.widget<FbListRow>(row.first).subtitle == label,
    'the Units row to say $label',
  );
  await _waitNoSnackBar(tester);
}

/// Today, on yesterday, through the header's previous-day button
/// when it is not already there.
Future<void> _showYesterday(WidgetTester tester) async {
  await _openTab(tester, 'Today');
  await waitUntil(
    tester,
    () => find.byType(TodayScreen).evaluate().isNotEmpty,
    'the Today screen',
  );
  final yesterday = find.descendant(
    of: find.byType(FbDateHeader),
    matching: find.text('Yesterday'),
  );
  if (yesterday.evaluate().isEmpty) {
    await tapExactly(tester, find.byTooltip('Previous day'), 'Previous day');
  }
  await waitUntil(
    tester,
    () => yesterday.evaluate().isNotEmpty,
    'the header to say Yesterday',
  );
  await pumpFor(tester, const Duration(milliseconds: 600));
}

/// The banana row on [date], with its meal open, shows [amount] as its
/// subtitle (the logged amount in the unit system's words).
Future<void> _expectAmount(
  WidgetTester tester,
  LocalDate date,
  String amount,
) async {
  final slot = find.descendant(
    of: dayPage(date),
    matching: find.widgetWithText(FbDisclosureRow, 'Breakfast'),
  );
  await revealDayWidget(tester, slot, date);
  if (!tester.widget<FbDisclosureRow>(slot).expanded) {
    await tapExactly(tester, slot, 'the Breakfast meal row');
    await waitUntil(
      tester,
      () => tester.widget<FbDisclosureRow>(slot).expanded,
      'the Breakfast meal to open',
    );
  }
  final row = find.descendant(
    of: dayPage(date),
    matching: find.byWidgetPredicate(
      (w) => w is FbListRow && w.title == _bananaName,
      description: 'the $_bananaName row',
    ),
  );
  await waitUntil(
    tester,
    () => row.evaluate().isNotEmpty,
    'the $_bananaName row on $date',
  );
  await revealDayWidget(tester, row, date, interactive: false);
  String shown() =>
      row.evaluate().isEmpty ? '-' : tester.widget<FbListRow>(row).subtitle!;
  await waitUntil(
    tester,
    () => shown() == amount,
    'the $_bananaName row to say "$amount" (it says "${shown()}")',
  );
}

Brightness? _brightness(WidgetTester tester) {
  final scaffold = find.byType(Scaffold);
  if (scaffold.evaluate().isEmpty) return null;
  return Theme.of(tester.element(scaffold.first)).brightness;
}

/// Starts the app on the profile database in [root] without waiting for the
/// pack, as a cold start does.
Future<ProviderContainer> _launch(
  WidgetTester tester,
  Directory root,
  String profileKey,
) async {
  final container = ProviderContainer(
    overrides: [
      ...appOverrides(AppConfig.fromEnvironment()),
      databaseLocationProvider.overrideWithValue(
        isolatedLocation(profileKey, root.path),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
  return container;
}

/// UX-040 UX-010 LC-010 LC-011 LC-033 SF-040 on the device (A10): no API is
/// reachable (as in `app_test`), the profile is a throw-away database. A food
/// is logged on yesterday through the app's own command, then the settings
/// are changed through Me like a user would.
void main() {
  patrolTest('A10 settings journey units theme city', ($) async {
    final container = await bootApp($, 'it-settings', rootName: 'fb_set_it');
    final tester = $.tester;
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final yesterday = today.plusDays(-1);

    // 100 g of banana on yesterday's breakfast (the single writer, as a
    // user's own log would).
    // The pack installs in the background after the app boots: wait
    // (bounded, 30 s) until it can answer, instead of failing on an empty read.
    final catalog = container.read(foodCatalogRepositoryProvider);
    CatalogFood? food;
    for (var attempt = 0; attempt < 60 && food == null; attempt++) {
      food = (await catalog.foodsByIds([_banana]))[_banana]?.firstOrNull;
      if (food == null) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    if (food == null) fail('The pack has no food $_banana after 30 s');
    final logged = await container.read(logFoodProvider)(
      choice: catalogChoice(food),
      input: Quantity(100, 'g'),
      date: yesterday,
      slotId: DefaultSlots.breakfastId,
    );
    expect(logged, isA<FoodLogged>(), reason: 'seeding the banana');

    // Metric by default: the amount reads in grams.
    await _showYesterday(tester);
    await _expectAmount(tester, yesterday, '100 g');

    // Imperial: the same entry reads in ounces (100 g is 3.5 oz).
    await _setUnits(tester, 'Imperial');
    await _showYesterday(tester);
    await _expectAmount(tester, yesterday, '3.5 oz');

    // Back to metric.
    await _setUnits(tester, 'Metric');
    await _showYesterday(tester);
    await _expectAmount(tester, yesterday, '100 g');

    // Theme dark: the app is dark and the choice is stored.
    await _openMeRow(
      tester,
      'Theme',
      () => find.byType(BottomSheet).evaluate().isNotEmpty,
      'the Theme sheet',
    );
    // Dark is the default (D-082), so Light is the change.
    await _chooseOption(tester, 'Light');
    await _waitForSnackBar(tester, 'Theme set to Light');
    await waitUntil(
      tester,
      () => _brightness(tester) == Brightness.light,
      'the app to turn light',
    );
    expect(
      container.read(themePreferenceProvider).value,
      ThemePreference.light,
    );
    await _waitNoSnackBar(tester);

    // City: type "nab", wait for the list (not the skeleton), choose Nablus.
    await _openMeRow(
      tester,
      'City',
      () => find.byType(CityPickerScreen).evaluate().isNotEmpty,
      'the city picker',
    );
    await waitUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(CityPickerScreen),
            matching: find.byType(FbSkeleton),
          )
          .evaluate()
          .isEmpty,
      'the city list to load',
    );
    await tester.enterText(find.byType(TextField), 'nab');
    final nablus = find.byWidgetPredicate(
      (w) => w is FbListRow && w.title.startsWith('Nablus'),
      description: 'the Nablus row',
    );
    await waitUntil(
      tester,
      () => nablus.evaluate().isNotEmpty,
      'Nablus in the results for "nab"',
    );
    await tapExactly(tester, nablus.first, 'the Nablus row');
    await waitUntil(
      tester,
      () =>
          find.byType(CityPickerScreen).evaluate().isEmpty &&
          find.byType(MeScreen).evaluate().isNotEmpty,
      'the picker to close',
    );
    await _waitForSnackBar(tester, 'City set to Nablus');
    final cityRow = find.widgetWithText(FbListRow, 'City');
    await waitUntil(
      tester,
      () =>
          cityRow.evaluate().isNotEmpty &&
          (tester.widget<FbListRow>(cityRow.first).subtitle ?? '').startsWith(
            'Nablus',
          ),
      'the City row to say Nablus',
    );
    expect(container.read(cityIdProvider).value, 'city:282615');
    await _waitNoSnackBar(tester);

    // About: the GeoNames credit shows once the pack's credits have loaded.
    final me = find.byType(MeScreen);
    final about = find.widgetWithText(FbListRow, 'About Fitness Buddy');
    await _reveal(tester, about, me);
    await tapExactly(tester, about, 'the About row');
    await waitUntil(
      tester,
      () => find.byType(AboutScreen).evaluate().isNotEmpty,
      'the About screen',
    );
    final credit = find.textContaining('GeoNames (geonames.org)');
    await waitUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(AboutScreen),
            matching: find.byType(FbSkeleton),
          )
          .evaluate()
          .isEmpty,
      'the About credits to load',
    );
    await _reveal(tester, credit, find.byType(AboutScreen));
    expect(credit, findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 4)));

  patrolTest('A10 cold start with a persisted opposite theme', ($) async {
    final tester = $.tester;
    // Light, the opposite of the dark default (D-082, A44 D7): frame 1 is
    // dark (the window and the default), then one switch to the stored
    // choice, without animation (D6).
    final systemDark =
        tester.platformDispatcher.platformBrightness == Brightness.dark;
    const chosen = ThemePreference.light;
    const want = Brightness.light;

    final cache = await getTemporaryDirectory();
    final root = await cache.createTemp('fb_theme_it');
    addTearDown(() {
      try {
        root.deleteSync(recursive: true);
      } on FileSystemException {
        // The cache directory is cleaned by the system anyway.
      }
    });

    // First run: persist the choice through the single writer, then stop.
    var container = await _launch(tester, root, 'it-theme');
    expect(find.byType(TodayScreen), findsOneWidget);
    final outcome = await container
        .read(settingsActionsProvider)
        .setTheme(chosen);
    expect(outcome, isA<SettingsDone>(), reason: 'storing the theme');
    await waitUntil(
      tester,
      () => container.read(themePreferenceProvider).value == chosen,
      'the theme to be stored',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    // The database closes in the background; let it finish before reopening.
    await pumpFor(tester, const Duration(seconds: 2));

    // Cold start: a new container on the same database. Count the frames and
    // time until the chosen theme is on screen (printed, not asserted tightly:
    // the first frame uses the dark default, A44 D7).
    final watch = Stopwatch()..start();
    container = await _launch(tester, root, 'it-theme');
    addTearDown(container.dispose);
    expect(find.byType(TodayScreen), findsOneWidget);
    var frames = 1;
    final first = _brightness(tester);
    while (_brightness(tester) != want) {
      if (watch.elapsed > const Duration(seconds: 30)) {
        fail(
          'The $want theme never showed after a cold start with the stored '
          '${chosen.name} theme (system dark: $systemDark; first frame '
          '$first); on screen: ${screenSummary()}',
        );
      }
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    debugPrint(
      'A10 theme cold start: system ${systemDark ? 'dark' : 'light'}, '
      'stored ${chosen.name}, first frame ${first?.name ?? 'none'}, '
      '$frames pumped frame(s) and ${watch.elapsedMilliseconds} ms until the '
      '${want.name} theme (flash: ${first != want})',
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}
