import 'package:fb_text/src/normalize/tables.dart';

/// The search key of [input]: the text both the index and the query are
/// reduced to before they are compared (S08 D11 with A1–A3, TD-030).
///
/// The steps run in this fixed order (the same order is written in
/// `contracts/testdata/README.md`, which the C# side follows):
///
/// 1. Fold fullwidth ASCII and Latin ligatures ([foldCompatibility]), then
///    delete invisible format characters and apostrophes.
/// 2. Fold Arabic-Indic and Persian digits to ASCII ([foldDigits]).
/// 3. Delete tashkeel and tatweel, then 4. fold Arabic letters
///    ([foldArabic]).
/// 5. Lowercase ASCII and fold accented Latin letters with the explicit
///    table, delete combining marks ([foldLatin]).
/// 6. Turn every character outside the allowed set into a space.
/// 7. Collapse repeated letters ([collapseRepeats]).
/// 8. Collapse runs of spaces to one and trim.
///
/// The key is a fixed point: `normalizeKey(normalizeKey(s)) ==
/// normalizeKey(s)` for every `s`.
String normalizeKey(String input) => _key(input, latinRepeats: true);

/// A strict food identity key (FD-021): search folding without collapsing
/// Latin repeats, so coffee and cofe remain distinct.
String identityKey(String input) => _key(input, latinRepeats: false);

String _key(String input, {required bool latinRepeats}) {
  final folded = foldLatin(
    foldArabic(foldDigits(_deleteInvisibles(foldCompatibility(input)))),
  );
  final allowed = _map(
    folded,
    (rune, out) => out.writeCharCode(isKeyCharacter(rune) ? rune : _space),
  );
  return _collapseSpaces(_collapseRepeats(allowed, latin: latinRepeats));
}

/// [text] with fullwidth ASCII forms (U+FF01–U+FF5E) replaced by ASCII and
/// the Latin ligatures U+FB00–U+FB06 replaced by their letters. Everything
/// else is kept (the first half of step 1).
String foldCompatibility(String text) => _map(text, (rune, out) {
  if (rune >= fullwidthFirst && rune <= fullwidthLast) {
    out.writeCharCode(rune - fullwidthOffset);
    return;
  }
  final ligature = latinLigatures[rune];
  if (ligature != null) {
    out.write(ligature);
  } else {
    out.writeCharCode(rune);
  }
});

/// [text] with Arabic-Indic (٠–٩) and Persian (۰–۹) digits replaced by ASCII
/// digits. Everything else is kept (step 2).
String foldDigits(String text) => _map(text, (rune, out) {
  if (rune >= arabicIndicZero && rune <= arabicIndicZero + 9) {
    out.writeCharCode(_zero + rune - arabicIndicZero);
  } else if (rune >= persianZero && rune <= persianZero + 9) {
    out.writeCharCode(_zero + rune - persianZero);
  } else {
    out.writeCharCode(rune);
  }
});

/// [text] without tashkeel and tatweel, with the Arabic letter folds applied
/// (lam-alef ligatures, alef forms, ة → ه, ى → ي, ئ → ي, ؤ → و, Persian
/// letters). Everything else is kept (steps 3 and 4).
String foldArabic(String text) => _map(text, (rune, out) {
  if (isDeletedArabicMark(rune)) return;
  final fold = arabicLetterFolds[rune];
  if (fold != null) {
    out.write(fold);
  } else {
    out.writeCharCode(rune);
  }
});

/// [text] with ASCII `A`–`Z` lowercased, accented Latin letters folded to
/// ASCII by the explicit table, and combining marks deleted. Everything else
/// is kept (step 5). Locale independent: `İ` → `i`, never `i̇`.
String foldLatin(String text) => _map(text, (rune, out) {
  if (rune >= _upperA && rune <= _upperZ) {
    out.writeCharCode(rune + _lowerA - _upperA);
    return;
  }
  if (isCombiningMark(rune)) return;
  final fold = latinFolds[rune];
  if (fold != null) {
    out.write(fold);
  } else {
    out.writeCharCode(rune);
  }
});

/// [text] with repeated letters collapsed (step 7, A1): a run of 2 or more
/// identical Latin letters `a`–`z` or Arabic long vowels ا و ي becomes one,
/// a run of 3 or more of any other Arabic letter becomes one (a run of 2
/// stays, so اللبن ≠ البن). Digits and every other character are kept.
String collapseRepeats(String text) => _collapseRepeats(text, latin: true);

String _collapseRepeats(String text, {required bool latin}) {
  final out = StringBuffer();
  final runes = text.runes.toList();
  var start = 0;
  while (start < runes.length) {
    final rune = runes[start];
    var end = start + 1;
    while (end < runes.length && runes[end] == rune) {
      end++;
    }
    final length = end - start;
    final collapse =
        (latin && rune >= _lowerA && rune <= _lowerZ) ||
        arabicLongVowels.contains(rune) ||
        (isKeyArabicLetter(rune) && length >= 3);
    for (var i = 0; i < (collapse ? 1 : length); i++) {
      out.writeCharCode(rune);
    }
    start = end;
  }
  return out.toString();
}

/// Step 1, after [foldCompatibility].
String _deleteInvisibles(String text) => _map(text, (rune, out) {
  if (!deletedCharacters.contains(rune)) out.writeCharCode(rune);
});

/// Step 8: runs of spaces → one space, no space at either end. After step 6
/// the only whitespace left is U+0020.
String _collapseSpaces(String text) =>
    text.split(' ').where((word) => word.isNotEmpty).join(' ');

/// Calls [write] for every code point of [text] and returns what it wrote.
String _map(String text, void Function(int rune, StringBuffer out) write) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    write(rune, out);
  }
  return out.toString();
}

const int _space = 0x20;
const int _zero = 0x30;
const int _upperA = 0x41;
const int _upperZ = 0x5A;
const int _lowerA = 0x61;
const int _lowerZ = 0x7A;
