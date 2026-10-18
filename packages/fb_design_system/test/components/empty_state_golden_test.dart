import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 empty state golden matrix',
  fileName: 'empty_state',
  states: {
    'with action': (_) => fbGoldenPad(
      FbEmptyState(
        icon: FbIcons.empty,
        title: 'Nothing logged yet',
        message: 'Tell Buddy what you ate and it shows up here.',
        action: FbButton.primary(label: 'Add food', onPressed: () {}),
      ),
    ),
    'no action': (_) => fbGoldenPad(
      const FbEmptyState(
        icon: FbIcons.chart,
        title: 'No data yet',
        message: 'Log a few days to see your trend.',
      ),
    ),
  },
);
