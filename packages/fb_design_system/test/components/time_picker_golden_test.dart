import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'D18 UX-070 UX-040 time picker golden matrix',
  fileName: 'time_picker',
  states: {
    // A phone-sized screen, so the dialog takes its portrait layout.
    'dial': (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: const Size(360, 800)),
      // A fixed size: the dialog's layout builder can't be measured by the
      // matrix table.
      child: const SizedBox(
        width: 360,
        height: 560,
        child: TimePickerDialog(initialTime: TimeOfDay(hour: 8, minute: 30)),
      ),
    ),
  },
);
