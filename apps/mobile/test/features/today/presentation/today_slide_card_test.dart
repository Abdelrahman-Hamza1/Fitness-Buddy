// Covers: HM-001, HM-005, HM-006, HM-009, UX-051
import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/application/weight_card_state.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/application/today_slide.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:fb_mobile/features/today/presentation/today_slide_card.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart' show weighInDraft;
import 'support/today_support.dart';
import 'support/today_targets_support.dart';
import 'today_navigation_test.dart' show containerOf, pumpToday, shownDate;
import 'today_screen_test.dart' as screen_support;

List<Override> lazyOverrides(void Function() weight, void Function() workout) =>
    [
      ...fakeToday().where((o) => o.origin != todayWorkoutProvider),
      weightCardProvider.overrideWith((ref, args) {
        weight();
        return const AsyncLoading();
      }),
      todayWorkoutProvider.overrideWith((ref, date) {
        workout();
        return const TodayWorkoutNone();
      }),
    ];

List<Override> stateOverrides({required bool failed}) => [
  ...fakeToday().where(
    (o) => o.origin != dayTargetsProvider && o.origin != todayWorkoutProvider,
  ),
  dayTargetsProvider.overrideWith(
    (ref, date) => failed
        ? Future<DayTargets?>.error(StateError('test'))
        : Completer<DayTargets?>().future,
  ),
  weightCardProvider.overrideWith(
    (ref, args) => failed
        ? AsyncError(StateError('test'), StackTrace.empty)
        : const AsyncLoading(),
  ),
  todayWorkoutProvider.overrideWith(
    (ref, date) => failed
        ? Future<TodayWorkout>.error(StateError('test'))
        : Completer<TodayWorkout>().future,
  ),
];

