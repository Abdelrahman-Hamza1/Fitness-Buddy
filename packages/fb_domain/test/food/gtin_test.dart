import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Gtin.normalize (same rules as the server, B10a D3)', () {
    test('keeps GTIN-8 and GTIN-13, pads GTIN-12, trims a zero GTIN-14', () {
      expect(Gtin.normalize('96385074'), '96385074');
      expect(Gtin.normalize('4006381333931'), '4006381333931');
      expect(Gtin.normalize('036000291452'), '0036000291452');
      expect(Gtin.normalize('00036000291452'), '0036000291452');
      expect(Gtin.normalize('10036000291459'), '10036000291459');
    });

    test('rejects a wrong check digit, letters and other lengths', () {
      expect(Gtin.normalize('4006381333932'), isNull);
      expect(Gtin.normalize('40063813339a1'), isNull);
      expect(Gtin.normalize('1234567'), isNull);
      expect(Gtin.normalize(''), isNull);
    });
  });

  group('Gtin.expandUpcE', () {
    test('expands each last-digit rule to a valid UPC-A', () {
      // Published GS1 examples.
      expect(Gtin.expandUpcE('04252614'), '042100005264');
      expect(Gtin.expandUpcE('01234565'), '012345000065');
      expect(Gtin.expandUpcE('425261'), '042100005264');
      expect(Gtin.expandUpcE('0425261'), '042100005264');
      for (var last = 0; last <= 9; last++) {
        final upcA = Gtin.expandUpcE('012345$last')!;
        expect(Gtin.isValid(upcA), isTrue, reason: '$last');
        // The 8-digit form with that check digit expands the same way.
        expect(Gtin.expandUpcE('012345$last${upcA[11]}'), upcA);
      }
    });

    test('rejects a wrong check digit or number system', () {
      expect(Gtin.expandUpcE('04252615'), isNull);
      expect(Gtin.expandUpcE('24252614'), isNull);
      expect(Gtin.expandUpcE('12a456'), isNull);
    });
  });
}
