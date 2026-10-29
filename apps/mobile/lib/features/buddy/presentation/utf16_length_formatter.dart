import 'package:fb_domain/fb_domain.dart';
import 'package:flutter/services.dart';

/// Caps text at [maxUnits] UTF-16 code units, never splitting a surrogate
/// pair (A22 D7). Flutter's `maxLength` counts characters (grapheme
/// clusters), so emoji-heavy text could exceed the server's 1,000-unit
/// limit; this counts what the server counts.
final class Utf16LengthLimitingFormatter extends TextInputFormatter {
  /// A formatter for [maxUnits] units.
  new(this.maxUnits) : assert(maxUnits > 0, 'max');

  /// The most UTF-16 code units the text may hold.
  final int maxUnits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= maxUnits) return newValue;
    // Already full with nothing selected: typing adds nothing (as Flutter's
    // own length limit does).
    if (oldValue.text.length >= maxUnits && oldValue.selection.isCollapsed) {
      return oldValue;
    }
    final text = ChatText.truncate(newValue.text, maxUnits);
    int clamp(int offset) => offset.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: newValue.selection.copyWith(
        baseOffset: clamp(newValue.selection.baseOffset),
        extentOffset: clamp(newValue.selection.extentOffset),
      ),
    );
  }
}
