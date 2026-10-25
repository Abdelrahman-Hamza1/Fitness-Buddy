import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 sheet with pinned actions golden matrix',
  fileName: 'sheet_actions',
  states: {
    'pinned actions': (_) => FbSheet(
      title: 'Edit meal',
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: FbSpace.s2,
        children: [
          FbButton.primary(label: 'Save', expand: true, onPressed: () {}),
          FbButton.text(label: 'Remove meal', expand: true, onPressed: () {}),
        ],
      ),
      child: const Text('Sheet content that explains something helpful.'),
    ),
  },
);
