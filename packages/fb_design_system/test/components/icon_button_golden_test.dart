import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-040 UX-070 icon button golden matrix',
  fileName: 'icon_button',
  states: {
    'enabled and disabled': (_) => fbGoldenPad(
      Row(
        children: [
          FbIconButton(icon: FbIcons.edit, tooltip: 'Rename', onPressed: () {}),
          FbIconButton(icon: FbIcons.more, tooltip: 'More', onPressed: () {}),
          const FbIconButton(
            icon: FbIcons.delete,
            tooltip: 'Delete',
            onPressed: null,
          ),
        ],
      ),
    ),
  },
);
