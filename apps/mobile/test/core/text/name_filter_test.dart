import 'package:fb_mobile/core/text/name_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A65 m13 a blank query matches everything', () {
    expect(namesMatch(['Labneh'], ''), isTrue);
    expect(namesMatch(['Labneh'], '   '), isTrue);
  });

  test('A65 m13 matching ignores case and finds a part of either name', () {
    expect(namesMatch(['Greek Yogurt', null], 'yog'), isTrue);
    expect(namesMatch(['Greek Yogurt', 'لبن زبادي'], 'زبادي'), isTrue);
    expect(namesMatch(['Greek Yogurt', null], 'rice'), isFalse);
  });

  test('A65 m13 Arabic matching folds tashkeel', () {
    expect(namesMatch(['Rice', 'أَرُز'], 'ارز'), isTrue);
  });
}
