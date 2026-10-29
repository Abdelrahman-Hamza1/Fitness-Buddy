import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  const minus = '−';

  test('D13 a weight shows one decimal in kg or lb with the locale '
      'separators', () {
    expect(weightText(l10n, 97.6, MassUnit.kilogram), '97.6 kg');
    expect(weightText(l10n, 97, MassUnit.kilogram), '97.0 kg');
    // 97.07 kg is 214.0 lb, shown back as typed (D6).
    expect(weightText(l10n, 97.07, MassUnit.pound), '214.0 lb');
    expect(weightText(l10n, 500, MassUnit.pound), '1,102.3 lb');
    expect(weightWholeText(l10n, 20, MassUnit.kilogram), '20 kg');
    expect(weightWholeText(l10n, 1102, MassUnit.pound), '1,102 lb');
    expect(
      weighInInputText(l10n, const WeighInInput(214, MassUnit.pound)),
      '214.0 lb',
    );
    expect(weightUnitLabel(l10n, MassUnit.kilogram), 'kg');
    expect(weightUnitLabel(l10n, MassUnit.pound), 'lb');
    expect(weightIn(1, MassUnit.pound), closeTo(2.20462, 1e-5));
  });

  test('WB-011 a rate or change is signed with U+2212, and 0.0 below '
      '0.05', () {
    expect(
      weightRateText(l10n, -0.4, MassUnit.kilogram),
      '${minus}0.4 kg/week',
    );
    expect(weightRateText(l10n, 0.26, MassUnit.kilogram), '+0.3 kg/week');
    expect(weightRateText(l10n, 0.049, MassUnit.kilogram), '0.0 kg/week');
    expect(weightRateText(l10n, -0.049, MassUnit.kilogram), '0.0 kg/week');
    expect(
      weightRateText(l10n, -0.05, MassUnit.kilogram),
      '${minus}0.1 kg/week',
    );
    expect(weightRateText(l10n, -0.5, MassUnit.pound), '${minus}1.1 lb/week');
    expect(weightDiffText(l10n, 3, MassUnit.kilogram), '+3.0 kg');
    expect(weightDiffText(l10n, -1.25, MassUnit.kilogram), '${minus}1.3 kg');
    expect(signedWeightNumber(l10n, 0), '0.0');
    // Never from readable rows, but no crash either.
    expect(signedWeightNumber(l10n, double.nan), '0.0');
    expect(signedWeightNumber(l10n, double.infinity), '0.0');
    expect(signedWeightNumber(l10n, 1e306), startsWith('+'));
  });

  test('m5 screen readers hear the unit in full', () {
    expect(weightSpoken(l10n, 97.6, MassUnit.kilogram), '97.6 kilograms');
    expect(weightSpoken(l10n, 97.6, MassUnit.pound), '215.2 pounds');
    expect(
      weightSpokenChange(l10n, -0.4, MassUnit.kilogram),
      '${minus}0.4 kilograms',
    );
    expect(weightSpokenChange(l10n, 0.5, MassUnit.pound), '+1.1 pounds');
  });

  test('the typed pad text uses the locale decimal separator; empty is 0', () {
    expect(weightTyped(l10n, ''), '0');
    expect(weightTyped(l10n, '97.'), '97.');
    expect(weightTyped(l10n, '97.4'), '97.4');
  });

  test('D13 weight copy is neutral: no praise or blame words in any '
      'weight* or weighIn* string', () {
    final arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final keys = [
      for (final key in arb.keys)
        if (key.startsWith('weight') || key.startsWith('weighIn')) key,
    ];
    expect(keys, hasLength(greaterThan(60)));
    for (final key in keys) {
      final copy = (arb[key] as String).toLowerCase();
      for (final word in [
        'great',
        'good',
        'bad',
        'oops',
        'too much',
        'gained',
        'lost',
        'well done',
        'careful',
        'warning',
      ]) {
        expect(copy, isNot(contains(word)), reason: '$key: $word');
      }
    }
  });
}
