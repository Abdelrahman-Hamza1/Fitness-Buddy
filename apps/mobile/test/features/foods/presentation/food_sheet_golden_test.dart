import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';
import 'support/sheet_support.dart';

/// Width of a golden cell in dp (a phone).
const double _width = 360;

/// The sheet as a phone shows it: LTR only in R1 (`09` §3), [brightness],
/// text [scale], animations off. The cell is tall enough for the whole
/// content at that scale.
Widget _sheet(FoodChoice choice, Brightness brightness, double scale) =>
    SizedBox(
      width: _width,
      height: scale > 1 ? 1240 : 780,
      child: ProviderScope(
        overrides: displayOverrides(choice),
        child: screenApp(
          Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topCenter,
              child: FbSheet(
                child: FoodSheet(pick: FoodPick(row: rowFor(choice))),
              ),
            ),
          ),
          brightness: brightness,
          textScale: scale,
        ),
      ),
    );

Future<void> _sheetGolden(
  String name,
  String file,
  FoodChoice Function() choice,
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
            child: _sheet(choice(), brightness, scale),
          ),
    ],
  ),
);

Future<void> main() async {
  await _sheetGolden(
    'FD-022 LC-005 LC-011 food sheet: a food with a local portion',
    'food_sheet_portion',
    () => catalogChoice(pita),
  );
}
