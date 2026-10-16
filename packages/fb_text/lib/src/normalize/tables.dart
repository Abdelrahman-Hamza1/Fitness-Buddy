/// The character tables of the search-key normalization (S08 D11, A1–A3).
///
/// These tables are the specification. The C# Catalog module (B07) uses the
/// same tables, so both sides give the same bytes (TD-030). No Unicode
/// normalization (NFD) and no locale or Unicode case APIs are used anywhere.
/// The tables are also listed in `contracts/testdata/README.md`: change both
/// together, and add a golden case for every change.
library;

/// Step 1, first: the first code point of the fullwidth ASCII forms
/// (U+FF01–U+FF5E, `！`–`～`), folded to ASCII U+0021–U+007E by subtracting
/// [fullwidthOffset]. So `ＲＩＣＥ` is read as `RICE` and `１００` as `100`.
const int fullwidthFirst = 0xFF01;

/// Step 1, first: the last fullwidth ASCII form (U+FF5E `～`).
const int fullwidthLast = 0xFF5E;

/// Step 1, first: fullwidth form − [fullwidthOffset] = the ASCII character.
const int fullwidthOffset = 0xFEE0;

/// Step 1, first: the Latin ligatures U+FB00–U+FB06 → their letters, so
/// `ﬁsh` is read as `fish`.
const Map<int, String> latinLigatures = {
  0xFB00: 'ff', // ﬀ
  0xFB01: 'fi', // ﬁ
  0xFB02: 'fl', // ﬂ
  0xFB03: 'ffi', // ﬃ
  0xFB04: 'ffl', // ﬄ
  0xFB05: 'st', // ﬅ (long s + t)
  0xFB06: 'st', // ﬆ
};

/// Step 1, then: invisible format characters and apostrophes, deleted.
///
/// Deleting (instead of turning them into spaces) keeps a word in one piece:
/// "don't" → "dont", and a ZWNJ inside an Arabic word doesn't split it.
const Set<int> deletedCharacters = {
  0x00AD, // soft hyphen
  0x061C, // Arabic letter mark
  0x200B, // zero width space
  0x200C, // zero width non-joiner
  0x200D, // zero width joiner
  0x200E, // left-to-right mark
  0x200F, // right-to-left mark
  0x202A, // left-to-right embedding
  0x202B, // right-to-left embedding
  0x202C, // pop directional formatting
  0x202D, // left-to-right override
  0x202E, // right-to-left override
  0x2060, // word joiner
  0x2066, // left-to-right isolate
  0x2067, // right-to-left isolate
  0x2068, // first strong isolate
  0x2069, // pop directional isolate
  0xFEFF, // byte order mark
  0x0027, // ' apostrophe
  0x0060, // ` grave accent
  0x02BC, // ʼ modifier letter apostrophe
  0x2018, // ‘ left single quotation mark
  0x2019, // ’ right single quotation mark
};

/// Step 2: the first code point of the Arabic-Indic digits ٠–٩
/// (U+0660–U+0669), folded to ASCII 0–9.
const int arabicIndicZero = 0x0660;

/// Step 2: the first code point of the Persian (Extended Arabic-Indic) digits
/// ۰–۹ (U+06F0–U+06F9), folded to ASCII 0–9.
const int persianZero = 0x06F0;

/// Step 3: whether [rune] is an Arabic mark that is deleted: tashkeel
/// U+064B–U+065F (including hamza above/below and madda), the superscript
/// alef U+0670, the Quranic marks U+06D6–U+06ED, and tatweel U+0640.
bool isDeletedArabicMark(int rune) =>
    (rune >= 0x064B && rune <= 0x065F) ||
    rune == 0x0670 ||
    (rune >= 0x06D6 && rune <= 0x06ED) ||
    rune == 0x0640;

