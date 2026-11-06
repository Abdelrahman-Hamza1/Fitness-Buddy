import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';
import '../settings/presentation/settings_support.dart';

void main() {
  testWidgets('LC-030 Me › Ramadan: switch on the coming Ramadan, shift its '
      'first day, choose maintain; each saved with Undo', (tester) async {
    final container = await pumpAt(
      tester,
      // The real stored decisions (the test rigs stub them off).
      overrides: [
        ramadanSettingsProvider.overrideWith(
          (ref) => ref
              .watch(settingsStoreProvider)
              .watch(AppSettings.ramadanSeasons),
        ),
      ],
    );
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-ramadan')));
    await tester.pumpAndSettle();
    expect(find.byType(RamadanScreen), findsOneWidget);
    Future<RamadanSettings?> stored() => tester.runAsync(
      () => container
          .read(settingsStoreProvider)
          .read(AppSettings.ramadanSeasons),
    );

    await tester.tap(find.byKey(const ValueKey('ramadan-mode')));
    await settleWrites(tester);
    final on = (await stored())!.seasons.single;
    expect(on.on, isTrue);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ramadan-first-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).last);
    await settleWrites(tester);
    expect((await stored())![on.hijriYear]!.startShift, 1);

    await tester.tap(find.byKey(const ValueKey('ramadan-targets')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).last);
    await settleWrites(tester);
    final season = (await stored())![on.hijriYear]!;
    expect((season.maintain, season.targetsAnswered), (true, true));
    await unmountApp(tester, container);
  });

  testWidgets('UX-052 A63 audit minor a failed city read says so with Try '
      'again, not "no city"', (tester) async {
    var fail = true;
    final container = await pumpAt(
      tester,
      overrides: [
        selectedCityProvider.overrideWith((ref) async {
          if (fail) throw StateError('catalog');
          return null;
        }),
      ],
    );
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-ramadan')));
    await tester.pumpAndSettle();
    final retry = find.byKey(const ValueKey('ramadan-city-retry'));
    expect(retry, findsOneWidget);
    fail = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(retry, findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('A65 N8 M4 past the calendar table Ramadan shows a designed '
      'empty state, and the prayer times stay in their group', (tester) async {
    final container = await pumpAt(
      tester,
      overrides: [ramadanStatusProvider.overrideWith((ref) async => null)],
    );
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-ramadan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ramadan-outside-table')), findsOneWidget);
    expect(find.byKey(const ValueKey('ramadan-method')), findsOneWidget);
    await unmountApp(tester, container);
  });
}
