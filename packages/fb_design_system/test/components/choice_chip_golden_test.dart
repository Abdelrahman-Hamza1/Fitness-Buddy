import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Widget _aligned(Widget chip) => fbGoldenPad(
  Align(alignment: AlignmentDirectional.centerStart, child: chip),
);

Future<void> main() => fbGoldenMatrix(
  'D18 UX-070 UX-040 choice chip golden matrix',
  fileName: 'choice_chip',
  states: {
    'label and value': (_) =>
        _aligned(FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: () {})),
    'selected': (_) => _aligned(
      FbChoiceChip(label: 'Meal', value: 'Lunch', selected: true, onTap: () {}),
    ),
    'disabled': (_) => _aligned(
      const FbChoiceChip(label: 'Meal', value: 'Lunch', onTap: null),
    ),
    'label only, no arrow': (_) => _aligned(
      FbChoiceChip(
        label: 'Log as Rice, white, raw',
        dropdown: false,
        onTap: () {},
      ),
    ),
    'leading icon': (_) => _aligned(
      FbChoiceChip(
        label: 'Change food',
        icon: FbIcons.search,
        dropdown: false,
        onTap: () {},
      ),
    ),
    'arabic value': (_) =>
        _aligned(FbChoiceChip(label: 'Meal', value: 'الغداء', onTap: () {})),
    'long value': (_) => _aligned(
      FbChoiceChip(
        label: 'Food',
        value: 'Grilled chicken breast with roasted vegetables and tahini',
        onTap: () {},
      ),
    ),
    'row of chips': (_) => fbGoldenPad(
      Wrap(
        spacing: FbSpace.s2,
        runSpacing: FbSpace.s2,
        children: [
          FbChoiceChip(label: 'Amount', value: '2 loaves', onTap: () {}),
          FbChoiceChip(label: 'Meal', value: 'Breakfast', onTap: () {}),
          FbChoiceChip(label: 'Time', value: '8:30 AM', onTap: () {}),
        ],
      ),
    ),
  },
);
