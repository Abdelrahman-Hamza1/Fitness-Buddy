/// GS1 check digits for personal-food barcodes (FD-001) and scanned codes
/// (FD-030, B10a/A28a D3).
abstract final class Gtin {
  /// Accepts only GTIN-8/12/13/14, including leading zeroes.
  static bool isValid(String value) {
    if (![8, 12, 13, 14].contains(value.length) ||
        !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return false;
    }
    return _checkDigit(value.substring(0, value.length - 1)) ==
        value.codeUnitAt(value.length - 1) - 48;
  }

  /// The lookup key the server uses (Open Food Facts' canonical form):
  /// GTIN-12 gains a leading zero, a zero-padded GTIN-14 loses one; GTIN-8
  /// and GTIN-13 stay. `null` when [value] isn't a valid GTIN.
  static String? normalize(String value) {
    if (!isValid(value)) return null;
    return switch (value.length) {
      12 => '0$value',
      14 when value.startsWith('0') => value.substring(1),
      _ => value,
    };
  }

  /// The UPC-A (GTIN-12) form of a UPC-E code, or `null` when [value] isn't
  /// one. Takes the 8-digit form (number system 0 or 1, six digits, check),
  /// the 7-digit form without check, or the bare 6 digits (number system 0).
  static String? expandUpcE(String value) {
    if (!RegExp(r'^[0-9]{6,8}$').hasMatch(value)) return null;
    final system = value.length == 6 ? '0' : value[0];
    if (system != '0' && system != '1') return null;
    final d = value.length == 6 ? value : value.substring(1, 7);
    final body = switch (d[5]) {
      '0' || '1' || '2' => '${d[0]}${d[1]}${d[5]}0000${d[2]}${d[3]}${d[4]}',
      '3' => '${d[0]}${d[1]}${d[2]}00000${d[3]}${d[4]}',
      '4' => '${d[0]}${d[1]}${d[2]}${d[3]}00000${d[4]}',
      _ => '${d[0]}${d[1]}${d[2]}${d[3]}${d[4]}0000${d[5]}',
    };
    final withoutCheck = '$system$body';
    final check = _checkDigit(withoutCheck);
    if (value.length == 8 && value.codeUnitAt(7) - 48 != check) return null;
    return '$withoutCheck$check';
  }

  static int _checkDigit(String body) {
    var sum = 0;
    for (
      var i = body.length - 1, weight = 3;
      i >= 0;
      i--, weight = 4 - weight
    ) {
      sum += (body.codeUnitAt(i) - 48) * weight;
    }
    return (10 - sum % 10) % 10;
  }
}
