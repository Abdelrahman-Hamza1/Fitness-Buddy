import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';
import '../helpers/measurement.dart';

void main() {
  List<Measurement> onDays(List<int> days, List<double> values) => [
    for (var i = 0; i < days.length; i++)
      measuredOn(dayN(days[i]), values[i], id: measurementId(i)),
  ];

  test('WB-041 a series has no trend below 5 points and a smoothed trend '
      'from 5', () {
    expect(MeasurementSeries.minTrendPoints, 5);
    final empty = MeasurementSeries.of(const []);
    expect(empty.points, isEmpty);
    expect(empty.trend, isNull);
    expect(empty.latest, isNull);
    expect(empty.first, isNull);
    expect(empty.change, isNull);

    final four = MeasurementSeries.of(onDays([0, 7, 14, 21], [95, 94, 93, 92]));
    expect(four.points, hasLength(4));
    expect(four.dayChoices, hasLength(4));
    expect(four.trend, isNull);
    expect(four.first!.value, 95);
    expect(four.latest!.value, 92);
    expect(four.change, -3);

    final values = <double>[95, 94, 93.5, 93, 92];
    final days = [0, 7, 14, 21, 28];
    final five = MeasurementSeries.of(onDays(days, values).reversed);
    expect(five.points.map((m) => m.value), values);
    final trend = five.trend!;
    expect(trend, hasLength(5));
    final expected = smoothDaily([
      for (var i = 0; i < 5; i++) (dayN(days[i]), values[i]),
    ], TrendWeightConfig.standard);
    expect(trend.map((p) => p.trend), expected);
    expect(trend.map((p) => p.localDate), days.map(dayN));
    expect(trend.first.measurementId, measurementId(0));
    expect(() => trend.add(trend.first), throwsUnsupportedError);
    expect(five.points.clear, throwsUnsupportedError);
    expect(five.dayChoices.clear, throwsUnsupportedError);
    // A custom smoothing config is honoured.
    final fast = MeasurementSeries.of(
      onDays(days, values),
      config: TrendWeightConfig(halfLifeDays: 1, maxAlpha: 1),
    );
    expect(fast.trend!.last.trend, closeTo(92, 0.01));

    // Trend points compare by value.
    final point = trend.first;
    expect(
      point,
      MeasurementTrendPoint(
        localDate: point.localDate,
        measurementId: point.measurementId,
        trend: point.trend,
      ),
    );
    expect(point.hashCode, trend.first.hashCode);
    expect(point == trend[1], isFalse);
  });

  test('WB-041 5 entries spanning fewer than 5 days show a trend', () {
    final series = MeasurementSeries.of(
      onDays([0, 0, 1, 1, 2], [95, 96, 94, 97, 93]),
    );
    expect(series.points, hasLength(5));
    expect(series.dayChoices, hasLength(3));
    expect(series.trend, hasLength(3));
  });

  test('WB-041 several entries on one day are all points; the earliest feeds '
      'the trend', () {
    final late = measuredOn(day0, 96, id: measurementId(1), hour: 20);
    final early = measuredOn(day0, 95, id: measurementId(2), hour: 6);
    // Same time: the smaller ID wins.
    final tieA = measuredOn(dayN(1), 94, id: measurementId(3));
    final tieB = measuredOn(dayN(1), 93, id: measurementId(4));
    final series = MeasurementSeries.of([
      late,
      tieB,
      early,
      tieA,
      measuredOn(dayN(2), 92, id: measurementId(5)),
    ]);
    expect(series.points, [early, late, tieA, tieB, series.points.last]);
    expect(series.dayChoices.map((m) => m.id), [
      measurementId(2),
      measurementId(3),
      measurementId(5),
    ]);
    expect(series.trend!.first.trend, 95);
    expect(series.trend!.first.measurementId, measurementId(2));
  });

  test('WB-042 body fat is a percent series', () {
    final bodyFat = MeasurementTypeRef.builtIn(MeasurementKind.bodyFat);
    final series = MeasurementSeries.of([
      for (var i = 0; i < 5; i++)
        measuredOn(
          dayN(i * 7),
          24.0 - i,
          id: measurementId(i),
          type: bodyFat,
          unit: MeasurementUnit.percent,
        ),
    ]);
    expect(bodyFat.kind.isLength, isFalse);
    expect(
      series.points.every((m) => m.input.unit == MeasurementUnit.percent),
      isTrue,
    );
    expect(series.latest!.value, 20);
    expect(series.change, -4);
    expect(series.trend!.every((p) => p.trend >= 20 && p.trend <= 24), isTrue);
  });
}
