import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 switch row golden matrix',
  fileName: 'switch_row',
  states: {
    'on': (_) =>
        FbSwitchRow(title: 'Halal food', value: true, onChanged: (_) {}),
    'off with subtitle': (_) => FbSwitchRow(
      title: 'Halal food',
      subtitle: 'Only show halal foods',
      value: false,
      onChanged: (_) {},
    ),
    'disabled': (_) =>
        const FbSwitchRow(title: 'Halal food', value: true, onChanged: null),
    'long title': (_) => FbSwitchRow(
      title: 'Show only foods that are halal certified or halal by default',
      subtitle: 'A long subtitle that also needs to wrap on narrow screens',
      value: true,
      onChanged: (_) {},
    ),
  },
);
