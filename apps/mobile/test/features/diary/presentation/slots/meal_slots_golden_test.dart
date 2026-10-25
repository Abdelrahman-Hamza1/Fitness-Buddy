import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../today/presentation/support/today_support.dart';
import '../../support/diary_fixtures.dart' show fixtureId;

Widget _phone(
  Widget screen,
  Brightness brightness,
  double scale,
  List<Override> overrides,
) => SizedBox(
  width: 360,
  height: 640,
  child: ProviderScope(
    overrides: overrides,
    child: phoneApp(screen, brightness: brightness, textScale: scale),
  ),
);

Future<void> _golden(
  String name,
  String file,
  Widget screen,
  List<Override> overrides,
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
            child: _phone(screen, brightness, scale, overrides),
          ),
    ],
  ),
);

/// The default meals plus Pre workout (17:00-18:00) and an overnight Late
/// night (22:00-02:00), in order, each at version 1.
final List<SlotRecord> _records = [
  SlotRecord(DefaultSlots.breakfast, 1),
  SlotRecord(DefaultSlots.lunch, 1),
  SlotRecord(DefaultSlots.dinner, 1),
  SlotRecord(
    MealSlot(
      id: fixtureId(70),
      name: 'Pre workout',
      sortOrder: 3,
      window: TimeWindow(17 * 60, 18 * 60),
    ),
    1,
  ),
  SlotRecord(
    MealSlot(
      id: fixtureId(71),
      name: 'Late night',
      sortOrder: 4,
      window: TimeWindow(22 * 60, 2 * 60),
    ),
    1,
  ),
  SlotRecord(
    MealSlot(id: DefaultSlots.snacksId, defaultKey: 'snacks', sortOrder: 5),
    1,
  ),
];

List<Override> _overrides() => [
  ...fakeToday(),
  slotRecordsProvider.overrideWith((ref) => Stream.value(_records)),
  slotEntryCountsProvider.overrideWith(
    (ref) => Stream.value({
      DefaultSlots.breakfastId: 2,
      DefaultSlots.lunchId: 1,
      DefaultSlots.snacksId: 214,
    }),
  ),
  slotContentsProvider(DefaultSlots.snacksId).overrideWith(
    (ref) => Stream.value(
      SlotContents(
        entries: [
          for (var i = 0; i < 214; i++) VersionedId(fixtureId(100 + i), 1),
        ],
        dates: [
          for (var i = 0; i < 160; i++) testToday.plusDays(-i).toString(),
        ],
      ),
    ),
  ),
];

/// A sheet shown under a dimmed screen, as the bottom sheet shows it.
class _Sheet extends StatelessWidget {
  const new(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(alignment: AlignmentDirectional.bottomCenter, child: child),
  );
}

Future<void> main() async {
  await _golden(
    'DY-010 UX-070 meal times',
    'meal_times',
    const MealSlotsScreen(),
    _overrides(),
  );
  await _golden(
    'DY-010 UX-070 meal times: edit sheet',
    'meal_times_edit_sheet',
    _Sheet(SlotEditSheet(record: _records[1])),
    _overrides(),
  );
  await _golden(
    'DY-010 D11 UX-070 meal times: remove sheet',
    'meal_times_remove_sheet',
    _Sheet(SlotRemoveSheet(record: _records.last)),
    _overrides(),
  );
}
