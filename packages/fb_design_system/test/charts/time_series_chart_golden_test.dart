import 'dart:math' as math;

import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

final DateTime _t0 = DateTime.utc(2026, 6);
final DateTime _today = DateTime.utc(2026, 9);

/// 92 days of weigh-ins: a slow loss with daily noise, every few days a gap.
final List<FbPoint> _raw = [
  for (var i = 0; i < 92; i++)
    if (i % 5 != 3)
      FbPoint(
        _t0.add(Duration(days: i)),
        92 - i * 0.05 + math.sin(i * 1.7) * 0.6,
        key: i,
      ),
];

final List<FbPoint> _trend = [
  for (var i = 0; i < 92; i++)
    FbPoint(_t0.add(Duration(days: i)), 92.2 - i * 0.05),
];

final FbSeries _projection = FbSeries(
  style: FbSeriesStyle.dashedLine,
  points: [
    FbPoint(_today, 87.6),
    FbPoint(_today.add(const Duration(days: 30)), 86.1),
  ],
);

final FbBand _cone = FbBand(
  points: [
    FbBandPoint(_today, lower: 87.6, upper: 87.6),
    FbBandPoint(_today.add(const Duration(days: 30)), lower: 85.4, upper: 86.8),
  ],
);

String _value(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

String _date(DateTime at, FbTimeStep step) => '${at.day}/${at.month}';

FbTimeSeriesChart _chart({
  FbPointRef? selected,
  FbGoalLine? goal,
  bool overlays = true,
}) => FbTimeSeriesChart(
  series: [
    FbSeries(
      points: _raw,
      style: FbSeriesStyle.points,
      tone: FbSeriesTone.muted,
      selectable: true,
    ),
    FbSeries(points: _trend, style: FbSeriesStyle.line),
    if (overlays) _projection,
  ],
  range: FbChartRange(start: _t0, end: _today.add(const Duration(days: 30))),
  bands: overlays ? [_cone] : const [],
  goal: goal,
  periods: overlays
      ? [
          FbPeriod(start: _t0, end: DateTime.utc(2026, 7, 15), label: 'Cut'),
          FbPeriod(
            start: DateTime.utc(2026, 7, 16),
            end: _today.add(const Duration(days: 30)),
            tone: FbPeriodTone.phaseB,
            label: 'Lose weight',
          ),
          FbPeriod(
            start: DateTime.utc(2026, 8, 10),
            end: DateTime.utc(2026, 8, 25),
            tone: FbPeriodTone.highlight,
            label: 'Ramadan',
          ),
        ]
      : const [],
  selected: selected,
  formatValue: _value,
  formatDate: _date,
);

Future<void> main() => fbGoldenMatrix(
  'IN-004 the chart draws points, a trend line, a dashed projection, a cone '
  'band, a goal line and labelled periods',
  fileName: 'time_series_chart',
  states: {
    'full overlays': (_) =>
        fbGoldenPad(_chart(goal: const FbGoalLine(value: 86, label: 'Goal'))),
    'selection': (_) => fbGoldenPad(
      _chart(selected: const FbPointRef(series: 0, key: 40), overlays: false),
    ),
    'goal edge marker': (_) => fbGoldenPad(
      _chart(
        goal: const FbGoalLine(value: 75, label: 'Goal 75'),
        overlays: false,
      ),
    ),
    'empty': (_) => fbGoldenPad(
      FbTimeSeriesChart(
        series: const [],
        range: FbChartRange(start: _t0, end: _today),
      ),
    ),
  },
);
