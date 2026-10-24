import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/personal_food_support.dart';

void main() {
  testWidgets('UX-013 Your foods is 2 taps from Today', (tester) async {
    final container = await pumpPersonal(tester);
    var taps = 0;
    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      taps++;
      await settle(tester);
    }

    await tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Me'),
      ),
    );
    expect(find.byType(MeScreen), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Nothing to set up yet'), findsNothing);
    await tap(find.text('Your foods'));

    expect(taps, 2);
    expect(find.byType(PersonalFoodsScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('UX-050 an empty Your foods explains what to do and offers New '
      'food', (tester) async {
    final container = await pumpPersonal(
      tester,
      at: const PersonalFoodsRoute(),
    );
    expect(find.text('No foods of your own yet'), findsOneWidget);
    expect(
      find.text(
        'Add a food you eat often with the numbers from its label. It shows '
        'up first in search.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FbButton, 'New food'));
    await settle(tester);

    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);
    expect(find.text('New food'), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('FD-070 Your foods lists the foods by name with the ⓨ badge and '
      'their calories; a tap opens the food', (tester) async {
    final container = await pumpPersonal(
      tester,
      foods: [
        aFood(2, name: 'Zaatar mix', basis: NutrientBasis.per100ml),
        aFood(1, ar: 'لبنة'),
      ],
      at: const PersonalFoodsRoute(),
    );
    final titles = tester
        .widgetList<FbListRow>(find.byType(FbListRow))
        .map((r) => r.title)
        .toList();
    expect(titles, ['Labneh', 'Zaatar mix']);
    expect(find.text('لبنة · 180 kcal per 100 g'), findsOneWidget);
    expect(find.text('180 kcal per 100 ml'), findsOneWidget);
    expect(find.byType(FbSourceBadge), findsNWidgets(2));

    await tester.tap(find.text('Zaatar mix'));
    await settle(tester);
    expect(find.text('Edit food'), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('D10 a malformed food ID goes to the list, and "new" is the '
      'new-food form, not an ID', (tester) async {
    final container = await pumpPersonal(tester);
    final router = container.read(appRouterProvider);

    for (final bad in ['not-a-uuid', '123', 'NOT-A-UUID']) {
      router.config.go('/me/foods/$bad');
      await settle(tester);
      expect(find.byType(PersonalFoodsScreen), findsOneWidget, reason: bad);
      expect(find.byType(PersonalFoodFormScreen), findsNothing, reason: bad);
      expect(router.config.state.matchedLocation, PersonalFoodsRoute.path);
    }

    router.config.go('/me/foods/new');
    await settle(tester);
    expect(find.text('New food'), findsOneWidget);
    expect(find.byType(PersonalFoodFormScreen), findsOneWidget);

    // A well-formed ID of a food that does not exist says it is gone.
    router.config.go(PersonalFoodRoute(id: aFood(7).id).location);
    await settle(tester);
    expect(find.text('This food was deleted.'), findsOneWidget);
    await finish(tester, container);
  });

  test('D10 the personal food routes carry only IDs and dates', () {
    expect(const PersonalFoodsRoute().location, '/me/foods');
    expect(const PersonalFoodRoute().location, '/me/foods/new');
    expect(
      PersonalFoodRoute(id: aFood(1).id).location,
      '/me/foods/${aFood(1).id}',
    );
    expect(const NewFoodFromSearchRoute().location, '/today/add-food/new-food');
    expect(
      NewFoodFromSearchRoute(
        date: LocalDate(2026, 10, 20),
        slotId: 's1',
      ).location,
      '/today/add-food/new-food?date=2026-10-20&slot=s1',
    );
    final back = AppRouter.newFoodRouteOf(
      Uri.parse('/today/add-food/new-food?date=2026-10-20&slot=s1'),
    );
    expect(back.date, LocalDate(2026, 10, 20));
    expect(back.slotId, 's1');
    expect(
      AppRouter.newFoodRouteOf(Uri.parse('/today/add-food/new-food?date=junk'))
          .date,
      isNull,
    );
  });
}
