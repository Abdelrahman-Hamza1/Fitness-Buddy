import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'FD-022 AI-040 UX-070 UX-040 amount display golden matrix',
  fileName: 'amount_display',
  states: {
    'idle with edit': (_) => fbGoldenPad(
      FbAmountDisplay(
        amount: '100',
        unit: 'g',
        semanticLabel: 'Amount, 100 g',
        onTap: () {},
      ),
    ),
    'editing': (_) => fbGoldenPad(
      FbAmountDisplay(
        amount: '1.5',
        unit: 'loaves',
        semanticLabel: 'Amount, 1.5 loaves',
        active: true,
        onTap: () {},
      ),
    ),
    'long unit': (_) => fbGoldenPad(
      FbAmountDisplay(
        amount: '2.25',
        unit: 'portions (370 g)',
        semanticLabel: 'Amount, 2.25 portions',
        onTap: () {},
      ),
    ),
    'not tappable': (_) => fbGoldenPad(
      const FbAmountDisplay(
        amount: '250',
        unit: 'ml',
        semanticLabel: 'Amount, 250 ml',
      ),
    ),
  },
);
