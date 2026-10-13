// fb_domain is a dev dependency only (S08 D12): fb_text returns plain unit
// codes, and this test is what ties them to the domain's units.
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';
import 'package:test/test.dart';

void main() {
  test('every fb_text unit code resolves in fb_domain', () {
    expect(parsedUnitCodes, isNotEmpty);
    for (final code in parsedUnitCodes) {
      expect(isKnownFoodUnitCode(code), isTrue, reason: code);
    }
  });
}
