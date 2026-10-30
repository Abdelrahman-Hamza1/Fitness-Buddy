import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/progress/application/measurement_graph_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../body/support/measurement_harness.dart';

Measurement _at(int n, EntryTime time) => Measurement(
  id: mId(n),
  version: 1,
  type: waistRef,
  time: time,
  localDate: time.localDate,
  value: 90,
  input: const MeasurementInput(90, MeasurementUnit.cm),
);

void main() {
  test('a measurement graph orders points by wall-clock x across a DST '
      'rollback', () {
    // 02:50 at +03:00 is 23:50Z the day before; 02:10 at +02:00 (after the
    // clocks went back) is 00:10Z: later in UTC, earlier on the wall clock.
    final day = LocalDate(2026, 10, 25);
    final beforeChange = _at(
      1,
      EntryTime.local(LocalDateTime(day, hour: 2, minute: 50), 180),
    );
    final afterChange = _at(
      2,
      EntryTime.local(LocalDateTime(day, hour: 2, minute: 10), 120),
    );
    expect(
      afterChange.time.occurredAtUtc.isAfter(beforeChange.time.occurredAtUtc),
      isTrue,
    );
    final ordered = measurementChartOrdered([beforeChange, afterChange]);
    expect(ordered.map((m) => m.id), [mId(2), mId(1)]);
    expect(
      measurementChartTime(ordered.first),
      DateTime.utc(2026, 10, 25, 2, 10),
    );
    // Same wall clock: the instant, then the ID.
    final same = _at(
      3,
      EntryTime.local(LocalDateTime(day, hour: 2, minute: 10), 180),
    );
    expect(measurementChartOrdered([afterChange, same]).map((m) => m.id), [
      mId(3),
      mId(2),
    ]);
  });
}
