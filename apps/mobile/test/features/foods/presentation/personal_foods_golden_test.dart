import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';

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
}
