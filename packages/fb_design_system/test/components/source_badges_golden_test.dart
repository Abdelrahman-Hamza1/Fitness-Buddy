import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'FD-010 UX-044 UX-070 UX-040 source badges golden matrix',
  fileName: 'source_badges',
  states: {
    'all sources': (_) => fbGoldenPad(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final source in FbSource.values)
            FbSourceBadge(source: source, onTap: () {}),
          const FbEstimateMarker(
            rangeText: '450 to 650 kcal',
            reason: 'Portion size unknown',
          ),
        ],
      ),
    ),
  },
);
