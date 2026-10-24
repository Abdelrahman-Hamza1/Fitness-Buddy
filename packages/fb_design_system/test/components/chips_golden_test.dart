import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'AI-031 AI-033 DY-030 UX-070 UX-040 chips golden matrix',
  fileName: 'chips',
  states: {
    'assumption': (_) => fbGoldenPad(
      FbAssumptionChip(label: 'Assumed 1 cup of rice', onTap: () {}),
    ),
    'answer': (_) => fbGoldenPad(
      Wrap(
        spacing: FbSpace.s2,
        children: [
          FbAnswerChip(label: 'Small', onTap: () {}),
          FbAnswerChip(label: 'Medium', isDefault: true, onTap: () {}),
          FbAnswerChip(label: 'Large', selected: true, onTap: () {}),
        ],
      ),
    ),
    'quick add': (_) => fbGoldenPad(
      Wrap(
        spacing: FbSpace.s2,
        runSpacing: FbSpace.s2,
        children: [
          FbQuickAddChip(label: 'Coffee', onTap: () {}),
          FbQuickAddChip(
            label: 'Usual breakfast',
            icon: FbIcons.meal,
            semanticLabel: 'Log Usual breakfast',
            onTap: () {},
          ),
          FbQuickAddChip.add(label: 'Banana', onTap: () {}),
          FbQuickAddChip.add(label: 'Greek yoghurt with honey', onTap: () {}),
        ],
      ),
    ),
    'long name': (_) => fbGoldenPad(
      FbQuickAddChip(
        label:
            'Grilled chicken breast with roasted vegetables and tahini sauce '
            'and a very long extra name',
        icon: FbIcons.meal,
        onTap: () {},
      ),
    ),
  },
);
