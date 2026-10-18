import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'AI-040 UX-070 UX-040 unit picker golden matrix',
  fileName: 'unit_picker',
  states: {
    'selected first': (_) => fbGoldenPad(
      FbUnitPicker(units: _units, selected: 'g', onSelected: (_) {}),
    ),
    'selected last': (_) => fbGoldenPad(
      FbUnitPicker(units: _units, selected: 'cup', onSelected: (_) {}),
    ),
  },
);

const _units = [
  FbUnitOption(id: 'g', label: 'g'),
  FbUnitOption(id: 'ml', label: 'ml'),
  FbUnitOption(id: 'piece', label: 'piece'),
  FbUnitOption(id: 'cup', label: 'cup'),
];
