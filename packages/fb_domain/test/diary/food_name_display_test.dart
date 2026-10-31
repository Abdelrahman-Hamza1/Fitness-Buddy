import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  final both = FoodNames('Maqluba (chicken)', ar: 'مقلوبة دجاج');
  final english = FoodNames('Oats');

  test('D-091 "Match my phone" takes the first of Arabic or English in the '
      "phone's languages, else English", () {
    const phone = FoodNameLanguage.phone;
    expect(phone.resolve(['ar', 'en']), FoodNameLanguage.arabic);
    expect(phone.resolve(['fr', 'AR']), FoodNameLanguage.arabic);
    expect(phone.resolve(['en', 'ar']), FoodNameLanguage.english);
    expect(phone.resolve(['de']), FoodNameLanguage.english);
    expect(phone.resolve(const []), FoodNameLanguage.english);
    for (final other in FoodNameLanguage.values.skip(1)) {
      expect(other.resolve(['ar']), other);
    }
  });

  test('D-091 each language picks the lines; a missing Arabic name falls '
      'back to English, never an empty line', () {
    final en = FoodNameLines.of(both, FoodNameLanguage.english);
    expect((en.primary, en.secondary), ('Maqluba (chicken)', null));
    expect(
      FoodNameLines.of(both, FoodNameLanguage.phone),
      en,
      reason: 'unresolved phone reads as English',
    );
    final ar = FoodNameLines.of(both, FoodNameLanguage.arabic);
    expect((ar.primary, ar.secondary), ('مقلوبة دجاج', null));
    final two = FoodNameLines.of(both, FoodNameLanguage.both);
    expect((two.primary, two.secondary), ('Maqluba (chicken)', 'مقلوبة دجاج'));
    for (final language in FoodNameLanguage.values) {
      final lines = FoodNameLines.of(english, language);
      expect((lines.primary, lines.secondary), ('Oats', null));
    }
    expect('$two', isNot(contains('Maqluba')));
  });
}
