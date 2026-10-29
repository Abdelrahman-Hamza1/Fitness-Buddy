import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/support/diary_fixtures.dart' show fixtureId;
import 'support/today_support.dart';

/// Phone size of a screen golden cell, in dp.
const double _width = 360;
const double _height = 640;

/// Tall enough for the opened rows at text scale 2.0.
const double _tall = 1300;

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
    overrides: <Override>[
      ...fakeToday(days: days, units: units),
      if (choices != null)
        diaryViewStateProvider.overrideWithBuild((ref, notifier) => choices),
    ],
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
  final lunch = DiaryViewChoices(expandedSlotIds: [DefaultSlots.lunchId]);

  await _screenGolden(
    'HM-007 UX-050 today: empty day',
    'today_empty_day',
    (b, s) => _phone({}, b, s),
  );
  await _screenGolden(
    'HM-007 DY-020 today: full day',
    'today_full_day',
    (b, s) => _phone(full, b, s),
  );
  await _screenGolden(
    'HM-007 DY-020 today: full day, lunch expanded',
    'today_full_day_lunch_expanded',
    (b, s) => _phone(full, b, s, choices: lunch, height: _tall),
  );
  await _screenGolden(
    'LC-010 DY-020 today: full day, imperial',
    'today_full_day_imperial',
    (b, s) => _phone(
      full,
      b,
      s,
      choices: lunch,
      height: _tall,
      units: UnitSystem.imperial,
    ),
  );
  await _screenGolden(
    'DY-021 today: expanded item (editable)',
    'today_expanded_item',
    (b, s) => _phone(
      full,
      b,
      s,
      choices: DiaryViewChoices(
        expandedSlotIds: [DefaultSlots.breakfastId],
        expandedEntry: (date: testToday, id: fixtureId(1)),
      ),
      height: 2300,
    ),
  );
  await _screenGolden(
    'DY-024 today: dish group collapsed (open: lunch expanded)',
    'today_dish_group_collapsed',
    (b, s) => _phone(
      full,
      b,
      s,
      choices: DiaryViewChoices(
        expandedSlotIds: [DefaultSlots.lunchId],
        collapsedGroupIds: [fixtureId(901)],
      ),
      height: _tall,
    ),
  );
  await _screenGolden(
    'DY-022 move-to-meal sheet',
    'move_to_slot_sheet',
    (b, s) => SizedBox(
      width: _width,
      height: 420,
      child: phoneApp(
        Scaffold(
          bottomSheet: Builder(
            builder: (context) => FbSheet(
              title: context.l10n.diaryMoveTitle,
              child: MoveToSlotList(
                slots: DefaultSlots.all,
                currentSlotId: DefaultSlots.breakfastId,
                onPick: (_) {},
              ),
            ),
          ),
        ),
        brightness: b,
        textScale: s,
      ),
    ),
  );
  // The estimate the user corrected: both badges, the range, the assumptions
  // and the editable chips and buttons (AI-072).
  final edited = {
    testToday: fakeDay(testToday, [
      fakeEntry(
        1,
        date: testToday,
        name: 'Falafel plate',
        ar: 'فلافل',
        kcal: 450,
        minute: 30,
        source: FoodSource.estimate,
        edited: true,
        range: EstimateRange(380, 520),
        assumptions: ['a1:oil:most', 'a1:share:1/2'],
        extras: {NutrientKey.sugar: 1.6, NutrientKey.sodium: 322},
      ),
    ]),
  };
  await _screenGolden(
    'DY-021 AI-072 today: expanded item (editable, edited by you, assumptions)',
    'today_expanded_item_edited',
    (b, s) => _phone(
      edited,
      b,
      s,
      choices: DiaryViewChoices(
        expandedSlotIds: [DefaultSlots.breakfastId],
        expandedEntry: (date: testToday, id: fixtureId(1)),
      ),
      height: 2300,
    ),
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
  await _sheetGolden(
    'AI-072 nutrient override sheet',
    'nutrient_override_sheet',
    (title) => NutrientOverrideSheet(entry: pita, field: NutrientField.protein),
    title: 'Edit Protein',
    overrides: [
      entryProvider(pita.id).overrideWith((ref) => Stream.value(pita)),
    ],
    heights: (680, 900),
  );

  final yesterday = {testYesterday: fullDay(testYesterday)};
  final breakfast = fakeView(yesterday[testYesterday]!).layout.sections
      .firstWhere((s) => s.key == DefaultSlots.breakfastId);
  await _sheetGolden(
    'DY-023 copy meal sheet',
    'copy_meal_sheet',
    (title) => CopyMealSheet(section: breakfast, date: testYesterday),
    title: 'Copy Breakfast',
    overrides: fakeToday(days: yesterday),
    heights: (260, 420),
  );
  await _sheetGolden(
    'DY-023 save meal sheet',
    'save_meal_sheet',
    (title) => SaveMealSheet(section: breakfast, date: testYesterday),
    title: 'Save as meal',
    overrides: fakeToday(days: yesterday),
    heights: (280, 360),
  );
}
