import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:flutter_test/flutter_test.dart';

final LocalDate _day = LocalDate(2026, 10, 25);

WeighIn _weighIn(String suffix, int hour, int minute, int offsetMin) {
  const input = WeighInInput(90, MassUnit.kilogram);
  return WeighIn(
    id: '0199e3c2-5b1a-7000-8000-0000000000$suffix',
    version: 1,
    time: EntryTime.local(
      LocalDateTime(_day, hour: hour, minute: minute),
      offsetMin,
    ),
    localDate: _day,
    kg: input.kg,
    input: input,
  );
}

void main() {
  test('WB-020 chart points follow the local wall clock after a clock '
      'rollback, not the UTC order the repository returns', () {
    // 02:50 at +03:00 (23:50 UTC) happened before 02:10 at +02:00
    // (00:10 UTC): the clocks went back an hour in between.
    final before = _weighIn('a1', 2, 50, 180);
    final after = _weighIn('b2', 2, 10, 120);
    expect(
      before.time.occurredAtUtc.isBefore(after.time.occurredAtUtc),
      isTrue,
    );
    final ordered = chartOrdered([before, after]);
    expect(ordered, [after, before]);
    final xs = [for (final w in ordered) chartTimeOf(w)];
    expect(xs.first.isBefore(xs.last), isTrue);
    expect(chartTimeOf(before), DateTime.utc(2026, 10, 25, 2, 50));
  });

  test('equal wall-clock times order by instant, then ID', () {
    final plus3 = _weighIn('c3', 7, 0, 180);
    final plus2 = _weighIn('d4', 7, 0, 120);
    final twin = _weighIn('c2', 7, 0, 180);
    expect(chartOrdered([plus2, plus3, twin]), [twin, plus3, plus2]);
  });
}
