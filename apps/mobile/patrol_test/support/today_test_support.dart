// Test support: RenderAnimatedSize.state is exposed for tests only.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Waits until the quick-add chip row (A09b) has settled, or is absent.
///
/// The row grows in (an `AnimatedSize`) once history exists and chips are
/// ranked, which is right after a journey logs its first foods. The day's
/// viewport ends at the row's top, so while it grows the viewport shrinks
/// and a row at the bottom edge ends up under the chip row: a tap there lands
/// on a chip (and logs an extra entry) or on nothing. So a tap on a day row
/// must come after this. "Settled" is: no `AnimatedSize` of the bar still
/// animating, its suggestions loaded, and the sizes of the bar and of the day
/// pager unchanged for [stableFrames] frames in a row. Bounded: fails with the
/// sizes it saw.
Future<void> settleQuickAddRow(
  WidgetTester tester, {
  int stableFrames = 3,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final bar = find.byType(QuickAddBar);
  final pager = find.byType(PageView);
  String sizes() => [
    for (final finder in [bar, pager])
      if (finder.evaluate().length == 1)
        '${tester.getSize(finder)}'
      else
        'absent',
  ].join(' / ');
  bool animating() => find
      .descendant(of: bar, matching: find.byType(AnimatedSize))
      .evaluate()
      .any(
        (e) =>
            (e.renderObject! as RenderAnimatedSize).state !=
            RenderAnimatedSizeState.stable,
      );
  // Suggestions that are still being worked out show no row yet, but will in
  // a moment: wait for them too, at most [timeout] (a row that never loads
  // is not this helper's failure; the sizes below still have to be stable).
  bool loading() {
    final found = bar.evaluate();
    if (found.length != 1) return false;
    final date = (found.single.widget as QuickAddBar).date;
    return ProviderScope.containerOf(found.single)
        .read(quickAddChipsProvider(date))
        .isLoading;
  }

  final watch = Stopwatch()..start();
  while (loading() && watch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  watch
    ..reset()
    ..start();
  var last = sizes();
  var stable = 0;
  while (stable < stableFrames) {
    if (watch.elapsed > timeout) {
      fail(
        'Timed out waiting for the quick-add row to settle; '
        'sizes (bar / pager) $last, still animating: ${animating()}',
      );
    }
    await tester.pump(const Duration(milliseconds: 50));
    final now = sizes();
    stable = (now == last && !animating()) ? stable + 1 : 0;
    last = now;
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
  // A chip row that is still growing in changes the day's viewport under the
  // check below (A09b): look only at a settled layout.
  await settleQuickAddRow(tester);
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
    await settleQuickAddRow(tester);
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
