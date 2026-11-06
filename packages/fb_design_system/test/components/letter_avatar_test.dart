import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  test('AC-005 A63 D11 the letter is the first grapheme, upper-cased; '
      'Arabic and emoji keep their first character', () {
    expect(FbLetterAvatar.letterOf('abood'), 'A');
    expect(FbLetterAvatar.letterOf('  sara@example.com'), 'S');
    expect(FbLetterAvatar.letterOf('عبود'), 'ع');
    expect(FbLetterAvatar.letterOf('👍🏽 Sam'), '👍🏽');
    expect(FbLetterAvatar.letterOf(''), isNull);
    expect(FbLetterAvatar.letterOf('   '), isNull);
    expect(FbLetterAvatar.letterOf(null), isNull);
  });

  testWidgets('AC-005 A63 D11 no source shows the icon; the circle keeps its '
      'size at text scale 2.0 and says nothing to a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpFb(tester, const Center(child: FbLetterAvatar(source: null)));
    expect(find.byIcon(FbIcons.me), findsOne);

    await pumpFb(
      tester,
      const Center(child: FbLetterAvatar(source: 'Abood')),
      textScale: 2,
    );
    expect(find.text('A'), findsOne);
    expect(tester.getSize(find.byType(FbLetterAvatar)), const Size.square(40));
    expect(find.semantics.byLabel('A'), findsNothing);
    semantics.dispose();
  });
}
