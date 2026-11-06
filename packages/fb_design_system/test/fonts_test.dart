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
      '(Outfit w800, its tnum feature)', () {
    expect(FbType.display.fontFamily, contains('Outfit'));
    expect(FbType.display.fontWeight, FontWeight.w800);
    final one = _width('1111', FbType.display);
    for (final digits in ['0000', '4444', '7777', '8888']) {
      expect(_width(digits, FbType.display), closeTo(one, 0.01));
    }
    // Without tnum Outfit's digits are proportional, so the test above can
    // only pass because the feature is on.
    final proportional = FbType.display.copyWith(fontFeatures: const []);
    expect(
      _width('1111', proportional),
      isNot(closeTo(_width('0000', proportional), 0.5)),
    );
  });

  test('A64 the Outfit weight axis moves: w100 < w400 < w800 in rendered '
      'width', () {
    // The variable font's default instance is Thin (100): a stuck default or
    // a fixed weight can't pass.
    TextStyle at(FontWeight w) => FbType.headline.copyWith(fontWeight: w);
    const text = 'Fitness Buddy';
    final thin = _width(text, at(FontWeight.w100));
    final regular = _width(text, at(FontWeight.w400));
    final extraBold = _width(text, at(FontWeight.w800));
    expect(thin, lessThan(regular));
    expect(regular, lessThan(extraBold));
  });

  test('UX-070 every Outfit style carries tabular figures (A64), since '
      'its default digits are proportional', () {
    for (final style in [
      FbType.display,
      FbType.headline,
      FbType.title,
      FbType.wordmark(26),
    ]) {
      expect(style.fontFamily, contains(FbType.displayFamily));
      expect(
        style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: '$style',
      );
    }
    final one = _width('1111', FbType.title);
    expect(_width('0000', FbType.title), closeTo(one, 0.01));
  });
}
