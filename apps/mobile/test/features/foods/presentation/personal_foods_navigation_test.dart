import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/personal_food_support.dart';

void main() {
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
