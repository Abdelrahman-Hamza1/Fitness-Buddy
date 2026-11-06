import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('LC-033 countryLabel names the known countries', () {
    expect(countryLabel(l10n, 'PS'), 'Palestine');
    expect(countryLabel(l10n, 'JO'), l10n.countryJO);
  });

  test('LC-033 countryLabel has no subtitle for a country without a name, '
      'never the bare ISO code (#119)', () {
    expect(countryLabel(l10n, 'IL'), isNull);
    expect(countryLabel(l10n, 'XX'), isNull);
  });
}
