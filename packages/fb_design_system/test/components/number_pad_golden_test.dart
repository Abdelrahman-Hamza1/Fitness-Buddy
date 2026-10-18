import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'AI-040 UX-070 UX-040 number pad golden matrix',
  fileName: 'number_pad',
  states: {
    'decimal': (_) => FbNumberPad(onKey: (_) {}, onDone: () {}),
    'integer only': (_) =>
        FbNumberPad(allowDecimal: false, onKey: (_) {}, onDone: () {}),
  },
);
