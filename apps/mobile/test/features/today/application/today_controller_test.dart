import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DY-001 HM-009 midnight plus one second refreshes today; '
      'past date stays fixed', (tester) async {
    final clock = ManualClock(DateTime.utc(2026, 10, 23, 23, 59, 59));
    final c = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(clock)],
    );
    addTearDown(c.dispose);
    final seen = <LocalDate>[];
    c.listen(todayProvider, (_, next) {
      if (next case AsyncData(:final value)) seen.add(value);
    }, fireImmediately: true);
    await tester.pump();
    final old = LocalDate(2026, 10, 23);
    final next = old.plusDays(1);
    final controller = c.read(todayControllerProvider.notifier);
    expect(c.read(todayControllerProvider), isNull);
    expect(seen.last, old);
    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(seen.last, old);
    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(seen.last, next);
    controller.onTodayChanged(next);
    expect(c.read(todayControllerProvider), isNull);
    controller.previous();
    expect(c.read(todayControllerProvider), old);
    clock.advance(const Duration(days: 1));
    await tester.pump(const Duration(days: 1));
    controller.onTodayChanged(next.plusDays(1));
    expect(c.read(todayControllerProvider), old);
    controller.next();
    expect(c.read(todayControllerProvider), next);
    controller.next();
    expect(c.read(todayControllerProvider), isNull);
    controller.next();
    expect(c.read(todayControllerProvider), isNull);
    controller.goTo(old.plusDays(-10000));
    expect(c.read(todayControllerProvider), next.plusDays(1 - 3650));
    c.dispose();
  });
}
