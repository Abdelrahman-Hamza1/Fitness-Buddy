import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/components/estimate_marker.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'AI-032 UX-070 UX-040 estimate range sheet golden matrix',
  fileName: 'estimate_range_sheet',
  states: {
    'sheet': (context) => FbSheet(
      title: FbLocalizations.of(context).fbEstimateRangeTitle,
      child: const FbEstimateRangeBody(
        rangeText: '450 to 650 kcal',
        reason: 'The portion size and the oil used were not stated.',
      ),
    ),
  },
);
