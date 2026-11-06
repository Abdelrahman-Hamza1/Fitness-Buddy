import 'package:fb_mobile/features/body/presentation/body_versions.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('G7 #236 a weigh-in version reads as its weight as typed; a scrubbed '
      'tombstone (#136) or an unreadable payload shows only its time', () {
    expect(
      weighInVersionText(l10n, {
        'kg': 97.07,
        'inputValue': 214.0,
        'inputUnit': 'lb',
      }),
      '214.0 lb',
    );
    expect(
      weighInVersionText(l10n, {
        'kg': 0.0,
        'inputValue': 0.0,
        'inputUnit': 'lb',
        'note': null,
      }),
      isNull,
    );
    expect(weighInVersionText(l10n, {'kg': 80, 'inputUnit': 'stone'}), isNull);
  });

  test('G7 #236 a measurement version reads as its value as typed', () {
    expect(
      measurementVersionText(l10n, {'inputValue': 36.5, 'inputUnit': 'in'}),
      '36.5 in',
    );
    expect(measurementVersionText(l10n, {'inputValue': 'x'}), isNull);
  });
}
