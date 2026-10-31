import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String? _assign(List<MealSlot> slots, int h, [int m = 0]) =>
    const SlotAssigner().assign(h * 60 + m, slots, SlotMode.ramadan);

void main() {
  // Fajr 04:58, Maghrib 17:29 (1 Ramadan 1447 in Ramallah).
  final day = RamadanSlots.withPrayerWindows(
    [...DefaultSlots.all, ...RamadanSlots.all],
    fajrMinute: 4 * 60 + 58,
    maghribMinute: 17 * 60 + 29,
  );

  test('DY-012 windows follow the prayer times', () {
    final suhoor = day.firstWhere((s) => s.id == RamadanSlots.suhoorId);
    final iftar = day.firstWhere((s) => s.id == RamadanSlots.iftarId);
    expect(suhoor.window, TimeWindow(118, 298));
    expect(iftar.window, TimeWindow(1049, 1229));
    expect(day.firstWhere((s) => s.id == RamadanSlots.snacksId).window, isNull);
    expect(
      day.where((s) => s.mode == SlotMode.normal),
      DefaultSlots.all,
      reason: 'normal slots are untouched',
    );
  });

  test('J11 / T31 suhoor at 03:30 goes to Suhoor, iftar to Iftar, the night '
      'to Snacks', () {
    expect(_assign(day, 3, 30), RamadanSlots.suhoorId);
    expect(_assign(day, 4, 57), RamadanSlots.suhoorId);
    expect(_assign(day, 17, 40), RamadanSlots.iftarId);
    expect(_assign(day, 22), RamadanSlots.snacksId);
    expect(_assign(day, 12), RamadanSlots.snacksId);
  });

  test('a window the user set wins over the prayer times', () {
    final custom = MealSlot(
      id: RamadanSlots.iftarId,
      defaultKey: RamadanSlots.iftarKey,
      sortOrder: 1,
      mode: SlotMode.ramadan,
      window: TimeWindow(18 * 60, 20 * 60),
    );
    final out = RamadanSlots.withPrayerWindows([custom], maghribMinute: 1049);
    expect(out.single.window, TimeWindow(18 * 60, 20 * 60));
    expect(RamadanSlots.followsPrayerTimes(custom), isFalse);
    expect(RamadanSlots.followsPrayerTimes(RamadanSlots.iftar), isTrue);
  });

  test('without prayer times (no city) the fallback windows apply', () {
    final out = RamadanSlots.withPrayerWindows(RamadanSlots.all);
    expect(out[0].window, RamadanSlots.fallbackSuhoor);
    expect(out[1].window, RamadanSlots.fallbackIftar);
  });

  test('a Suhoor window wraps midnight when Fajr is before 03:00', () {
    final out = RamadanSlots.withPrayerWindows([
      RamadanSlots.suhoor,
    ], fajrMinute: 2 * 60);
    expect(out.single.window, TimeWindow(23 * 60, 2 * 60));
  });
}
