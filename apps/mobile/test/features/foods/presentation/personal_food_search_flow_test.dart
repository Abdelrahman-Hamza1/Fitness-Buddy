import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'personal_food_form_test.dart' show fillValues, tapVisible, textOf;
import 'support/personal_food_support.dart';

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('FD-020 #86 no match offers "Create … as your own food"; '
      'saving opens the food sheet with it; Add logs it with ⓨ', (
    tester,
  ) async {
    final container = await pumpPersonal(
      tester,
      at: FoodSearchRoute(
        date: LocalDate(2026, 10, 20),
        slotId: DefaultSlots.dinnerId,
      ),
      overrides: [
        clockProvider.overrideWithValue(
          ManualClock(DateTime.utc(2026, 10, 23, 12)),
        ),
      ],
    );
    await search(tester, 'Labneh');
    expect(find.text('No match for "Labneh"'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FbButton, 'Create "Labneh" as your own food'),
    );
    await settle(tester);

    // The form opened over the search with the name filled in; the name is
    // not in the location (backlog #42).
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
    expect(textOf(tester, 'Name'), 'Labneh');
    expect(
      container.read(appRouterProvider).config.state.uri.toString(),
      '/today/add-food/new-food?date=2026-10-20&slot=${DefaultSlots.dinnerId}',
    );
    expect(find.byType(NavigationBar), findsOneWidget);

    await fillValues(tester);
    await tapVisible(tester, find.text('Save'));

    // The form closes and the food sheet takes over, for the new food.
    expect(find.byType(PersonalFoodFormScreen), findsNothing);
    expect(find.byType(FoodSheet), findsOneWidget);
    expect(find.widgetWithText(FbSourceBadge, 'Y'), findsOneWidget);
    expect(find.text('180 kcal'), findsWidgets);

    await tester.tap(find.widgetWithText(FbButton, 'Add'));
    await settle(tester);

    expect(find.byType(FoodSheet), findsNothing);
    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.textContaining('Added Labneh to'), findsOneWidget);
    final food = (await storedFoods(tester, container)).single;
    final entry = (await liveEntries(tester, container)).single;
    expect(entry.foodKind, 'personal');
    expect(entry.foodId, food.id);
    expect(entry.nameEn, 'Labneh');
    expect(entry.source, 'yours');
    expect(entry.localDate, '2026-10-20');
    expect(entry.slotId, DefaultSlots.dinnerId);
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await liveEntries(tester, container), isEmpty);
    expect((await storedFoods(tester, container)).single.id, food.id);
    await finish(tester, container);
  });
}
