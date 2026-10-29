import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/assumption_labels.dart';
import 'package:fb_mobile/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  // rule: A22 assumption-labels
  test('A22 known assumption codes render localized text', () {
    expect(
      assumptionText(l10n, 'a1:yield:dry:cooked:200.0:500.0'),
      '200 g weighed dry, counted as 500 g cooked',
    );
    expect(
      assumptionText(
        l10n,
        'a1:yield:dry:cooked:200.0:500.0',
        system: UnitSystem.imperial,
      ),
      contains('oz'),
    );
    expect(
      assumptionText(l10n, 'a1:oil:all'),
      'All of the cooking oil counted',
    );
    expect(
      assumptionText(l10n, 'a1:oil:most'),
      'Most of the cooking oil counted (some stays in the pan)',
    );
    expect(assumptionText(l10n, 'a1:share:0.5/1'), 'Your share: 50%');
    expect(assumptionText(l10n, 'a1:share:1/3'), 'Your share: 33%');
    expect(assumptionText(l10n, 'a1:origin:stated'), 'As you said');
    expect(assumptionText(l10n, 'a1:origin:savedDefault'), 'Your usual choice');
    expect(
      assumptionText(l10n, 'a1:origin:fallback'),
      'A typical choice was assumed',
    );
    expect(assumptionText(l10n, 'a1:origin:userAdjusted'), 'Changed by you');
    // Card notes: only what a number rests on.
    expect(isCardAssumption('a1:oil:all'), isTrue);
    expect(isCardAssumption('a1:share:1/3'), isTrue);
    expect(isCardAssumption('a1:yield:dry:cooked:200.0:500.0'), isTrue);
    expect(isCardAssumption('a1:origin:fallback'), isFalse);
    expect(isCardAssumption('Includes tahini'), isFalse);
  });

  // rule: A22 assumption-labels
  test('A22 unknown assumption code or legacy text renders generic '
      'assumption', () {
    for (final raw in [
      'a2:oil:all',
      'a1:mood:happy',
      'a1:oil:half',
      'a1:yield:dry:cooked:x:500',
      'a1:share:3/2',
      'a1:yield:dry:cooked:${'9' * 400}:500.0',
      'Assuming 1 tbsp olive oil',
      'افترضت ملعقة زيت',
      '',
    ]) {
      final text = assumptionText(l10n, raw);
      expect(text, 'Assumed value', reason: raw);
      if (raw.isNotEmpty) expect(text, isNot(contains(raw)));
    }
  });
}
