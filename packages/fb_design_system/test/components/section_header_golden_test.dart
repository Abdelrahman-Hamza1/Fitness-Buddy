import 'package:fb_design_system/fb_design_system.dart';

import '../helpers/golden_matrix.dart';

Future<void> main() => fbGoldenMatrix(
  'UX-070 UX-040 section header golden matrix',
  fileName: 'section_header',
  states: {
    'title': (_) => const FbSectionHeader(title: 'Dinner'),
    'trailing': (_) => FbSectionHeader(
      title: 'Dinner',
      trailing: FbButton.text(label: 'Add', onPressed: () {}),
    ),
    'long title': (_) => FbSectionHeader(
      title: 'A very long section title that wraps',
      trailing: FbButton.text(label: 'See all', onPressed: () {}),
    ),
  },
);
