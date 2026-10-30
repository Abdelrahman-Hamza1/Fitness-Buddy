import 'dart:io';

import 'package:glados/glados.dart';

/// Runs per property test: 100 by default (push, PR and laptop), 1,000 when
/// `PROPERTY_RUNS=1000` is set (CI's nightly and manual runs; TD-104, which
/// amends S08 D14). Never lower it in a single test.
final int propertyRunCount =
    int.tryParse(Platform.environment['PROPERTY_RUNS'] ?? '') ?? 100;

/// The explore settings every property test uses. A fresh value per test, so
/// each test has its own seeded random and doesn't depend on test order.
ExploreConfig get propertyRuns => ExploreConfig(numRuns: propertyRunCount);

/// Code point ranges (inclusive) the text generator draws from: every
/// character class the normalization treats differently, plus ones it must
/// turn into spaces.
const _ranges = <(int, int)>[
  (0x20, 0x7E), // ASCII printable
  (0x09, 0x0D), // ASCII whitespace controls
  (0x00A0, 0x00FF), // Latin-1 Supplement (NBSP, symbols, accented letters)
  (0x0100, 0x017F), // Latin Extended-A
  (0x0300, 0x036F), // combining marks
  (0x0400, 0x04FF), // Cyrillic
  (0x0600, 0x06FF), // Arabic (letters, tashkeel, digits, Persian letters)
  (0x0621, 0x064A), // Arabic letters again, so they are frequent
  (0x2000, 0x206F), // General Punctuation (spaces, invisibles, quotes)
  (0xFB50, 0xFDFF), // Arabic Presentation Forms-A
  (0xFE70, 0xFEFF), // Arabic Presentation Forms-B (lam-alef, BOM)
  (0xFB00, 0xFB06), // Latin ligatures (ﬀ ﬁ ﬂ ﬃ ﬄ ﬅ ﬆ)
  (0xFF01, 0xFF5E), // fullwidth ASCII
  (0x1F300, 0x1F64F), // emoji (outside the BMP: surrogate pairs)
  (0x0627, 0x0627), // ا
  (0x0648, 0x0648), // و
  (0x064A, 0x064A), // ي
  (0x0644, 0x0644), // ل
  (0x0061, 0x0061), // a
  (0x0031, 0x0031), // 1
  (0x0020, 0x0020), // space
];

/// Generators for normalization input.
extension TextAnys on Any {
  /// One code point from [_ranges], repeated 1 to 4 times so runs are common.
  Generator<String> get textPiece => combine3(
    intInRange(0, _ranges.length),
    intInRange(0, 1 << 20),
    intInRange(1, 5),
    (range, offset, repeat) {
      final (first, last) = _ranges[range];
      return String.fromCharCode(first + offset % (last - first + 1)) * repeat;
    },
  );

  /// Arbitrary Arabic, Latin, digit, symbol and invisible text, up to 40
  /// pieces long.
  Generator<String> get anyText =>
      listWithLengthInRange(0, 40, textPiece).map((pieces) => pieces.join());
}
