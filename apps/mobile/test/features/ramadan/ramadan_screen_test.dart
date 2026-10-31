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
}
