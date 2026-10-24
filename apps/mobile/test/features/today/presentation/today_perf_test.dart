@Tags(['perf'])
library;

import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:fb_mobile/features/today/presentation/day_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../quick_add/presentation/quick_add_support.dart';
import 'support/today_support.dart';

/// 30 entries: eight in each of three meals, six in the last, with a dish of
/// two in each of the first three.
DiaryDay thirtyEntryDay(LocalDate date) {
  const meals = [
    DefaultSlots.breakfastId,
    DefaultSlots.lunchId,
    DefaultSlots.dinnerId,
    DefaultSlots.snacksId,
  ];
  final entries = <DiaryEntry>[];
  for (var n = 0; n < 30; n++) {
    final meal = n < 24 ? n ~/ 8 : 3;
    final inDish = n < 24 && n % 8 < 2;
    entries.add(
      fakeEntry(
        n + 1,
        date: date,
        slotId: meals[meal],
        hour: 7 + meal * 4,
        minute: n % 8 * 5,
        name: 'Food number ${n + 1} with a longer name',
        ar: 'طعام ${n + 1}',
        kcal: 80.0 + n * 7,
        group: inDish ? '${meal + 1}' : null,
      ),
    );
  }
  return fakeDay(date, entries, [
    for (var meal = 0; meal < 3; meal++)
      fakeGroup(meal + 1, date: date, slotId: meals[meal], name: 'Dish $meal'),
  ]);
}

double p95(List<int> micros) {
  final sorted = [...micros]..sort();
  return sorted[(sorted.length * 0.95).ceil() - 1] / 1000;
}

/// The first frame of [page] in a mounted app (build and layout), in µs, over
/// 25 runs; the first 5 are warm-ups.
Future<List<int>> firstFrames(
  WidgetTester tester,
  Widget page, {
  List<Override> overrides = const [],
}) async {
  final show = ValueNotifier(false);
  addTearDown(show.dispose);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: phoneApp(
        ValueListenableBuilder(
          valueListenable: show,
          builder: (_, visible, _) =>
              Scaffold(body: visible ? page : const SizedBox()),
        ),
      ),
    ),
  );
  final times = <int>[];
  for (var i = 0; i < 25; i++) {
    show.value = false;
    await tester.pump();
    final timer = Stopwatch()..start();
    show.value = true;
    await tester.pump();
    timer.stop();
    if (i >= 5) times.add(timer.elapsedMicroseconds);
  }
  return times;
}

/// 30 plain list tiles: what this machine does with a screenful of the same
/// widgets while the other tests run beside it.
Widget get referencePage => ListView.builder(
  itemCount: 30,
  itemBuilder: (_, i) => ListTile(
    leading: const Icon(Icons.circle),
    title: Text('Food number $i with a longer name'),
    subtitle: Text('${100 + i} g'),
    trailing: Text('${80 + i * 7} kcal'),
    onTap: () {},
  ),
);

/// The reference's p95 on a quiet machine, in ms (recorded 2026-10-23).
const double _referenceQuietMs = 30;

