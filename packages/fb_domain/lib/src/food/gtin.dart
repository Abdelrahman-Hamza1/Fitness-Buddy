/// GS1 check digits for personal-food barcodes (FD-001).
abstract final class Gtin {
  /// Accepts only GTIN-8/12/13/14, including leading zeroes.
  static bool isValid(String value) {
    if (![8, 12, 13, 14].contains(value.length) ||
        !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return false;
    }
    var sum = 0;
    for (
      var i = value.length - 2, weight = 3;
      i >= 0;
      i--, weight = 4 - weight
    ) {
      sum += (value.codeUnitAt(i) - 48) * weight;
    }
    return (sum + value.codeUnitAt(value.length - 1) - 48) % 10 == 0;
  }
}
