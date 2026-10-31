import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';

List<Override> _goldenOverrides(
  Map<LocalDate, DiaryDay> days,
  UnitSystem units,
  DiaryViewChoices? choices,
) => [
  ...fakeToday(days: days, units: units),
  if (choices != null)
    diaryViewStateProvider.overrideWithBuild((ref, notifier) => choices),
];

/// Phone size of a screen golden cell, in dp.
const double _width = 360;
const double _height = 640;

/// Today as a phone shows it: LTR only in R1 (`09` §3), [brightness], text
/// [scale], animations off, on [days] with the given session [choices].
Widget _phone(
  Map<LocalDate, DiaryDay> days,
  Brightness brightness,
  double scale, {
  DiaryViewChoices? choices,
  double height = _height,
  UnitSystem units = UnitSystem.metric,
}) => SizedBox(
  width: _width,
  height: height,
  child: ProviderScope(
    overrides: [..._goldenOverrides(days, units, choices)],
    child: phoneApp(
      const TodayScreen(),
      brightness: brightness,
      textScale: scale,
    ),
  ),
);

Future<void> _screenGolden(
  String name,
  String file,
  Widget Function(Brightness brightness, double scale) phone,
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
            child: phone(brightness, scale),
          ),
    ],
  ),
);

/// A sheet [body] on a phone, in a `FbSheet` titled [title], tall enough for
/// its content at text scale 1.0 and 2.0 ([heights]).
Future<void> _sheetGolden(
  String name,
  String file,
  Widget Function(String title) body, {
  required String title,
  required List<Override> overrides,
  required (double, double) heights,
}) => goldenTest(
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
            child: SizedBox(
              width: _width,
              height: scale > 1 ? heights.$2 : heights.$1,
              child: ProviderScope(
                overrides: overrides,
                child: phoneApp(
                  Scaffold(
                    body: Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: FbSheet(title: title, child: body(title)),
                    ),
                  ),
                  brightness: brightness,
                  textScale: scale,
                ),
              ),
            ),
          ),
    ],
  ),
);

Future<void> main() async {
  final full = {testToday: fullDay(testToday)};

  await _screenGolden(
    'HM-007 UX-050 today: empty day',
    'today_empty_day',
    (b, s) => _phone({}, b, s),
  );
  // covers: UX-041 (a clean, not empty, full day)
  await _screenGolden(
    'HM-007 DY-020 today: full day',
    'today_full_day',
    (b, s) => _phone(full, b, s),
  );
  final pita = fakeEntry(
    1,
    date: testToday,
    name: 'Pita bread, white',
    ar: 'خبز عربي',
    kcal: 165,
    grams: 60,
    input: Quantity(1, 'loaf'),
    extras: {NutrientKey.sugar: 1.6, NutrientKey.sodium: 322},
  );
  await _sheetGolden(
    'DY-021 entry amount sheet',
    'entry_amount_sheet',
    (title) => EntryAmountSheet(entry: pita),
    title: pita.food.names.en,
    overrides: [
      entryProvider(pita.id).overrideWith((ref) => Stream.value(pita)),
    ],
    heights: (820, 1000),
  );
}
