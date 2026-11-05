/// Whether [unit] is a Western (0–9), Arabic-Indic (٠–٩) or Persian
/// (۰–۹) digit.
bool isAnyDigit(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x660 && unit <= 0x669) ||
    (unit >= 0x6f0 && unit <= 0x6f9);

/// [text] with Arabic-Indic and Persian digits replaced by ASCII digits
/// (A57 A60): a keyboard set to Arabic types "٤٨١", which is the code
/// "481". Everything else is kept.
String normalizeDigits(String text) {
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    if (unit >= 0x660 && unit <= 0x669) {
      out.writeCharCode(0x30 + unit - 0x660);
    } else if (unit >= 0x6f0 && unit <= 0x6f9) {
      out.writeCharCode(0x30 + unit - 0x6f0);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}