void main() {
  for (final (name, expanded, budgetMs) in [
    ('collapsed', false, 60),
    ('all expanded', true, 120),
  ]) {
    testWidgets('A08 perf W1 first frame of a 30-entry page, $name: p95 < '
        '$budgetMs ms', (tester) async {
      usePhone(tester);
      final day = thirtyEntryDay(testToday);
      final overrides = [
        ...fakeToday(days: {testToday: day}),
        if (expanded)
          diaryViewStateProvider.overrideWithBuild(
            (ref, notifier) => DiaryViewChoices(
              expandedSlotIds: [for (final s in DefaultSlots.all) s.id],
            ),
          ),
      ];
      // The budget is for a quiet machine; the tests run in parallel, so it
      // grows with how much slower the reference screen is than when quiet.
      await firstFrames(tester, referencePage); // warms the code up
      final reference = p95(await firstFrames(tester, referencePage));
      final load = max(1, reference / _referenceQuietMs);
      final times = await firstFrames(
        tester,
        DayPage(date: testToday, isToday: true),
        overrides: overrides,
      );
      final ms = p95(times);
      debugPrint(
        'A08 perf W1 $name: p95 ${ms.toStringAsFixed(1)} ms '
        '(20 runs after 5 warm-ups); budget $budgetMs ms x load '
        '${load.toStringAsFixed(2)} (reference ${reference.toStringAsFixed(1)} '
        'ms)',
      );
      expect(ms, lessThan(budgetMs * load));
    });
  }

  // The quick-add chips start only after the day's first data frame has been
  // drawn (D14), so the day's own frame must cost the same with the chip-row
  // model present as without it: the same budget as the collapsed day above.
  // The model answers "loading" until [arrived] flips, like the real one.
  List<Override> chipOverrides(
    LocalDate day,
    ValueNotifier<bool> arrived,
    List<QuickAddChip> chips,
  ) => [
    ...fakeToday(
      days: {testToday: thirtyEntryDay(day)},
      chipsOverride: quickAddChipsProvider.overrideWith((ref, date) {
        void onChange() => ref.invalidateSelf();
        arrived.addListener(onChange);
        ref.onDispose(() => arrived.removeListener(onChange));
        return arrived.value ? AsyncData(chips) : const AsyncLoading();
      }),
    ),
  ];
  final chips = [
    for (var n = 1; n <= 6; n++) fakeFoodChip(n, 'Chip food number $n'),
  ];

  testWidgets('A08 perf W1 still within budget with the chip-row model '
      'present: first frame of a 30-entry page with the row still loading, '
      'p95 < 60 ms x load', (tester) async {
    usePhone(tester);
    final arrived = ValueNotifier(false);
    addTearDown(arrived.dispose);
    await firstFrames(tester, referencePage);
    final reference = p95(await firstFrames(tester, referencePage));
    final load = max(1, reference / _referenceQuietMs);
    final times = await firstFrames(
      tester,
      Column(
        children: [
          Expanded(child: DayPage(date: testToday, isToday: true)),
          QuickAddBar(date: testToday),
        ],
      ),
      overrides: chipOverrides(testToday, arrived, chips),
    );
    final ms = p95(times);
    debugPrint(
      'A08 perf W1 with the chip-row model present: p95 '
      '${ms.toStringAsFixed(1)} ms (20 runs after 5 warm-ups); budget 60 ms x '
      'load ${load.toStringAsFixed(2)} (reference '
      '${reference.toStringAsFixed(1)} ms)',
    );
    expect(ms, lessThan(60 * load));
  });

  testWidgets('A09 perf W1 chip arrival: the frame in which six quick-add '
      'chips arrive under a built 30-entry page, p95 < '
      '$_chipArrivalBudgetMs ms x load', (tester) async {
    usePhone(tester);
    final arrived = ValueNotifier(false);
    addTearDown(arrived.dispose);
    await firstFrames(tester, referencePage);
    final reference = p95(await firstFrames(tester, referencePage));
    final load = max(1, reference / _referenceQuietMs);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ProviderScope(
        overrides: chipOverrides(testToday, arrived, chips),
        child: phoneApp(
          Scaffold(
            body: Column(
              children: [
                Expanded(child: DayPage(date: testToday, isToday: true)),
                QuickAddBar(date: testToday),
              ],
            ),
          ),
        ),
      ),
    );
    final micros = <int>[];
    for (var i = 0; i < 25; i++) {
      arrived.value = false;
      await tester.pump();
      final timer = Stopwatch()..start();
      arrived.value = true;
      await tester.pump();
      timer.stop();
      expect(find.text('Chip food number 1'), findsOneWidget);
      if (i >= 5) micros.add(timer.elapsedMicroseconds);
    }
    final ms = p95(micros);
    debugPrint(
      'A09 perf W1 chip arrival: p95 ${ms.toStringAsFixed(1)} ms (20 runs '
      'after 5 warm-ups); budget $_chipArrivalBudgetMs ms x load '
      '${load.toStringAsFixed(2)} (reference ${reference.toStringAsFixed(1)} '
      'ms)',
    );
    expect(ms, lessThan(_chipArrivalBudgetMs * load));
  });
}

/// The budget of the frame in which the chips arrive, in ms on a quiet
/// machine (A09 D14). Printed numbers decide it; see the test's output.
const int _chipArrivalBudgetMs = 40;