/// Step 4: Arabic letter folds.
const Map<int, String> arabicLetterFolds = {
  // Lam-alef ligatures (presentation forms) → لا.
  0xFEF5: 'لا', // ﻵ
  0xFEF6: 'لا', // ﻶ
  0xFEF7: 'لا', // ﻷ
  0xFEF8: 'لا', // ﻸ
  0xFEF9: 'لا', // ﻹ
  0xFEFA: 'لا', // ﻺ
  0xFEFB: 'لا', // ﻻ
  0xFEFC: 'لا', // ﻼ
  // Alef forms → ا.
  0x0622: 'ا', // آ
  0x0623: 'ا', // أ
  0x0625: 'ا', // إ
  0x0671: 'ا', // ٱ
  // Teh marbuta → heh, alef maksura → yeh.
  0x0629: 'ه', // ة
  0x0649: 'ي', // ى
  // Hamza on a seat → the seat (A3). A standalone ء stays.
  0x0626: 'ي', // ئ
  0x0624: 'و', // ؤ
  // Persian and loanword letters → the Arabic letter people type instead.
  0x06A9: 'ك', // ک keheh
  0x06CC: 'ي', // ی Farsi yeh
  0x06A4: 'ف', // ڤ veh
  0x067E: 'ب', // پ peh
  0x0686: 'ج', // چ tcheh
  0x06AF: 'ك', // گ gaf
};

/// Step 5: Latin letters with accents (all of Latin-1 Supplement and Latin
/// Extended-A except × and ÷) → lowercase ASCII, as groups: every character
/// of a value folds to its key.
const Map<String, String> latinFoldGroups = {
  'a': 'ÀÁÂÃÄÅàáâãäåĀāĂăĄą',
  'ae': 'Ææ',
  'c': 'ÇçĆćĈĉĊċČč',
  'd': 'ÐðĎďĐđ',
  'e': 'ÈÉÊËèéêëĒēĔĕĖėĘęĚě',
  'g': 'ĜĝĞğĠġĢģ',
  'h': 'ĤĥĦħ',
  'i': 'ÌÍÎÏìíîïĨĩĪīĬĭĮįİı',
  'ij': 'Ĳĳ',
  'j': 'Ĵĵ',
  'k': 'Ķķĸ',
  'l': 'ĹĺĻļĽľĿŀŁł',
  'n': 'ÑñŃńŅņŇňŉŊŋ',
  'o': 'ÒÓÔÕÖØòóôõöøŌōŎŏŐő',
  'oe': 'Œœ',
  'r': 'ŔŕŖŗŘř',
  's': 'ŚśŜŝŞşŠšſ',
  'ss': 'ß',
  't': 'ŢţŤťŦŧ',
  'th': 'Þþ',
  'u': 'ÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲų',
  'w': 'Ŵŵ',
  'y': 'ÝýÿŶŷŸ',
  'z': 'ŹźŻżŽž',
};

/// [latinFoldGroups] as a lookup from code point to its ASCII fold.
final Map<int, String> latinFolds = {
  for (final MapEntry(key: ascii, value: letters) in latinFoldGroups.entries)
    for (final rune in letters.runes) rune: ascii,
};

/// Step 5: whether [rune] is a combining diacritical mark (U+0300–U+036F),
/// deleted.
bool isCombiningMark(int rune) => rune >= 0x0300 && rune <= 0x036F;

/// Step 6: whether [rune] is in the allowed set (A2): `a`–`z`, `0`–`9`, the
/// space, and the Arabic letters U+0621–U+063A and U+0641–U+064A. Every
/// other character becomes a space.
bool isKeyCharacter(int rune) =>
    (rune >= 0x61 && rune <= 0x7A) ||
    (rune >= 0x30 && rune <= 0x39) ||
    rune == 0x20 ||
    isKeyArabicLetter(rune);

/// Whether [rune] is an Arabic letter of the allowed set (U+0621–U+063A,
/// U+0641–U+064A).
bool isKeyArabicLetter(int rune) =>
    (rune >= 0x0621 && rune <= 0x063A) || (rune >= 0x0641 && rune <= 0x064A);

/// Step 7: the Arabic long vowels ا و ي. A run of 2 or more collapses to
/// one, like a Latin letter. Any other Arabic letter collapses only from a
/// run of 3, so a real double letter (اللبن, مملح) survives (A1).
const Set<int> arabicLongVowels = {0x0627, 0x0648, 0x064A};
