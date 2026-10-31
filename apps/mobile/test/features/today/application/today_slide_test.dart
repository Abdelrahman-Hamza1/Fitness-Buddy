// Covers: HM-009
import 'package:fb_mobile/features/today/application/today_slide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection survives subscriptions and resets with the app session', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(todaySlideProvider), 0);
    final listener = c.listen(todaySlideProvider, (_, _) {});
    c.read(todaySlideProvider.notifier).select(2);
    listener.close();
    expect(c.read(todaySlideProvider), 2);
    final fresh = ProviderContainer();
    addTearDown(fresh.dispose);
    expect(fresh.read(todaySlideProvider), 0);
  });
}
