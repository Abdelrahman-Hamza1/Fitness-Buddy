import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/components/source_badge.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-044 FD-010 UX-070 UX-040 legend sheet golden matrix',
  fileName: 'legend_sheet',
  states: {
    'sheet': (context) => FbSheet(
      title: FbLocalizations.of(context).fbSourceLegendTitle,
      child: const FbSourceLegendBody(),
    ),
  },
);
