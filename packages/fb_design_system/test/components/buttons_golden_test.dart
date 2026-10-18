import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 buttons golden matrix',
  fileName: 'buttons',
  states: {
    'primary': (_) =>
        fbGoldenPad(FbButton.primary(label: 'Log it', onPressed: () {})),
    'primary disabled': (_) =>
        fbGoldenPad(const FbButton.primary(label: 'Log it', onPressed: null)),
    'primary icon': (_) => fbGoldenPad(
      FbButton.primary(label: 'Add food', icon: FbIcons.add, onPressed: () {}),
    ),
    'primary expand': (_) => fbGoldenPad(
      FbButton.primary(label: 'Log it', expand: true, onPressed: () {}),
    ),
    'secondary': (_) =>
        fbGoldenPad(FbButton.secondary(label: 'Discard', onPressed: () {})),
    'secondary disabled': (_) => fbGoldenPad(
      const FbButton.secondary(label: 'Discard', onPressed: null),
    ),
    'secondary icon': (_) => fbGoldenPad(
      FbButton.secondary(label: 'Scan', icon: FbIcons.camera, onPressed: () {}),
    ),
    'text': (_) =>
        fbGoldenPad(FbButton.text(label: 'Not now', onPressed: () {})),
    'text disabled': (_) =>
        fbGoldenPad(const FbButton.text(label: 'Not now', onPressed: null)),
    'text icon': (_) => fbGoldenPad(
      FbButton.text(label: 'More', icon: FbIcons.more, onPressed: () {}),
    ),
    'long label': (_) => fbGoldenPad(
      FbButton.primary(
        label: 'Add this meal to the diary for dinner',
        expand: true,
        onPressed: () {},
      ),
    ),
  },
);
