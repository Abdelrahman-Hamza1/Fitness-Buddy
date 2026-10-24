import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

/// A field with [text] (a controller per cell; goldens are one-shot).
Widget _field(
  String text, {
  String label = 'Protein',
  String? unit = 'g',
  String? errorText,
  String? hint,
  bool enabled = true,
}) => fbGoldenPad(
  FbNumberField(
    controller: TextEditingController(text: text),
    label: label,
    unit: unit,
    errorText: errorText,
    hint: hint,
    enabled: enabled,
  ),
);

Future<void> main() => fbGoldenMatrix(
  'D16 UX-070 UX-040 number field golden matrix',
  fileName: 'number_field',
  states: {
    'empty with hint': (_) => _field('', hint: '0'),
    'number and unit': (_) => _field('12.5'),
    'kcal': (_) => _field('250', label: 'Calories', unit: 'kcal'),
    'no unit': (_) => _field('3', label: 'Pieces', unit: null),
    'arabic digits': (_) => _field('٣٠٫٥'),
    'error': (_) =>
        _field('9999', errorText: 'That is more than a food can hold'),
    'disabled': (_) => _field('12.5', enabled: false),
    'long label': (_) => _field(
      '120',
      label: 'Energy of one serving as printed on the label',
      unit: 'kcal',
    ),
  },
);
