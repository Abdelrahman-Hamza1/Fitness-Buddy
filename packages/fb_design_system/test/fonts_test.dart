import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

double _width(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  // D19: if the package fonts silently fell back to the test font (Ahem, one
  // em per glyph), every golden's text metrics would be wrong.
  const ahem = TextStyle(fontFamily: 'Ahem', fontSize: 16);

  test('A02-D19 the Arabic fallback font is loaded for Arabic text', () {
    const text = 'لبنة بالزعتر';
    expect(_width(text, FbType.body), isNot(_width(text, ahem)));
    expect(_width(text, FbType.body), greaterThan(0));
  });

  test('UX-070 tabular figures: digits have equal width in the display style '
      '(Nunito w800)', () {
    expect(FbType.display.fontFamily, contains('Nunito'));
    expect(FbType.display.fontWeight, FontWeight.w800);
    final one = _width('1111', FbType.display);
    for (final digits in ['0000', '4444', '7777', '8888']) {
      expect(_width(digits, FbType.display), closeTo(one, 0.01));
    }
  });
}
