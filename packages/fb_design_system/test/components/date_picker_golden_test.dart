import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'HM-009 UX-070 UX-040 date picker golden matrix',
  fileName: 'date_picker',
  states: {
    // A phone-sized screen, so the dialog takes its portrait layout.
    'days after lastDate disabled': (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: const Size(360, 800)),
      child: DatePickerDialog(
        initialDate: DateTime(2026, 10, 15),
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 10, 20),
      ),
    ),
  },
  textScales: const [1],
);