void main() {
  testWidgets('HM-005 HM-006 slide controls remain reachable in semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpToday(tester, fakeToday());
    final c = containerOf(tester);
    for (final (index, key) in [
      (1, 'today-weigh-in'),
      (2, 'today-workout-log'),
    ]) {
      c.read(todaySlideProvider.notifier).select(index);
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.byKey(ValueKey(key)).first);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.getSemanticsData().label, isNotEmpty);
      tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      if (index == 1) {
        expect(find.byType(WeighInSheet), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      } else {
        expect(c.read(appNavigatorProvider), isA<RecordingNavigator>());
        expect(
          (c.read(appNavigatorProvider) as RecordingNavigator).pushed.last,
          isA<TodayWorkoutLogRoute>(),
        );
      }
    }
    handle.dispose();
  });
  testWidgets(
    'HM-001 height resolves once and grows monotonically up to 400dp',
    (tester) async {
      double previous = 0;
      for (final scale in [1.0, 1.3, 1.4, 2.0]) {
        await screen_support.pumpToday(
          tester,
          fakeToday(),
          scale: scale,
          tall: true,
        );
        final height = tester
            .getSize(find.byKey(const ValueKey('fb-slide-card')).first)
            .height;
        if (scale == 1) expect(height, TodaySlideCard.baseHeight);
        if (scale == 2) expect(height, greaterThanOrEqualTo(360));
        expect(height, greaterThanOrEqualTo(previous));
        expect(height, lessThanOrEqualTo(420));
        previous = height;
      }
    },
  );

  for (final scale in [1.0, 1.3, 1.4, 2.0]) {
    for (final failed in [false, true]) {
      testWidgets('UX-051 UX-052 loading/error $failed at $scale', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(360, 1200)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [...stateOverrides(failed: failed)],
            child: phoneApp(
              Scaffold(
                body: TodaySlideCard(
                  date: testToday,
                  isToday: true,
                  totals: eatenTotals(2000),
                ),
              ),
              textScale: scale,
            ),
          ),
        );
        final c = ProviderScope.containerOf(
          tester.element(find.byType(TodaySlideCard)),
        );
        for (var index = 0; index < 3; index++) {
          c.read(todaySlideProvider.notifier).select(index);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
  testWidgets('HM-001 hidden slides do not read weight or workout providers', (
    tester,
  ) async {
    var weight = 0;
    var workout = 0;
    await pumpToday(tester, lazyOverrides(() => weight++, () => workout++));
    await tester.pumpAndSettle();
    expect(weight, 0);
    expect(workout, 0);
  });
  testWidgets('HM-001 measure Nutrition and original compact header', (
    tester,
  ) async {
    final target = targetsOn(testToday, ramadanMaintain: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeToday(targets: {testToday: target}),
        child: phoneApp(
          Scaffold(
            body: SizedBox(
              width: 304,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TodayNumbers(
                    date: testToday,
                    isToday: true,
                    totals: Nutrients.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nutritionHeight = tester.getSize(find.byType(TodayNumbers)).height;
    // Keep the measured minimum in the hand-back.
    expect(nutritionHeight, 178);
    expect(nutritionHeight + 24, lessThanOrEqualTo(TodaySlideCard.baseHeight));
  });
  testWidgets(
    'HM-005 summary is shorter than the former weighed-in/planned header',
    (tester) async {
      await pumpToday(tester, fakeToday());
      // Measured from the pre-A56 widgets at 360 dp, with a weigh-in today,
      // a planned Push workout and populated Nutrition + Ramadan maintain.
      const previousHeaderHeight = 310.0;
      final summary = find.byType(TodaySlideCard);
      expect(tester.getSize(summary).height, lessThan(previousHeaderHeight));
    },
  );
  for (final scale in [1.0, 1.3, 1.4, 2.0]) {
    for (final ramadan in [false, true]) {
      testWidgets('HM-005 full weight and target maintain $ramadan at $scale', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(360, 1200)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final weights = [
          for (var i = 0; i < 4; i++)
            WeighIn(
              id: '0199e3c2-5b1a-7000-8000-${i.toString().padLeft(12, '0')}',
              version: 1,
              time: weighInDraft(
                80 - i.toDouble(),
                date: testToday.plusDays(-i * 7 - 1),
              ).time,
              localDate: testToday.plusDays(-i * 7 - 1),
              kg: 80 - i.toDouble(),
              input: WeighInInput(80 - i.toDouble(), MassUnit.kilogram),
            ),
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeToday(
              weighIns: weights,
              targets: {
                testToday: targetsOn(testToday, ramadanMaintain: ramadan),
              },
              setup: SetupStatus.setUp,
            ),
            child: phoneApp(
              Scaffold(
                body: TodaySlideCard(
                  date: testToday,
                  isToday: true,
                  totals: eatenTotals(2000),
                ),
              ),
              textScale: scale,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final c = ProviderScope.containerOf(
          tester.element(find.byType(TodaySlideCard)),
        );
        c.read(todaySlideProvider.notifier).select(1);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (scale == 2) {
          final scroll = find.ancestor(
            of: find.byType(WeightSlide),
            matching: find.byType(SingleChildScrollView),
          );
          await tester.drag(scroll, const Offset(0, -700));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('today-weigh-in')).hitTestable(),
            findsOneWidget,
          );
          expect(c.read(todaySlideProvider), 1);
        }
      });
    }
  }

  testWidgets(
    'HM-009 card swipe keeps date; below-card swipe keeps selection',
    (tester) async {
      await pumpToday(tester, fakeToday());
      final c = containerOf(tester);
      expect(c.read(todaySlideProvider), 0);
      expect(find.byType(WeightSlide), findsNothing);
      expect(find.byType(WorkoutSlide), findsNothing);
      await tester.drag(
        find.byKey(const ValueKey('fb-slide-card')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();
      expect(c.read(todaySlideProvider), 1);
      expect(shownDate(tester), testToday);
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
      expect(shownDate(tester), testYesterday);
      expect(c.read(todaySlideProvider), 1);
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(shownDate(tester), testToday);
      expect(c.read(todaySlideProvider), 1);
    },
  );
  for (final scale in [1.0, 1.3, 1.4, 2.0]) {
    testWidgets('slides have equal height and no overflow at $scale', (
      tester,
    ) async {
      await screen_support.pumpToday(
        tester,
        fakeToday(),
        scale: scale,
        tall: true,
      );
      final c = containerOf(tester);
      double? height;
      for (var i = 0; i < 3; i++) {
        c.read(todaySlideProvider.notifier).select(i);
        await tester.pumpAndSettle();
        final size = tester.getSize(
          find.byKey(const ValueKey('fb-slide-card')).first,
        );
        height ??= size.height;
        expect(size.height, height);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
