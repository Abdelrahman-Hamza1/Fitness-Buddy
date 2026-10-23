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
}) => SizedBox(
  width: _width,
  height: height,
  child: ProviderScope(
    overrides: <Override>[
      ...fakeToday(days: days),
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
    'DY-021 today: expanded item (read-only)',
    'today_expanded_item',
    (b, s) => _phone(
      full,
      b,
      s,
      choices: DiaryViewChoices(
        expandedSlotIds: [DefaultSlots.breakfastId],
        expandedEntry: (date: testToday, id: fixtureId(1)),
      ),
      height: _tall,
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
}
