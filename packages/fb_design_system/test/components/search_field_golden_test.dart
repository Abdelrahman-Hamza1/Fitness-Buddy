import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

/// A field with [text] (a controller per cell; goldens are one-shot).
Widget _field(String text, {String hint = 'Search foods'}) => fbGoldenPad(
  FbSearchField(
    controller: TextEditingController(text: text),
    hint: hint,
  ),
);

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 FD-020 search field golden matrix',
  fileName: 'search_field',
  states: {
    'empty': (_) => _field(''),
    'text': (_) => _field('rice'),
    'arabic text': (_) => _field('خبز عربي'),
    'long text': (_) => _field(
      'grilled chicken breast with roasted vegetables and tahini sauce',
    ),
    'long hint': (_) => _field(
      '',
      hint: 'Search in English, Arabic or Arabizi for any food you ate',
    ),
  },
);
