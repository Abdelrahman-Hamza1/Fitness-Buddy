import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/workouts/application/workout_views.dart'
    show workoutPlanProvider;
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;
import '../support/progress_support.dart';

void _tallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 3200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

FbIconButton _button(WidgetTester tester, String key) =>
    tester.widget<FbIconButton>(find.byKey(ValueKey(key)));

List<Override> _overrides(AppNavigator? navigator, List<Override> extra) => [
  for (final base in progressOverrides())
    if (!extra.any((o) => o.origin == base.origin)) base,
  appNavigatorProvider.overrideWithValue(navigator ?? _GoNavigator()),
  ...extra,
];

/// The Progress overrides with the real weekly workout summary over a
/// sessions stream that fails while [fail] says so (A63 review: Try again
/// must re-read the failed source, not only the derived summary).
List<Override> _failingSessions(bool Function() fail) => [
  for (final base in progressOverrides())
    if (base.origin != weeklyWorkoutSummaryProvider &&
        base.origin != allWorkoutSessionsProvider)
      base,
  appNavigatorProvider.overrideWithValue(RecordingNavigator()),
  allWorkoutSessionsProvider.overrideWith(
    (ref) => fail()
        ? Stream.error(StateError('synthetic sessions read failure'))
        : Stream.value(const []),
  ),
  workoutPlanProvider.overrideWith((ref) => Stream.value(const {})),
  exerciseLibraryProvider.overrideWith((ref) async => ExerciseLibrary.empty),
];

Widget _screen(
  LocalDate start, {
  List<Override> extra = const [],
  AppNavigator? navigator,
}) => ProviderScope(
  // A new scope per set of overrides (their number can't change).
  key: ValueKey(extra.length),
  retry: (_, _) => null,
  overrides: _overrides(navigator, extra),
  child: phoneApp(WeeklySummaryScreen(start: start)),
);

