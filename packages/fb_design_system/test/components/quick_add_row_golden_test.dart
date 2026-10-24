import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'DY-030 HM-008 UX-070 UX-040 quick-add row golden matrix',
  fileName: 'quick_add_row',
  states: {
    'foods and a meal': (_) => FbQuickAddRow(
      chips: [
        FbQuickAddChip(label: 'Labaneh', onTap: () {}),
        FbQuickAddChip(
          label: 'Usual breakfast',
          icon: FbIcons.meal,
          onTap: () {},
        ),
        FbQuickAddChip(label: 'Pita bread, white', onTap: () {}),
        FbQuickAddChip(label: 'Coffee', onTap: () {}),
      ],
      addLabel: 'Add food',
      onAdd: () {},
    ),
    'only the plus': (_) =>
        FbQuickAddRow(chips: const [], addLabel: 'Add food', onAdd: () {}),
  },
);
