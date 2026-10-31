// Covers: WB-011
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/application/weight_sparkline.dart';
import 'package:flutter_test/flutter_test.dart';

WeighIn w(int day, double kg, {int hour = 9}) => WeighIn(
  id:
      '0199e3c2-5b1a-7000-8000-'
      '${(day * 100 + hour).toString().padLeft(12, '0')}',
  version: 1,
  time: EntryTime(DateTime.utc(2026, 10, day, hour), 0),
  localDate: LocalDate(2026, 10, day),
  kg: kg,
  input: WeighInInput(kg, MassUnit.kilogram),
);
void main() {
  test('last 30 days, last per day, no future points; needs two days', () {
    final date = LocalDate(2026, 10, 31);
    expect(
      sparklineValues([
        w(1, 70),
        w(2, 71),
        w(30, 72),
        w(30, 73, hour: 10),
        w(31, 74),
      ], date),
      [71, 73, 74],
    );
    expect(
      sparklineValues([w(30, 72), w(31, 74)], LocalDate(2026, 10, 30)),
      isEmpty,
    );
    expect(sparklineValues([], date), isEmpty);
  });
}
