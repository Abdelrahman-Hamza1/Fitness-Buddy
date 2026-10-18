import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';

/// The snackbar the helpers show, rendered in place (a real one needs a
/// Scaffold and an animation, which would take more than one pump).
///
/// The snackbar's Wrap has no intrinsic sizes, which the matrix table asks
/// for, so the cell gets a fixed height: [lines] text lines at the scale.
Widget _snack(
  BuildContext context,
  String message, {
  required int lines,
  bool undo = true,
}) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  return SizedBox(
    width: fbGoldenCellWidth,
    height: 32 + lines * 24 * scale,
    child: SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      width: fbGoldenCellWidth - 2 * FbSpace.s4,
      animation: const AlwaysStoppedAnimation(1),
      action: undo
          ? SnackBarAction(
              label: FbLocalizations.of(context).fbUndo,
              onPressed: () {},
            )
          : null,
    ),
  );
}

Future<void> main() => fbGoldenMatrix(
  'UX-030 UX-070 UX-040 undo snackbar golden matrix',
  fileName: 'undo_snackbar',
  states: {
    'undo': (context) => _snack(context, 'Logged Oats, 150 kcal', lines: 2),
    'long message': (context) => _snack(
      context,
      'Logged Grilled chicken breast with roasted vegetables, 650 kcal',
      lines: 4,
    ),
    'plain': (context) =>
        _snack(context, 'Weight saved', lines: 1, undo: false),
  },
);