void main() {
  Text slotText(WidgetTester tester) => tester.widget<Text>(
    find.descendant(
      of: find.byKey(const ValueKey('progress-week-average')),
      matching: find.byType(Text),
    ),
  );

  testWidgets('IN-001 IN-002 D-097 T-P1 week mode: the calories header shows '
      "the week's average / target and the key line, above the chart; tap "
      'opens that week; month mode shows the plain title; offline', (
    tester,
  ) async {
    _tallPhone(tester);
    final navigator = RecordingNavigator();
    await tester.pumpWidget(
      progressApp([
        ...progressOverrides(),
        appNavigatorProvider.overrideWithValue(navigator),
      ]),
    );
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('progress-week-header'));
    expect(header, findsOneWidget);
    expect(slotText(tester).data, isNotEmpty);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('progress-week-line')))
          .data,
      isNotEmpty,
    );
    expect(
      tester.getTopLeft(header).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('progress-calories-chart')))
            .dy,
      ),
    );
    // No sentence card on top: the period bar comes right after the notices.
    expect(find.byKey(const ValueKey('weekly-summary-past')), findsNothing);
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(navigator.pushed.single, isA<WeeklySummaryRoute>());
    expect(
      (navigator.pushed.single as WeeklySummaryRoute).start,
      LocalDate(2026, 10, 17),
    );

    await tester.tap(find.byKey(const ValueKey('progress-period-month')));
    await tester.pumpAndSettle();
    expect(header, findsNothing);
  });

  testWidgets('IN-001 UX-052 A63 PA5 T-P5 a failed workout-summary read with '
      'healthy calories: the header shows the week failure with Try again; '
      'recovery shows the numbers', (tester) async {
    _tallPhone(tester);
    var fail = true;
    await tester.pumpWidget(
      progressApp(
        _overrides(RecordingNavigator(), [
          weeklyWorkoutSummaryProvider.overrideWith(
            (ref, weekStart) async => fail
                ? throw StateError('synthetic workout read failure')
                : const WeeklyWorkoutSummary(sessions: 3, planned: 4, prs: 1),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-calories-chart')), findsOne);
    expect(find.byKey(const ValueKey('progress-week-failed')), findsOne);
    expect(find.byKey(const ValueKey('progress-week-header')), findsOne);
    final failedHeight = tester
        .getSize(find.byKey(const ValueKey('progress-week-header')))
        .height;

    fail = false;
    await tester.tap(find.byKey(const ValueKey('progress-week-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-week-failed')), findsNothing);
    expect(slotText(tester).data, isNotEmpty);
    expect(
      tester.getSize(find.byKey(const ValueKey('progress-week-header'))).height,
      lessThanOrEqualTo(failedHeight),
    );
  });

  testWidgets('IN-001 UX-052 A63 PA5 T-P5 a failed workout sessions read '
      'beneath the real weekly summaries: Try again re-reads the source and '
      'the header shows the numbers', (tester) async {
    _tallPhone(tester);
    var fail = true;
    await tester.pumpWidget(progressApp(_failingSessions(() => fail)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-week-failed')), findsOne);

    fail = false;
    await tester.tap(find.byKey(const ValueKey('progress-week-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-week-failed')), findsNothing);
    expect(slotText(tester).data, isNotEmpty);
  });

  testWidgets('IN-001 D-097 A63 review the week average, "avg" included, is '
      'never clipped: beside the title at 1.0 text, under it at 2.0', (
    tester,
  ) async {
    _tallPhone(tester);
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        progressApp(
          _overrides(RecordingNavigator(), const []),
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(slotText(tester).data, startsWith('avg '));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(const ValueKey('progress-week-average')),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        paragraph.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(paragraph.size.width),
      );
      expect(
        find.byKey(const ValueKey('progress-week-stacked')),
        scale == 1 ? findsNothing : findsOneWidget,
      );
    }
  });

  testWidgets('IN-001 D-097 T-P3 the weekly summary screen shows the week as '
      'a big average and number tiles', (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_screen(LocalDate(2026, 10, 10)));
    await tester.pumpAndSettle();
    final week = find.byKey(
      ValueKey('weekly-summary-${LocalDate(2026, 10, 10)}'),
    );
    expect(week, findsOneWidget);
    expect(
      find.descendant(
        of: week,
        matching: find.byKey(const ValueKey('weekly-summary-average')),
      ),
      findsOne,
    );
    // Workouts (3 of 4) and PRs are tiles, among the numbers.
    expect(find.descendant(of: week, matching: find.byType(Wrap)), findsOne);
    expect(
      find.descendant(
        of: find.descendant(of: week, matching: find.byType(Wrap)),
        matching: find.byType(DecoratedBox),
      ),
      findsAtLeast(2),
    );
  });

  testWidgets('IN-001 past weeks step with ‹ › (route-driven, A40 review '
      '4), from the first data week to this week; a link to a future week '
      'shows this week', (tester) async {
    _tallPhone(tester);
    final navigator = _GoNavigator();
    await tester.pumpWidget(
      _screen(LocalDate(2026, 10, 12), navigator: navigator),
    );
    await tester.pumpAndSettle();
    // 12 Oct is in the week of Saturday 10 Oct.
    expect(
      find.byKey(ValueKey('weekly-summary-${LocalDate(2026, 10, 10)}')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('weekly-summary-next')));
    await tester.tap(find.byKey(const ValueKey('weekly-summary-previous')));
    expect(navigator.went.map((r) => (r as WeeklySummaryRoute).start), [
      LocalDate(2026, 10, 17),
      LocalDate(2026, 10, 3),
    ]);

    await tester.pumpWidget(_screen(LocalDate(2026, 10, 17)));
    await tester.pumpAndSettle();
    expect(_button(tester, 'weekly-summary-next').onPressed, isNull);
    expect(_button(tester, 'weekly-summary-previous').onPressed, isNotNull);

    await tester.pumpWidget(_screen(LocalDate(2026, 12, 1)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('weekly-summary-${LocalDate(2026, 10, 17)}')),
      findsOneWidget,
    );
  });

  testWidgets('IN-001 A40 review 7 A63 PA8 T-P7 a week with only a workout, '
      'before any other data, is reachable from the week screen', (
    tester,
  ) async {
    _tallPhone(tester);
    // Without workouts the first week is 30 May (data from 1 June).
    await tester.pumpWidget(_screen(LocalDate(2026, 5, 30)));
    await tester.pumpAndSettle();
    expect(_button(tester, 'weekly-summary-previous').onPressed, isNull);

    final session = (
      ref: VersionedId('0199e3c2-5b1a-7000-8000-000000000001', 1),
      draft: WorkoutSessionDraft(date: LocalDate(2026, 5, 2), exercises: []),
    );
    await tester.pumpWidget(
      _screen(
        LocalDate(2026, 5, 30),
        extra: [
          allWorkoutSessionsProvider.overrideWith(
            (ref) => Stream.value([session]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(_button(tester, 'weekly-summary-previous').onPressed, isNotNull);
  });

  testWidgets("A40 review 8 last week's summary (the NT-004 link) carries "
      "this week's check-in; an older week doesn't", (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_screen(LocalDate(2026, 10, 10)));
    await tester.pumpAndSettle();
    expect(find.byType(CheckInCard), findsOneWidget);
    await tester.pumpWidget(_screen(LocalDate(2026, 10, 3)));
    await tester.pumpAndSettle();
    expect(find.byType(CheckInCard), findsNothing);
  });
}

/// Records `go` (the summary's ‹ ›).
final class _GoNavigator implements AppNavigator {
  final List<AppRoute> went = [];

  @override
  void go(AppRoute route) => went.add(route);

  @override
  void push(AppRoute route) {}

  @override
  void pop() {}
}
