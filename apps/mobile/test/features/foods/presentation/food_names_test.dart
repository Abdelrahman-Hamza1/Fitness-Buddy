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

  test('D-091 isolateName wraps only right-to-left text', () {
    expect(isolateName('Oats'), 'Oats');
    expect(isolateName(_ar), '\u2068$_ar\u2069');
  });
}
