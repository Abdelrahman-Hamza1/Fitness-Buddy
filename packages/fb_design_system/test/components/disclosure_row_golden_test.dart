import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'HM-007 UX-070 UX-040 disclosure row golden matrix',
  fileName: 'disclosure_row',
  states: {
    'collapsed': (_) => FbDisclosureRow(
      title: 'Breakfast',
      subtitle: 'Oats · Banana',
      expanded: false,
      onToggle: () {},
    ),
    'expanded with leading and trailing': (_) => FbDisclosureRow(
      title: 'Chicken and rice',
      subtitle: '3 items',
      leading: const Icon(FbIcons.diary),
      trailing: const Text('520 kcal'),
      expanded: true,
      onToggle: () {},
    ),
    'title only': (_) =>
        FbDisclosureRow(title: 'Lunch', expanded: false, onToggle: () {}),
    'long title': (_) => FbDisclosureRow(
      title: 'Grilled chicken breast with roasted vegetables and tahini sauce',
      subtitle: 'A long subtitle that also needs to wrap on narrow screens',
      trailing: const Text('650 kcal'),
      expanded: true,
      onToggle: () {},
    ),
  },
);
