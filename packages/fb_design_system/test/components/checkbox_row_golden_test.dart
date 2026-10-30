import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 SF-012 checkbox row golden matrix',
  fileName: 'checkbox_row',
  states: {
    'checked': (_) => FbCheckboxRow(
      title: 'I understand and want to use 1,300 kcal a day',
      value: true,
      onChanged: (_) {},
    ),
    'unchecked with subtitle': (_) => FbCheckboxRow(
      title: 'I understand',
      subtitle: 'You can change this at any time',
      value: false,
      onChanged: (_) {},
    ),
    'disabled': (_) => const FbCheckboxRow(
      title: 'I understand',
      value: false,
      onChanged: null,
    ),
  },
);
