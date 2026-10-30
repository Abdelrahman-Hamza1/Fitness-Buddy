import 'package:material_ui/material_ui.dart';

/// The direction a chat message is laid out in (D-080, backlog #144), by
/// its first strong character (the Unicode bidi "first strong" rule):
/// right to left for a Hebrew or Arabic-script letter (bidi class R/AL),
/// left to right for a Latin, Greek or Cyrillic letter (L), else `null`
/// (the UI's direction).
///
/// Everything else is skipped as weak or neutral: digits (Western and
/// Arabic-Indic), Arabic punctuation (، ؛ ؟), combining marks and harakat,
/// spaces, symbols and emoji. Arabizi is written in Latin letters, so it
/// stays left to right.
TextDirection? messageDirection(String text) {
  for (final rune in text.runes) {
    if (_strongRtl(rune)) return TextDirection.rtl;
    if (_strongLtr(rune)) return TextDirection.ltr;
  }
  return null;
}

bool _strongRtl(int c) =>
    // Hebrew letters and ligatures.
    (c >= 0x05D0 && c <= 0x05EA) ||
    (c >= 0x05EF && c <= 0x05F2) ||
    (c >= 0xFB1D && c <= 0xFB4F && c != 0xFB1E) ||
    // Arabic letters (not punctuation, digits or marks).
    (c >= 0x0620 && c <= 0x064A) ||
    (c >= 0x066E && c <= 0x066F) ||
    (c >= 0x0671 && c <= 0x06D3) ||
    c == 0x06D5 ||
    (c >= 0x06E5 && c <= 0x06E6) ||
    (c >= 0x06EE && c <= 0x06EF) ||
    (c >= 0x06FA && c <= 0x06FF) ||
    (c >= 0x0750 && c <= 0x077F) ||
    (c >= 0x08A0 && c <= 0x08C9) ||
    // Arabic presentation forms.
    (c >= 0xFB50 && c <= 0xFD3D) ||
    (c >= 0xFD50 && c <= 0xFDFB) ||
    (c >= 0xFE70 && c <= 0xFEFC);

bool _strongLtr(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0xC0 && c <= 0x024F && c != 0xD7 && c != 0xF7) ||
    (c >= 0x0370 && c <= 0x03FF) ||
    (c >= 0x0400 && c <= 0x04FF);
