import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 card golden matrix',
  fileName: 'card',
  states: {
    'static': (_) =>
        fbGoldenPad(const FbCard(child: Text('Chicken and rice, 520 kcal'))),
    'tappable': (_) => fbGoldenPad(
      FbCard(onTap: () {}, child: const Text('Chicken and rice, 520 kcal')),
    ),
    'long text': (_) => fbGoldenPad(
      const FbCard(
        child: Text('A long description that wraps at large text sizes'),
      ),
    ),
  },
);
