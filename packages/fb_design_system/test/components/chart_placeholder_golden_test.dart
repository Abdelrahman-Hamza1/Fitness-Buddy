import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 chart placeholder golden matrix',
  fileName: 'chart_placeholder',
  states: {
    'placeholder': (_) => fbGoldenPad(
      FbTimeSeriesChart(
        series: [
          FbSeries(
            points: [
              FbPoint(DateTime(2026, 10), 80),
              FbPoint(DateTime(2026, 10, 8), 79.5),
            ],
          ),
        ],
        range: FbChartRange(
          start: DateTime(2026, 10),
          end: DateTime(2026, 10, 8),
        ),
      ),
    ),
  },
);
