import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../today/presentation/support/today_support.dart';
import '../support/diary_fixtures.dart' show fixtureId;
import 'saved_meals_support.dart';

Widget _phone(
  Widget screen,
  Brightness brightness,
  double scale,
  List<SavedMeal> meals,
) => SizedBox(
  width: 360,
  height: 640,
  child: ProviderScope(
    overrides: fakeMeals(meals),
    child: phoneApp(screen, brightness: brightness, textScale: scale),
  ),
);

Future<void> _golden(
  String name,
  String file,
  Widget screen,
  List<SavedMeal> meals,
) => goldenTest(
  name,
  fileName: file,
  builder: () => GoldenTestGroup(
    columns: 4,
    children: [
      for (final scale in const [1.0, 2.0])
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$label, x$scale',
            child: _phone(screen, brightness, scale, meals),
          ),
    ],
  ),
);

Future<void> main() async {
  final meals = [
    aMeal(90, 'Usual breakfast'),
    aMeal(
      91,
      'Quick lunch with a very long name that keeps going',
      items: ['Rice, white, cooked', 'Chicken thigh', 'Salad'],
    ),
    aMeal(92, 'Snack', items: ['Banana, raw']),
  ];
  await _golden(
    'DY-031 FD-010 UX-070 saved meals list',
    'saved_meals_list',
    const SavedMealsScreen(),
    meals,
  );
  await _golden(
    'DY-031 FD-010 UX-050 saved meals list: empty',
    'saved_meals_list_empty',
    const SavedMealsScreen(),
    const [],
  );
  await _golden(
    'DY-031 FD-010 UX-070 saved meal detail',
    'saved_meal_detail',
    SavedMealScreen(id: fixtureId(90)),
    meals,
  );
}
