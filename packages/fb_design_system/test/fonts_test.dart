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

  test('A02-D19 the package font is loaded: Latin text is not measured '
      'with Ahem', () {
    const text = 'Hello iii';
    final inter = _width(text, FbType.body);
    expect(inter, isNot(_width(text, ahem)));
    expect(inter, lessThan(_width(text, ahem)));
    // Proportional: narrow and wide glyphs differ (Ahem: all equal).
    expect(
      _width('iiiiii', FbType.body),
      lessThan(_width('WWWWWW', FbType.body)),
    );
  });

  test('A02-D19 the Arabic fallback font is loaded for Arabic text', () {
    const text = 'لبنة بالزعتر';
    expect(_width(text, FbType.body), isNot(_width(text, ahem)));
    expect(_width(text, FbType.body), greaterThan(0));
  });

  test(
    'UX-070 tabular figures: digits have equal width in the display style',
    () {
      expect(
        _width('1111', FbType.display),
        closeTo(_width('8888', FbType.display), 0.01),
      );
    },
  );
}
