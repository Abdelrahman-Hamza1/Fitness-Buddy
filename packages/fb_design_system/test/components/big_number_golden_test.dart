import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'HM-001 UX-070 UX-040 big number golden matrix',
  fileName: 'big_number',
  textScales: const [1, 1.5, 2],
  states: {
    'under': (_) => fbGoldenPad(
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FbBigNumber(value: '1,240', caption: 'kcal left'),
          SizedBox(height: FbSpace.s2),
          FbProgressBar(value: 760, target: 2000),
        ],
      ),
    ),
    'over': (_) => fbGoldenPad(
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FbBigNumber(value: '180', caption: 'kcal over', over: true),
          SizedBox(height: FbSpace.s2),
          FbProgressBar(value: 2180, target: 2000),
        ],
      ),
    ),
    'huge number': (_) => fbGoldenPad(
      const FbBigNumber(value: '12,345,678', caption: 'kcal left'),
    ),
  },
);
