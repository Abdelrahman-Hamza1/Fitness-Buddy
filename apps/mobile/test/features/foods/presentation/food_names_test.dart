import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_text/fb_text.dart' show normalizeKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';

const _ar = 'مقلوبة دجاج';

/// A result for Maqluba matched through [key] (normalized), as a display
/// name or not.
FoodSearchRow _maqluba({String? key, bool display = false}) {
  final base = rowOf('dish:maqluba_chicken', 'Maqluba (chicken)', ar: _ar);
  return FoodSearchRow(
    choice: base.choice,
    tier: base.tier,
    matchedKey: key,
    matchedDisplay: display,
  );
}

/// The food-name setting, the phone's languages and Halal off.
List<Override> _overrides(FoodNameLanguage setting, List<String> phone) => [
  foodNameSettingProvider.overrideWith((ref) => Stream.value(setting)),
  phoneLanguagesProvider.overrideWithValue(phone),
  halalProvider.overrideWith((ref) => Stream.value(false)),
];

Future<void> _pump(
  WidgetTester tester,
  FoodSearchRow row, {
  FoodNameLanguage setting = FoodNameLanguage.phone,
  List<String> phone = const ['en'],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [..._overrides(setting, phone)],
      child: screenApp(
        Scaffold(
          body: FoodResultRow(row: row, onTap: () {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('D-091 LC-007 Match my phone shows English on an English phone '
      'and Arabic on an Arabic one', (tester) async {
    await _pump(tester, _maqluba());
    expect(find.text('Maqluba (chicken)'), findsOneWidget);
    expect(find.textContaining(_ar), findsNothing);

    await _pump(tester, _maqluba(), phone: const ['ar', 'en']);
    expect(find.text(_ar), findsOneWidget);
    expect(find.text('Maqluba (chicken)'), findsNothing);
  });

  testWidgets('D-091 Both shows English with the Arabic name, isolated, in '
      'the second line', (tester) async {
    await _pump(tester, _maqluba(), setting: FoodNameLanguage.both);
    expect(find.text('Maqluba (chicken)'), findsOneWidget);
    expect(find.textContaining('\u2068$_ar\u2069 · '), findsOneWidget);
  });

  testWidgets('D-091 FnSearch an alias match says "Matched …"; a hit on the '
      'shown name or a dish name says nothing; a hit on the Arabic name in '
      'English mode names it', (tester) async {
    await _pump(tester, _maqluba(key: 'ma2loobe'));
    expect(find.textContaining('Matched ma2loobe · '), findsOneWidget);

    await _pump(
      tester,
      _maqluba(key: normalizeKey('Maqluba (chicken)'), display: true),
    );
    expect(find.textContaining('Matched'), findsNothing);
    await _pump(tester, _maqluba(key: 'maqluba', display: true));
    expect(find.textContaining('Matched'), findsNothing);

    await _pump(tester, _maqluba(key: normalizeKey(_ar), display: true));
    expect(find.textContaining('Matched \u2068$_ar\u2069'), findsOneWidget);
    // In Arabic mode the Arabic hit is the title: no line.
    await _pump(
      tester,
      _maqluba(key: normalizeKey(_ar), display: true),
      setting: FoodNameLanguage.arabic,
    );
    expect(find.textContaining('Matched'), findsNothing);
  });

  test('A57 T-N1 LC-007 inline name follows the setting; Both is the main '
      'name only, spoken is both', () {
    final both = FoodNames('Maqluba (chicken)', ar: _ar);
    final noArabic = FoodNames('Oats');
    // A user-written dish name: as typed, whatever the setting.
    final typed = FoodNames('صحن الغدا');
    const iso = '\u2068$_ar\u2069';
    final expected = {
      FoodNameLanguage.phone: ['Maqluba (chicken)', 'Oats'],
      FoodNameLanguage.english: ['Maqluba (chicken)', 'Oats'],
      FoodNameLanguage.arabic: [iso, 'Oats'],
      FoodNameLanguage.both: ['Maqluba (chicken)', 'Oats'],
    };
    for (final MapEntry(key: language, value: names) in expected.entries) {
      expect(foodNameInline(both, language), names[0], reason: '$language');
      expect(foodNameInline(noArabic, language), names[1]);
      expect(foodNameInline(typed, language), '\u2068صحن الغدا\u2069');
    }
    expect(
      foodNameSpoken(FoodNameLines.of(both, FoodNameLanguage.both)),
      'Maqluba (chicken), $_ar',
    );
    for (final language in FoodNameLanguage.values) {
      expect(foodNameSpoken(FoodNameLines.of(noArabic, language)), 'Oats');
      if (language != FoodNameLanguage.both) {
        expect(
          foodNameSpoken(FoodNameLines.of(both, language)),
          FoodNameLines.of(both, language).primary,
        );
      }
    }
    // Undo-label placeholders: structured names resolve, text is isolated.
    expect(foodNameArg(both, FoodNameLanguage.arabic), iso);
    expect(foodNameArg('Oats', FoodNameLanguage.arabic), 'Oats');
  });

  test('A57 T-N4 LC-007 isolateName wraps embedded RTL queries and scan '
      'names, not English ones', () {
    expect(createQuote(_ar), _ar);
    expect(isolateName(createQuote(_ar)), '\u2068$_ar\u2069');
    expect(isolateName('Pita bread, white'), 'Pita bread, white');
    expect(
      pendingScanNames(
        const PendingScan(
          code: '1',
          scannedAtMs: 0,
          name: 'Halawa',
          nameAr: 'حلاوة',
        ),
        FoodNameLanguage.arabic,
      )?.primary,
      'حلاوة',
    );
    expect(
      pendingScanNames(
        const PendingScan(code: '1', scannedAtMs: 0, nameAr: 'حلاوة'),
        FoodNameLanguage.english,
      )?.primary,
      'حلاوة',
    );
    expect(
      pendingScanNames(
        const PendingScan(code: '1', scannedAtMs: 0),
        FoodNameLanguage.both,
      ),
      isNull,
    );
  });

  test('D-091 isolateName wraps only right-to-left text', () {
    expect(isolateName('Oats'), 'Oats');
    expect(isolateName(_ar), '\u2068$_ar\u2069');
  });
}
