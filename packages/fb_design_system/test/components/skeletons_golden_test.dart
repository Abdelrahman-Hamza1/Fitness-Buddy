import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-051 UX-070 UX-040 skeletons golden matrix',
  fileName: 'skeletons',
  states: {
    'line': (_) => fbGoldenPad(const FbSkeleton.line()),
    'short line': (_) => fbGoldenPad(const FbSkeleton.line(width: 120)),
    'box': (_) => fbGoldenPad(const FbSkeleton.box(width: 56, height: 56)),
    'card': (_) => fbGoldenPad(const FbSkeleton.card()),
  },
);
