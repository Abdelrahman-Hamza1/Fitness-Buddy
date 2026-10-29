import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/presentation/utf16_length_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  final formatter = Utf16LengthLimitingFormatter(ChatText.composerLimit);

  // rule: A22 composer-limit
  test('A22 composer caps input at 1000 UTF-16 units', () {
    // Plain text past the limit is cut at 1000 units.
    final long = formatter.formatEditUpdate(
      TextEditingValue.empty,
      _value('a' * 1200),
    );
    expect(long.text.length, 1000);
    expect(long.selection.baseOffset, 1000);

    // An emoji (two units) straddling the limit is dropped whole, never
    // split into a lone surrogate.
    final straddle = formatter.formatEditUpdate(
      TextEditingValue.empty,
      _value('${'a' * 999}🍎'),
    );
    expect(straddle.text, 'a' * 999);
    expect(ChatText.isWellFormed(straddle.text), isTrue);

    // Exactly at the limit with an emoji at the end: kept.
    final exact = '${'a' * 998}🍎';
    expect(
      formatter.formatEditUpdate(TextEditingValue.empty, _value(exact)).text,
      exact,
    );

    // 500 emoji are 1000 units (Flutter's maxLength would count 500).
    final emoji = '🍎' * 600;
    final capped = formatter.formatEditUpdate(
      TextEditingValue.empty,
      _value(emoji),
    );
    expect(capped.text.length, 1000);
    expect(capped.text.runes.length, 500);

    // Full: typing more keeps the old text.
    final full = _value('a' * 1000);
    expect(formatter.formatEditUpdate(full, _value('${'a' * 1000}b')), full);
  });
}
