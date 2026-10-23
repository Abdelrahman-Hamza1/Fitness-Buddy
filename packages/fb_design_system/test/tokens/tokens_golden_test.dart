import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_matrix.dart';
import '../helpers/tokens_sheet.dart';

Future<void> main() async {
  await goldenTest(
    'UX-042 UX-071 tokens sheet, light/dark',
    fileName: 'tokens_sheet',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        for (final brightness in Brightness.values)
          GoldenTestScenario(
            name: brightness.name,
            child: fbGoldenCell(
              brightness: brightness,
              child: TokensSheet(palette: FbPalette.of(brightness)),
            ),
          ),
      ],
    ),
  );
}
