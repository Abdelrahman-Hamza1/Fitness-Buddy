import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 date header golden matrix',
  fileName: 'date_header',
  states: {
    'both enabled': (_) =>
        FbDateHeader(label: 'Yesterday', onPrevious: () {}, onNext: () {}),
    'next disabled': (_) => FbDateHeader(label: 'Today', onPrevious: () {}),
    'long label': (_) => FbDateHeader(
      label: 'Wednesday, 30 September 2026',
      onPrevious: () {},
      onNext: () {},
    ),
  },
);
