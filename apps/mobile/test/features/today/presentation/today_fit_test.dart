import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/shell/app_shell.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';
import 'support/today_targets_support.dart';

void main() {
  // The design canvas (390 x 844) and the owner's Galaxy A55 at the default
  // display zoom (1080 x 2340 px at 2.625 = 411 x 891 dp; A44 §5 G), each
  // with a 24 dp status bar and a navigation-bar inset: 24 dp for gesture
  // navigation (the A55's default), 48 dp for the 3-button bar.
  for (final (name, size, bottom) in const [
    ('canvas 390x844, gestures', Size(390, 844), 24.0),
    ('canvas 390x844, 3 buttons', Size(390, 844), 48.0),
    ('A55 411x891, gestures', Size(411, 891), 24.0),
    ('A55 411x891, 3 buttons', Size(411, 891), 48.0),
  ]) {
    testWidgets("UX-041 #74 Today's essentials fit one screen without "
        'scrolling ($name)', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1
        ..padding = FakeViewPadding(top: 24, bottom: bottom);
      addTearDown(tester.view.reset);

      final midweek = [
        ate(weekDay(0), 1850),
        ate(weekDay(1), 1850),
        ate(weekDay(3), 2000),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeToday(
            days: {testToday: fullDay(testToday)},
            targets: {testToday: targetsOn(weekDay(4), intake: midweek)},
            setup: SetupStatus.setUp,
          ),
          child: phoneApp(
            AppShell(
              currentIndex: 0,
              onTabSelected: (_) {},
              child: const TodayScreen(),
            ),
            brightness: Brightness.dark,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final screen = Offset.zero & size;
      final viewport = tester.getRect(find.byType(CustomScrollView).first);
      final input = tester.getRect(find.byType(FbInputBar));
      final nav = tester.getRect(find.byType(NavigationBar));
      // The input bar and the nav bar are on screen, in that order.
      expect(screen.contains(input.topLeft), isTrue);
      expect(screen.contains(input.bottomRight), isTrue);
      expect(nav.bottom, lessThanOrEqualTo(size.height));
      expect(input.bottom, lessThanOrEqualTo(nav.top));
      // Above the input bar, inside the scroll viewport, without scrolling.
      expect(viewport.bottom, lessThanOrEqualTo(input.top));

      void fits(Finder finder, String what) {
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThanOrEqualTo(24), reason: '$what top');
        expect(
          rect.bottom,
          lessThanOrEqualTo(viewport.bottom),
          reason: '$what bottom ${rect.bottom} > viewport ${viewport.bottom}',
        );
      }

      fits(find.byType(FbDateHeader), 'the date header');
      fits(find.byType(FbBigNumber), 'the big number');
      fits(find.byType(FbProgressBar), 'the kcal bar');
      fits(
        find.textContaining(RegExp(r'^[\d,]+ / [\d,]+ kcal$')),
        'the eaten / target line',
      );
      fits(find.byType(FbMacroBars), 'the macro bars');
      fits(find.byType(SlotHeaderTile).first, "the first meal's header");
    });
  }
}
