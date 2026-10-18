import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 sheet golden matrix',
  fileName: 'sheet',
  states: {
    'titled': (_) => const FbSheet(
      title: 'Add food',
      child: Text('Sheet content that explains something helpful.'),
    ),
    'untitled': (_) =>
        const FbSheet(child: Text('Sheet content without a title.')),
  },
);
