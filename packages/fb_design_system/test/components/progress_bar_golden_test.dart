import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'HM-001 UX-070 UX-040 progress bar golden matrix',
  fileName: 'progress_bar',
  states: {
    'empty': (_) => fbGoldenPad(const FbProgressBar(value: 0, target: 2000)),
    'half': (_) => fbGoldenPad(const FbProgressBar(value: 1000, target: 2000)),
    'full': (_) => fbGoldenPad(const FbProgressBar(value: 2000, target: 2000)),
    'over': (_) => fbGoldenPad(const FbProgressBar(value: 2400, target: 2000)),
  },
);
