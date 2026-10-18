import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 list row golden matrix',
  fileName: 'list_row',
  states: {
    'plain': (_) => const FbListRow(title: 'Breakfast'),
    'subtitle': (_) => const FbListRow(title: 'Breakfast', subtitle: '2 items'),
    'leading and trailing': (_) => FbListRow(
      title: 'Oats',
      subtitle: '40 g',
      leading: const Icon(FbIcons.diary),
      trailing: const Text('150 kcal'),
      onTap: () {},
    ),
    'long title': (_) => const FbListRow(
      title: 'Grilled chicken breast with roasted vegetables and tahini sauce',
      subtitle: 'A long subtitle that also needs to wrap on narrow screens',
      trailing: Text('650 kcal'),
    ),
  },
);
