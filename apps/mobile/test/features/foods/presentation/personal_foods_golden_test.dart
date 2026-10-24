import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/foods/presentation/personal_foods/merge_food_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';

import 'support/personal_food_support.dart' show aFood;
import 'support/search_screen_support.dart';
import 'support/sheet_support.dart';

/// Width of a golden cell in dp (a phone).
const double _width = 360;

/// A golden of [name] with [cell] at text scale 1.0 and 2.0, light and dark
/// (LTR only: R1 is English, `09` §3). The form is a long scrolling screen,
/// so its cell is as tall as all of it.
Future<void> _golden(
  String name,
  String file,
  Widget Function(Brightness brightness, double scale) cell, {
  List<double> scales = const [1, 2],
}) => goldenTest(
  name,
  fileName: file,
  builder: () => GoldenTestGroup(
    columns: scales.length * 2,
    children: [
      for (final scale in scales)
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$label, x$scale',
            child: cell(brightness, scale),
          ),
    ],
  ),
);

/// A screen in a cell: no cell takes the focus, so every one looks the same.
Widget _screen(
  Widget screen,
  Brightness brightness,
  double scale,
  double height,
  List<Override> overrides,
) => SizedBox(
  width: _width,
  height: height,
  child: ExcludeFocus(
    child: ProviderScope(
      overrides: overrides,
      child: screenApp(screen, brightness: brightness, textScale: scale),
    ),
  ),
);

/// The form's cell height: all the sections at that text scale.
double _formHeight(double scale) => scale > 1 ? 2800 : 1750;

List<Override> _formOverrides(
  List<PersonalFood> foods, [
  PersonalFood? edited,
]) => [
  personalFoodsProvider.overrideWith((ref) => Stream.value(foods)),
  if (edited != null)
    personalFoodProvider(edited.id).overrideWith((ref) => Stream.value(edited)),
];

/// Both foods of the merge confirmation, as the database would stream them.
List<Override> _mergeOverrides() => [
  personalFoodProvider(aFood(1).id)
      .overrideWith((ref) => Stream.value(aFood(1))),
  personalFoodProvider(aFood(2).id)
      .overrideWith((ref) => Stream.value(aFood(2, name: 'Labne'))),
];

/// A label's numbers entered per serving: a 30 g bar, 120 kcal.
final PersonalFood _bar = PersonalFood(
  id: aFood(3).id,
  version: 1,
  draft: PersonalFoodDraft.fromServing(
    names: FoodNames('Protein bar', ar: 'لوح بروتين'),
    brand: 'Fit Co',
    valuesPerServing: Nutrients(
      kcal: 120,
      protein: 12,
      carbs: 8,
      fat: 4,
      fiber: 3,
      extras: {NutrientKey.sugar: 2, NutrientKey.sodium: 90},
    ),
    serving: PersonalFoodServing('serving', 30),
    aliases: ['bar'],
    servings: [PersonalFoodServing('piece', 30)],
  ),
);

/// Calories that do not match the macros: about 78 kcal expected.
final PersonalFood _mismatch = PersonalFood(
  id: aFood(4).id,
  version: 1,
  draft: PersonalFoodDraft(
    names: FoodNames('Mystery spread'),
    per100: Nutrients(kcal: 500, protein: 5, carbs: 10, fat: 2, fiber: 0),
  ),
);

Future<void> main() async {
  await _golden(
    'FD-070 UX-070 personal food form: new',
    'personal_food_form_new',
    (brightness, scale) => _screen(
      const PersonalFoodFormScreen(),
      brightness,
      scale,
      _formHeight(scale),
      _formOverrides(const []),
    ),
  );
  await _golden(
    'FD-012 UX-070 personal food form: filled with the sanity warning',
    'personal_food_form_sanity_warning',
    (brightness, scale) => _screen(
      PersonalFoodFormScreen(id: _mismatch.id),
      brightness,
      scale,
      _formHeight(scale),
      _formOverrides([_mismatch], _mismatch),
    ),
  );
  await _golden(
    'FD-070 UX-070 personal food form: per serving',
    'personal_food_form_per_serving',
    (brightness, scale) => _screen(
      PersonalFoodFormScreen(id: _bar.id),
      brightness,
      scale,
      _formHeight(scale),
      _formOverrides([_bar], _bar),
    ),
  );
  await _golden(
    'UX-050 FD-010 your foods list',
    'your_foods_list',
    (brightness, scale) => _screen(
      const PersonalFoodsScreen(),
      brightness,
      scale,
      scale > 1 ? 640 : 420,
      [
        personalFoodsProvider.overrideWith(
          (ref) => Stream.value([
            aFood(1, ar: 'لبنة'),
            _bar,
            aFood(2, name: 'Zaatar mix', basis: NutrientBasis.per100ml),
          ]),
        ),
      ],
    ),
  );
  await _golden(
    'FD-073 UX-070 merge confirm sheet',
    'merge_confirm_sheet',
    (brightness, scale) => SizedBox(
      width: _width,
      height: scale > 1 ? 1400 : 650,
      child: ProviderScope(
        overrides: _mergeOverrides(),
        child: screenApp(
          Scaffold(
            body: Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: FbSheet(
                title: 'Merge these foods?',
                child: MergeConfirmSheet(
                  keep: aFood(1),
                  other: aFood(2, name: 'Labne'),
                ),
              ),
            ),
          ),
          brightness: brightness,
          textScale: scale,
        ),
      ),
    ),
  );
  await goldenTest(
    'UX-070 #85 food sheet at 2.0 on a 412 x 915 phone',
    fileName: 'food_sheet_at_2_0',
    builder: () {
      final choice = catalogChoice(
        riceCooked,
        history: usedBefore(riceCooked, 100, 'g', 100),
        siblings: [riceDry],
        yields: yields,
      );
      return GoldenTestGroup(
        columns: 2,
        children: [
          for (final (label, brightness) in const [
            ('light', Brightness.light),
            ('dark', Brightness.dark),
          ])
            GoldenTestScenario(
              name: '$label, x2.0',
              child: SizedBox(
                width: 412,
                height: 915,
                child: ProviderScope(
                  overrides: displayOverrides(choice),
                  child: screenApp(
                    Scaffold(
                      body: Align(
                        alignment: AlignmentDirectional.bottomCenter,
                        child: FbSheet(
                          child: FoodSheet(pick: FoodPick(row: rowFor(choice))),
                        ),
                      ),
                    ),
                    brightness: brightness,
                    textScale: 2,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
