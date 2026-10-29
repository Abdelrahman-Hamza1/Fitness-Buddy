import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

/// Pieces that hit every UTF-16 case: ASCII, Arabic (BMP), a supplementary
/// pair, U+0000, lone high and low surrogates, a reversed pair and U+FFFD.
const _pieces = [
  'x',
  ' ',
  'ب',
  '🍎',
  '\u0000',
  '\uD800',
  '\uDBFF',
  '\uDC00',
  '\uDFFF',
  '\uDC00\uD800',
  '�',
];

extension on Any {
  /// Text from the pieces above, up to 40 of them.
  Generator<String> get chatText => listWithLengthInRange(
    0,
    41,
    choose(_pieces),
  ).map((pieces) => pieces.join());

  /// Text from admissible pieces only (no U+0000, no lone surrogates).
  Generator<String> get wellFormedText => listWithLengthInRange(
    0,
    41,
    choose(const ['x', ' ', 'ب', '🍎', '�']),
  ).map((pieces) => pieces.join());
}

/// Independent oracle: drop U+0000, replace lone surrogates (Dart's `runes`
/// yields them as their own values), then keep whole code points while they
/// fit in [limit] units.
String _expected(String text, int limit) {
  final out = StringBuffer();
  var units = 0;
  for (final rune in text.runes) {
    if (rune == 0) continue;
    final point = rune >= 0xD800 && rune <= 0xDFFF ? 0xFFFD : rune;
    final width = point > 0xFFFF ? 2 : 1;
    if (units + width > limit) break;
    out.writeCharCode(point);
    units += width;
  }
  return out.toString();
}

void main() {
  // rule: A22 chat-text
  group('A22 chat text sanitizer keeps UTF-16 bounds without splitting '
      'surrogate pairs', () {
    Glados2(any.chatText, any.intInRange(0, 60), propertyRuns).test(
      'sanitize equals the code-point oracle and is admissible',
      (text, limit) {
        final clean = ChatText.sanitize(text, limit: limit);
        expect(clean, _expected(text, limit));
        expect(clean.length, lessThanOrEqualTo(limit));
        expect(clean, isNot(contains('\u0000')));
        expect(ChatText.isWellFormed(clean), isTrue);
        expect(ChatText.admits(clean, limit: limit), isTrue);
        expect(ChatText.sanitize(clean, limit: limit), clean);
      },
    );

    // The real limits, with the random tail straddling the boundary.
    for (final limit in [ChatText.storedLimit, ChatText.composerLimit]) {
      Glados2(any.intInRange(0, 9), any.chatText, propertyRuns).test(
        'sanitize at the $limit-unit limit',
        (short, tail) {
          final text = 'x' * (limit - short) + tail;
          final clean = ChatText.sanitize(text, limit: limit);
          expect(clean, _expected(text, limit));
          expect(ChatText.admits(clean, limit: limit), isTrue);
          // Never more than one unit short: only a pair that doesn't fit is
          // left out whole.
          final repaired = _expected(text, text.length * 2);
          expect(
            clean.length,
            greaterThanOrEqualTo(
              (repaired.length < limit ? repaired.length : limit) - 1,
            ),
          );
        },
      );

      Glados2(any.intInRange(0, 9), any.wellFormedText, propertyRuns).test(
        'truncate keeps a well-formed prefix at the $limit-unit limit',
        (short, tail) {
          final text = 'x' * (limit - short) + tail;
          final cut = ChatText.truncate(text, limit);
          expect(text.startsWith(cut), isTrue);
          expect(cut.length, lessThanOrEqualTo(limit));
          expect(ChatText.isWellFormed(cut), isTrue);
          expect(
            cut.length,
            greaterThanOrEqualTo(
              (text.length < limit ? text.length : limit) - 1,
            ),
          );
          if (ChatText.admits(text, limit: limit)) expect(cut, text);
        },
      );
    }

    Glados(any.wellFormedText, propertyRuns).test(
      'admissible text within the limit is kept unchanged',
      (text) {
        expect(ChatText.admits(text, limit: 200), isTrue);
        expect(ChatText.sanitize(text, limit: 200), text);
        expect(ChatText.truncate(text, 200), text);
      },
    );

    test('boundaries with a supplementary character', () {
      const apple = '🍎';
      final fits = 'x' * 8190 + apple;
      expect(fits.length, 8192);
      expect(ChatText.sanitize(fits), fits);
      expect(ChatText.admits(fits), isTrue);
      final over = 'x' * 8191 + apple;
      expect(ChatText.admits(over), isFalse);
      expect(ChatText.sanitize(over), 'x' * 8191);
      expect(ChatText.sanitize('x' * 8193), 'x' * 8192);
      final composer = 'x' * 999 + apple;
      expect(ChatText.truncate(composer, ChatText.composerLimit), 'x' * 999);
      expect(ChatText.truncate('x' * 998 + apple, 1000), 'x' * 998 + apple);
      expect(ChatText.truncate('x' * 1001, 1000), 'x' * 1000);
      expect(ChatText.composerLimit, 1000);
      expect(ChatText.storedLimit, ChatProposalSyncBounds.text);
    });

    test('U+0000 is stripped and lone surrogates become U+FFFD', () {
      expect(ChatText.sanitize('a\u0000b'), 'ab');
      expect(ChatText.sanitize('a\uD800b'), 'a�b');
      expect(ChatText.sanitize('\uDC00\uD800'), '��');
      expect(ChatText.sanitize('\uD800'), '�');
      expect(ChatText.sanitize('🍎\uD83C'), '🍎�');
      expect(ChatText.isWellFormed('\uD83C'), isFalse);
      expect(ChatText.isWellFormed('\uDF4E'), isFalse);
      expect(ChatText.isWellFormed('🍎'), isTrue);
      expect(ChatText.admits('a\u0000'), isFalse);
      expect(ChatText.admits(''), isTrue);
      expect(ChatText.sanitize('abc', limit: 0), '');
      expect(() => ChatText.sanitize('a', limit: -1), throwsArgumentError);
      expect(() => ChatText.truncate('a', -1), throwsArgumentError);
    });
  });
}
