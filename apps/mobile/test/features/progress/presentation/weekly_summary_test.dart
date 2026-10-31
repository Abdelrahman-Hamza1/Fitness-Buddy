import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:fb_mobile/features/progress/presentation/weekly_summary_card.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
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
  testWidgets("IN-001 SC-5 A39a D2 Progress opens on this week's summary "
      'with the check-in inside it and a way to past weeks; offline', (
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
    // This week (17–23 Oct) at the top, before the period selector.
    final summary = find.byKey(
      ValueKey('weekly-summary-${LocalDate(2026, 10, 17)}'),
    );
    expect(summary, findsOneWidget);
    expect(
      tester.getTopLeft(summary).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('progress-period-week')))
            .dy,
      ),
    );
    // Backlog #231: the check-in sits in the summary card.
    expect(
      find.descendant(
        of: find.byType(WeeklySummaryCard),
        matching: find.byType(CheckInCard),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('weekly-summary-past')));
    await tester.pumpAndSettle();
    expect(navigator.pushed.single, isA<WeeklySummaryRoute>());
    expect(
      (navigator.pushed.single as WeeklySummaryRoute).start,
      LocalDate(2026, 10, 10),
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

  testWidgets('A40 review 7 a week with only a workout, before any other '
      'data, is reachable', (tester) async {
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
