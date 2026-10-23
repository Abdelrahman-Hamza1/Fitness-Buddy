import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Stable identity used by TodayScreen's day pager.
Finder dayPage(LocalDate date) => find.byKey(ValueKey<LocalDate>(date));

/// The total in the requested day, including empty and historical days.
Finder dayNumber(LocalDate date) =>
    find.descendant(of: dayPage(date), matching: find.byType(FbBigNumber));

/// The requested page has arrived and rendered its loaded sliver list.
/// Meals below the viewport need not be mounted by SliverList.builder.
bool showsLoadedDay(WidgetTester tester, LocalDate date) {
  final page = dayPage(date);
  final pager = find.byType(PageView);
  if (page.evaluate().length != 1 || pager.evaluate().length != 1) return false;
  final controller = tester.widget<PageView>(pager).controller!;
  return !controller.position.isScrollingNotifier.value &&
      (tester.getCenter(page).dx - tester.getCenter(pager).dx).abs() < 1 &&
      dayNumber(date).evaluate().length == 1 &&
      find
          .descendant(of: page, matching: find.byType(SlotHeaderTile))
          .evaluate()
          .isNotEmpty;
}

/// Waits for local UI/data work without settling pulsing skeletons.
Future<void> waitForToday(
  WidgetTester tester,
  bool Function() done,
  String reason,
) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > const Duration(seconds: 30)) {
      fail('Timed out waiting for $reason');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Reveal lazy rows in the day's vertical list, never the horizontal pager.
/// Start at the top because a previous check may have scrolled past the row.
Future<void> revealDayWidget(
  WidgetTester tester,
  Finder target,
  LocalDate date, {
  bool interactive = true,
}) async {
  final pager = tester.widget<PageView>(find.byType(PageView));
  await waitForToday(
    tester,
    () =>
        !pager.controller!.position.isScrollingNotifier.value &&
        dayPage(date).evaluate().isNotEmpty &&
        (tester.getCenter(dayPage(date)).dx -
                    tester.getCenter(find.byType(PageView)).dx)
                .abs() <
            1,
    'the pager to reach $date',
  );
  await tester.pump();
  bool visible() {
    if (target.evaluate().isEmpty) return false;
    // Display-only widgets can have blank space at their centre. Hit testing
    // is meaningful for a tap/swipe target, not for reading the day's total.
    return interactive
        ? target.hitTestable().evaluate().isNotEmpty
        : tester
              .getRect(find.byType(PageView))
              .contains(tester.getCenter(target));
  }

  if (visible()) return;
  final scrollView = find.descendant(
    of: dayPage(date),
    matching: find.byType(CustomScrollView),
  );
  await waitForToday(
    tester,
    () => scrollView.evaluate().length == 1,
    'the scroll view for $date',
  );
  final scrollable = find.descendant(
    of: scrollView,
    matching: find.byType(Scrollable),
  );
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  for (var attempt = 0; attempt < 20; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 50));
      if (visible()) return;
    }
    await tester.drag(scrollView, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Could not reveal $target on $date after 20 scrolls');
}
