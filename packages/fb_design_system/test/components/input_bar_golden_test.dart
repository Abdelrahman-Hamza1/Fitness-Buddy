import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-030 UX-070 UX-040 input bar golden matrix',
  fileName: 'input_bar',
  states: {
    'full': (_) => fbGoldenPad(
      FbInputBar(
        hint: 'Tell Buddy what you ate',
        onTap: () {},
        onCamera: () {},
        onBarcode: () {},
      ),
    ),
    'text only': (_) =>
        fbGoldenPad(FbInputBar(hint: 'Tell Buddy what you ate', onTap: () {})),
    'long hint': (_) => fbGoldenPad(
      FbInputBar(
        hint: 'Tell Buddy what you ate, weighed or want to log later',
        onTap: () {},
        onCamera: () {},
        onBarcode: () {},
      ),
    ),
  },
);
