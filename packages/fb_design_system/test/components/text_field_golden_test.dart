import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

/// A field with [text] (a controller per cell; goldens are one-shot).
Widget _field(
  String text, {
  String label = 'Name',
  int? maxLength,
  String? errorText,
  String? hint,
}) => fbGoldenPad(
  FbTextField(
    controller: TextEditingController(text: text),
    label: label,
    maxLength: maxLength,
    errorText: errorText,
    hint: hint,
  ),
);

Future<void> main() => fbGoldenMatrix(
  'D18 UX-070 UX-040 text field golden matrix',
  fileName: 'text_field',
  states: {
    'empty with hint': (_) => _field('', hint: 'Breakfast bowl'),
    'text with counter': (_) => _field('Oats and banana', maxLength: 60),
    'arabic text': (_) => _field('فطور الصباح', maxLength: 60),
    'error': (_) => _field('', maxLength: 60, errorText: 'Give it a name'),
    'long text and long label': (_) => _field(
      'grilled chicken breast with roasted vegetables and tahini sauce',
      label: 'Name of the saved meal that you will find again later',
      maxLength: 60,
    ),
  },
);
