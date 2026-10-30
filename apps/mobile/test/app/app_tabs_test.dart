import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../features/diary/support/diary_harness.dart' show atDay, newEntry;
import '../features/foods/presentation/support/personal_food_support.dart';
import '../helpers/pump_app.dart';

/// Tab [index] of the tab bar (0 Today, 1 Progress, 2 Workouts, 3 Me).
Finder _tab(int index) => find
    .descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(NavigationDestination),
    )
    .at(index);

/// The scroll position of the main (vertical) list of [screen].
ScrollPosition _scroll(WidgetTester tester, Type screen) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(screen),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    )
    .position;

Future<void> _tap(WidgetTester tester, int index) async {
  await tester.tap(_tab(index));
  await settle(tester);
}

/// The text in the first field of the personal food form.
String _firstField(WidgetTester tester) => tester
    .widget<EditableText>(
      find
          .descendant(
            of: find.byType(PersonalFoodFormScreen),
            matching: find.byType(EditableText),
          )
          .first,
    )
    .controller
    .text;

void main() {
  testWidgets('UX-010 A45 leaving a tab resets it to its root; re-tapping the '
      'current tab scrolls it to the top, and pops to root when deep', (
    tester,
  ) async {
    // A short phone, so the Me list scrolls.
    useWindow(tester, width: 360, height: 600);
    final container = await pumpApp(tester);
    final router = container.read(appRouterProvider);

    // Progress → Weight graph → Today → Progress: back at its root.
    await _tap(tester, 1);
    router.push(const WeightGraphRoute());
    await settle(tester);
    expect(find.byType(WeightGraphScreen), findsOneWidget);
    await _tap(tester, 0);
    expect(find.byType(TodayScreen), findsOneWidget);
    await _tap(tester, 1);
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.byType(WeightGraphScreen, skipOffstage: false), findsNothing);

    // A scrolled Me list: a re-tap of Me scrolls it to the top.
    await _tap(tester, 3);
    final me = _scroll(tester, MeScreen);
    expect(me.maxScrollExtent, greaterThan(0));
    me.jumpTo(me.maxScrollExtent);
    await tester.pump();
    await _tap(tester, 3);
    expect(_scroll(tester, MeScreen).pixels, 0);

    // A long Today page (an opened slot of 15 items), scrolled down: a
    // re-tap of Today scrolls it to the top.
    final date = EntryTime.now(container.read(clockProvider)).localDate;
    await applyOps(tester, container, [
      LogEntries([
        for (var n = 1; n <= 15; n++)
          newEntry(n, slotId: DefaultSlots.breakfastId, when: atDay(date, 8)),
      ]),
    ]);
    await _tap(tester, 0);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is SlotHeaderTile && w.section.key == DefaultSlots.breakfastId,
      ),
    );
    await settle(tester);
    final today = _scroll(tester, TodayScreen);
    expect(today.maxScrollExtent, greaterThan(0));
    today.jumpTo(today.maxScrollExtent);
    await tester.pump();
    expect(_scroll(tester, TodayScreen).pixels, greaterThan(0));
    await _tap(tester, 0);
    expect(_scroll(tester, TodayScreen).pixels, 0);

    // Me → Your foods → re-tap Me: back at the root.
    await _tap(tester, 3);
    router.push(const PersonalFoodsRoute());
    await settle(tester);
    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    await _tap(tester, 3);
    expect(find.byType(MeScreen), findsOneWidget);
    expect(find.byType(PersonalFoodsScreen, skipOffstage: false), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('A45 a personal food form with unsaved edits survives a tab '
      'switch; a re-tap asks, cancel keeps it, discard ends at the tab root', (
    tester,
  ) async {
    final container = await pumpPersonal(
      tester,
      at: const PersonalFoodsRoute(),
    );
    final router = container.read(appRouterProvider)
      ..push(const PersonalFoodRoute());
    await settle(tester);
    final field = find
        .descendant(
          of: find.byType(PersonalFoodFormScreen),
          matching: find.byType(TextField),
        )
        .first;
    await tester.enterText(field, 'Draft');
    await tester.pump();

    // A switch away and back keeps the form and its text.
    await _tap(tester, 0);
    expect(find.byType(TodayScreen), findsOneWidget);
    await _tap(tester, 3);
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
    expect(_firstField(tester), 'Draft');

    // A re-tap asks; keeping the edits leaves everything as it was.
    await _tap(tester, 3);
    expect(find.byType(FbSheet), findsOneWidget);
    // The sheet's buttons: keep editing, then discard.
    Finder sheetButton(int index) => find
        .descendant(of: find.byType(FbSheet), matching: find.byType(FbButton))
        .at(index);
    await tester.tap(sheetButton(0));
    await settle(tester);
    expect(find.byType(FbSheet), findsNothing);
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
    expect(_firstField(tester), 'Draft');

    // The system back on the dirty form still asks, through the guard.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(FbSheet), findsOneWidget);
    await tester.tap(sheetButton(0));
    await settle(tester);
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);

    // A re-tap and a discard: the Me root, no form and no foods list.
    await _tap(tester, 3);
    await tester.tap(sheetButton(1));
    await settle(tester);
    expect(find.byType(MeScreen), findsOneWidget);
    expect(
      find.byType(PersonalFoodFormScreen, skipOffstage: false),
      findsNothing,
    );
    expect(find.byType(PersonalFoodsScreen, skipOffstage: false), findsNothing);
    expect(router.config.state.matchedLocation, const MeRoute().location);
    await unmountApp(tester, container);
  });
}
