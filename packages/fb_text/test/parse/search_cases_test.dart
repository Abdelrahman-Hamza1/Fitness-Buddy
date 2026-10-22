import 'package:fb_text/fb_text.dart';
import 'package:test/test.dart';

void main() {
  test('LC-011 two adjacent quantities are rejected (#28)', () {
    expect(parseQuantity('2 x2 eggs'), isNull);
    expect(parseQuantity('2 100g rice'), isNull);
  });
  test('LC-011 zero suffix is rejected, callers search raw text (#29)', () {
    expect(parseQuantity('Coke 0'), isNull);
  });
  test('LC-011 explicit suffix wins over implicit prefix (#31)', () {
    final parsed = parseQuantity('cup of tea 2 tbsp')!;
    expect(parsed.amount, 2);
    expect(parsed.unitCode, 'tbsp');
    expect(parsed.rest, 'cup of tea');
  });
}
