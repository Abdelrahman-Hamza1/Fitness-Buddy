import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WB-020 windows for 1M/3M/6M/1Y end today on calendar months '
      '(31 March − 1 month = 28/29 February)', () {
    final today = LocalDate(2027, 3, 31);
    final first = LocalDate(2020, 1, 1);
    DateTime start(GraphRange r) =>
        ChartWindow.of(r, today, firstDate: first).start;
    expect(start(GraphRange.m1), DateTime.utc(2027, 2, 28));
    expect(
      ChartWindow.of(GraphRange.m1, LocalDate(2028, 3, 31)).start,
      DateTime.utc(2028, 2, 29),
    );
    expect(start(GraphRange.m3), DateTime.utc(2026, 12, 31));
    expect(start(GraphRange.m6), DateTime.utc(2026, 9, 30));
    expect(start(GraphRange.y1), DateTime.utc(2026, 3, 31));
    final w = ChartWindow.of(GraphRange.m3, today, firstDate: first);
    expect(w.end, DateTime.utc(2027, 4));
    expect(w.panMin, DateTime.utc(2019, 12, 25));
    expect(w.pans, isTrue);
  });

  test('WB-020 All spans the first weigh-in to today, at least one month, '
      'and does not pan', () {
    final today = LocalDate(2027, 3, 31);
    final all = ChartWindow.of(
      GraphRange.all,
      today,
      firstDate: LocalDate(2025, 6, 2),
    );
    expect(all.start, DateTime.utc(2025, 6, 2));
    expect(all.pans, isFalse);
    final recent = ChartWindow.of(
      GraphRange.all,
      today,
      firstDate: LocalDate(2027, 3, 20),
    );
    expect(recent.start, DateTime.utc(2027, 2, 28));
  });

  test('WB-020 a panned window keeps its length inside the pan bounds; a '
      'projection adds future room', () {
    final today = LocalDate(2027, 3, 31);
    final first = LocalDate(2026, 1, 1);
    final base = ChartWindow.of(GraphRange.m1, today, firstDate: first);
    final span = base.end.difference(base.start);
    final panned = ChartWindow.of(
      GraphRange.m1,
      today,
      firstDate: first,
      panStart: DateTime.utc(2026, 6, 10, 12),
    );
    expect(panned.start, DateTime.utc(2026, 6, 10, 12));
    expect(panned.end.difference(panned.start), span);
    final tooFar = ChartWindow.of(
      GraphRange.m1,
      today,
      firstDate: first,
      panStart: DateTime.utc(2020),
    );
    expect(tooFar.start, DateTime.utc(2025, 12, 25));
    final future = ChartWindow.of(
      GraphRange.m1,
      today,
      firstDate: first,
      panStart: DateTime.utc(2030),
    );
    expect(future.end, base.end);
    final withProjection = ChartWindow.of(
      GraphRange.m1,
      today,
      firstDate: first,
      futureDays: 10,
    );
    expect(withProjection.end, DateTime.utc(2027, 4, 11));
  });
}
