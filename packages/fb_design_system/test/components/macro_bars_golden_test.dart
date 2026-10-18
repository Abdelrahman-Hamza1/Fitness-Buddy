import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'HM-003 UX-042 UX-071 UX-070 UX-040 macro bars golden matrix',
  fileName: 'macro_bars',
  states: {
    'normal': (_) => fbGoldenPad(
      const FbMacroBars(
        macros: [
          FbMacroValue(
            kind: FbMacroKind.protein,
            value: 82,
            target: 140,
            label: 'Protein',
            valueText: '82 / 140 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.carbs,
            value: 120,
            target: 220,
            label: 'Carbs',
            valueText: '120 / 220 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.fat,
            value: 30,
            target: 70,
            label: 'Fat',
            valueText: '30 / 70 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.fiber,
            value: 12,
            target: 30,
            label: 'Fiber',
            valueText: '12 / 30 g',
          ),
        ],
      ),
    ),
    'one over': (_) => fbGoldenPad(
      const FbMacroBars(
        macros: [
          FbMacroValue(
            kind: FbMacroKind.protein,
            value: 150,
            target: 140,
            label: 'Protein',
            valueText: '10 g over',
          ),
          FbMacroValue(
            kind: FbMacroKind.carbs,
            value: 120,
            target: 220,
            label: 'Carbs',
            valueText: '120 / 220 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.fat,
            value: 30,
            target: 70,
            label: 'Fat',
            valueText: '30 / 70 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.fiber,
            value: 35,
            target: 30,
            label: 'Fiber',
            valueText: '5 g over',
          ),
        ],
      ),
    ),
  },
);
