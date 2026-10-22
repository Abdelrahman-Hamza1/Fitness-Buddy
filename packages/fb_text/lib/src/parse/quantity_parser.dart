import 'package:fb_text/src/normalize/normalizer.dart';
import 'package:fb_text/src/normalize/tables.dart';
import 'package:fb_text/src/parse/number_words.dart';
import 'package:fb_text/src/parse/unit_words.dart';

/// A quantity read from food text by [parseQuantity] (S08 D12).
///
/// "2 رغيف عيش" is `amount` 2, `unitCode` `loaf`, `rest` "عيش". Text with
/// no quantity is [ParsedQuantity.none]: one of the food, no unit, and
/// [amountImplicit] set ([hasQuantity] is false).
///
/// The split is a hypothesis, not a fact: some food names start or end
/// with a number or a portion word (حبة البركة, سبع بهارات, 7 Up, omega 3,
/// chicken 65). Callers try a catalog match on the whole text ([original])
/// before they trust [rest] and the quantity.
final class ParsedQuantity {
  /// A quantity with an [amount], an optional [unitCode], the food text
  /// ([rest]) and the whole text it was read from ([original]).
  const new({
    required this.amount,
    required this.rest,
    required this.original,
    this.unitCode,
    this.amountImplicit = false,
  });

  /// No quantity in the text: [rest] is all of it, the amount is one.
  const new none(this.rest)
    : amount = 1,
      unitCode = null,
      amountImplicit = true,
      original = rest;

  /// How many [unitCode]s, or how many of the food if there is no unit.
  /// Always greater than zero.
  final double amount;

  /// The unit as a plain code (one of [parsedUnitCodes]), or `null` when
  /// the text only counts ("2 eggs").
  final String? unitCode;

  /// Whether no number was given and [amount] is the assumed one ("cup of
  /// rice", "رغيف عيش", or no quantity at all). A dual (رغيفين) or "a"/"an"
  /// is a number.
  final bool amountImplicit;

  /// The food text: the input without the quantity, as typed (not
  /// normalized), without the separators around it.
  final String rest;

  /// The whole text as typed, quantity included, without the separators
  /// around it ("2 رغيف عيش"). Equal to [rest] when there is no quantity.
  /// Match it against the catalog before trusting the split.
  final String original;

  /// Whether the text had a quantity: a number, a unit, or both.
  bool get hasQuantity => !amountImplicit || unitCode != null;

  @override
  bool operator ==(Object other) =>
      other is ParsedQuantity &&
      other.amount == amount &&
      other.unitCode == unitCode &&
      other.amountImplicit == amountImplicit &&
      other.rest == rest &&
      other.original == original;

  @override
  int get hashCode =>
      Object.hash(amount, unitCode, amountImplicit, rest, original);

  @override
  String toString() =>
      'ParsedQuantity($amount ${unitCode ?? '-'}'
      '${amountImplicit ? ' implicit' : ''}, "$rest")';
}

/// The number [text] spells, or `null` if [text] is anything more or less
/// than one number (S08 D12).
///
/// Accepts digits (also Arabic-Indic, Persian and fullwidth), `.` and `٫` as
/// the decimal point, `,` as the decimal point when 1–2 digits follow it
/// (else as a thousands separator in groups of 3), the fractions ½ ¼ ¾ ⅓ ⅔
/// and `1/2`, mixed numbers (`1 1/2`, `1½`), English words up to 999
/// ("two hundred and fifty", "three quarters", "a dozen"), Arabic words 1–10
/// and fractions in MSA and dialect spellings (تلاتة, ثلاثة, نص, ربع,
/// تلت), a few Arabizi words (wa7ed, etnen, nos, rob3), and added fractions
/// ("two and a half", "تلاتة ونص").
double? parseNumber(String text) {
  final chunks = _chunks(text);
  if (chunks.isEmpty ||
      !_isBlank(text.substring(0, chunks.first.start)) ||
      !_isBlank(text.substring(chunks.last.end))) {
    return null;
  }
  try {
    final number = _Reader(chunks).number(0, atStart: true);
    return number != null && number.next == chunks.length ? number.value : null;
  } on _Unparseable {
    return null;
  }
}

/// The quantity at the start or the end of [text], and the food text
/// around it (S08 D12, LC-011, LC-051).
///
/// A quantity is a number, a unit, or a number and a unit, in any of the
/// forms of [parseNumber]: "8 oz chicken", "chicken 150g", "2 cups of rice",
/// "نص كيلو لحمة", "رغيفين عيش" (the Arabic dual is two), "ملعقة صغيرة
/// سكر" (a teaspoon), "كيلو ونص طماطم". A unit without a number is one of
/// it: at the start only for Arabic words ("رغيف عيش") or before "of"
/// ("cup of tea"), so "pound cake" stays a food. At the end a quantity needs
/// a digit or a unit ("eggs 2", "rice 1 cup"), so "Coke Zero" stays a food.
///
/// When a unit word without a number starts the text and a number with a
/// unit ends it, the end wins and the start stays in the food text
/// ("حبة البركة ٥ غرام" is 5 g of "حبة البركة").
///
/// Returns [ParsedQuantity.none] when there is no quantity, and `null` when
/// the text can't be read: no food text left, a range ("2-3 eggs", "two or
/// three eggs"), a quantity at both ends or two numbers in a row (several
/// items: Buddy handles them), a zero or negative amount ("0 g sugar"), a
/// microgram unit (µg, mcg: not a unit the parser knows, and never grams),
/// or a malformed number ("1/0").
///
/// The split is a hypothesis: a food name can look like a quantity
/// ("حبة البركة" reads as one piece of "البركة", "7 Up" as seven "Up").
/// Callers match [ParsedQuantity.original] (the whole text) against the
/// catalog before they trust [ParsedQuantity.rest].
ParsedQuantity? parseQuantity(String text) {
  final chunks = _chunks(text);
  if (chunks.isEmpty) return null;
  final reader = _Reader(chunks);
  final original = _rest(text, chunks, 0, chunks.length);
  try {
    final atStart = reader.quantity(0, atStart: true);
    if (atStart != null) {
      final from = atStart.next;
      if (from == chunks.length || reader.startsNumber(from)) return null;
      final atEnd = reader.quantityAtEnd(from + 1);
      if (atEnd != null) {
        final end = atEnd.quantity;
        // A bare portion word at the start is likely part of the name.
        if (!atStart.implicit || end.implicit || end.unitCode == null) {
          return null;
        }
        return end.result(_rest(text, chunks, 0, atEnd.from), original);
      }
      return atStart.result(_rest(text, chunks, from, chunks.length), original);
    }
    final atEnd = reader.quantityAtEnd(1);
    if (atEnd != null) {
      return atEnd.quantity.result(
        _rest(text, chunks, 0, atEnd.from),
        original,
      );
    }
    return ParsedQuantity.none(original);
  } on _Unparseable {
    return null;
  }
}

/// The text has a number the parser can't use (a range, two numbers in a
/// row, "1/0"), so [parseQuantity] gives up rather than guess.
final class _Unparseable implements Exception {
  const new();
}

/// A number read from the chunks before `next`.
typedef _Number = ({
  double value,
  int next,
  // Spelled in words (no digit): not a quantity on its own at the end.
  bool words,
  // A fraction word alone ("half"), which may take "a" ("half a cup").
  bool fraction,
});

/// A unit read from the chunks before `next`.
typedef _UnitMatch = ({_Unit unit, int next});

/// A unit word: its code, whether it is an Arabic dual (two of it), and
/// whether it may start the text without a number.
typedef _Unit = ({String code, bool dual, bool bare});

/// A quantity read from the chunks before `next`.
final class _Quantity {
  const new(this.amount, this.unitCode, {required this.next})
    : implicit = false;

  const new implicit(this.unitCode, {required this.next})
    : amount = 1,
      implicit = true;

  final double amount;
  final String? unitCode;
  final bool implicit;
  final int next;

  _Quantity withAmount(double amount, {required int next}) =>
      _Quantity(amount, unitCode, next: next);

  _Quantity withNext(int next) => implicit
      ? _Quantity.implicit(unitCode, next: next)
      : _Quantity(amount, unitCode, next: next);

  /// The parse, or `null` for a zero or negative amount ("0 g sugar").
  ParsedQuantity? result(String rest, String original) => amount > 0
      ? ParsedQuantity(
          amount: amount,
          unitCode: unitCode,
          amountImplicit: implicit,
          rest: rest,
          original: original,
        )
      : null;
}

/// The grammar of D12 over a list of chunks.
final class _Reader {
  new(this.chunks);

  final List<_Chunk> chunks;

  /// The quantity that starts at `from` and runs to the end of the text,
  /// for the smallest `from` at or after [first], with the index it starts
  /// at.
  ({_Quantity quantity, int from})? quantityAtEnd(int first) {
    for (var from = first; from < chunks.length; from++) {
      final quantity = this.quantity(from, atStart: false);
      if (quantity != null && quantity.next == chunks.length) {
        return (quantity: quantity, from: from);
      }
    }
    return null;
  }

  /// The quantity at chunk [i]: a glued number and unit ("150g"), a number
  /// with an optional unit, or a unit alone. [atStart] allows the things
  /// only the start of the text may have: "a"/"an", a bare unit, "of".
  _Quantity? quantity(int i, {required bool atStart}) {
    final found = _glued(i) ?? _numberAndUnit(i, atStart: atStart);
    if (found != null) return found;
    final match = unit(i);
    if (match == null || _in(_numberOnlyUnits, i)) return null;
    var quantity = match.unit.dual
        ? _Quantity(2, match.unit.code, next: match.next)
        : _Quantity.implicit(match.unit.code, next: match.next);
    if (!match.unit.dual && _in(_oneAfterUnit, quantity.next)) {
      quantity = _Quantity(1, match.unit.code, next: quantity.next + 1);
    }
    quantity = _addFraction(quantity);
    final of = atStart && _in(_of, quantity.next);
    if (of) quantity = quantity.withNext(quantity.next + 1);
    final allowed = !quantity.implicit || (atStart && (match.unit.bare || of));
    return allowed ? quantity : null;
  }

  /// A number at [i] with the unit after it, if any.
  _Quantity? _numberAndUnit(int i, {required bool atStart}) {
    final number = this.number(i, atStart: atStart);
    if (number == null) return null;
    final match = unit(number.next);
    if (match == null) {
      // At the end a bare number must be digits: "Coke Zero" is a food, and
      // so is "zero sugar cola".
      if (number.words && (!atStart || number.value == 0)) return null;
      return _Quantity(number.value, null, next: number.next);
    }
    final quantity = _addFraction(
      _Quantity(number.value, match.unit.code, next: match.next),
    );
    return atStart && _in(_of, quantity.next)
        ? quantity.withNext(quantity.next + 1)
        : quantity;
  }

  /// A chunk that is a number with a unit glued to it ("150g", "٢كيلو",
  /// "1½cup"), or a count with a times sign ("2x", "x2"). Throws
  /// [_Unparseable] for a microgram unit ("50µg").
  _Quantity? _glued(int i) {
    if (i >= chunks.length) return null;
    final chunk = chunks[i];
    if (chunk.isMicro) throw const _Unparseable();
    final text = chunk.folded;
    final times = _times.firstMatch(text.toLowerCase());
    if (times != null) {
      final value = _numeralValue(times[1] ?? times[2]!);
      if (value == null) throw const _Unparseable();
      return _Quantity(value, null, next: i + 1);
    }
    var split = 0;
    while (split < text.length && _numeralChars.contains(text[split])) {
      split++;
    }
    if (split == 0 || split == text.length) return null;
    final value = _numeralValue(text.substring(0, split));
    final match = _units[normalizeKey(text.substring(split))];
    if (value == null || match == null) return null;
    return _Quantity(value, match.code, next: i + 1);
  }

  /// [quantity] with an added fraction after it ("كيلو ونص").
  _Quantity _addFraction(_Quantity quantity) {
    final added = _phrase(_addedFractions, quantity.next);
    return added == null
        ? quantity
        : quantity.withAmount(quantity.amount + added.$1, next: added.$2);
  }

  /// The number at chunk [i] with its multipliers and added fractions
  /// ("2 dozen", "half a dozen", "تلاتة ونص"). Throws [_Unparseable] if
  /// another number follows it (a range or two items).
  _Number? number(int i, {required bool atStart}) {
    final base = _baseNumber(i, atStart: atStart);
    if (base == null) return null;
    var (:value, :next, :words, :fraction) = base;
    // "half a cup", "half a dozen": the article belongs to the fraction,
    // and so does "of a" ("a third of a cup").
    if (fraction && _in(_of, next) && _in(_articles, next + 1)) {
      if (_in(_dozens, next + 2) || unit(next + 2) != null) next += 2;
    } else if (fraction &&
        _in(_articles, next) &&
        (_in(_dozens, next + 1) || unit(next + 1) != null)) {
      next++;
    }
    if (_in(_dozens, next)) {
      value *= 12;
      next++;
    }
    final added = _phrase(_addedFractions, next);
    if (added != null) {
      value += added.$1;
      next = added.$2;
    }
    if (startsNumber(next) || (_in(_ranges, next) && startsNumber(next + 1))) {
      throw const _Unparseable();
    }
    return (value: value, next: next, words: words, fraction: fraction);
  }

  /// Whether a number starts at chunk [i] (digits or a number word, not an
  /// article).
  bool startsNumber(int i) =>
      i < chunks.length &&
      (chunks[i].isNumeral ||
          _glued(i) != null ||
          _baseNumber(i, atStart: false) != null);

  _Number? _baseNumber(int i, {required bool atStart}) {
    if (i >= chunks.length) return null;
    final chunk = chunks[i];
    if (chunk.isNumeral) return _digits(i);
    if (atStart && _in(_articles, i)) {
      final fraction = _phrase(_fractions, i + 1);
      if (fraction != null && fraction.$2 == i + 2) {
        return _number(fraction.$1, fraction.$2, fraction: true);
      }
      // "a hundred and fifty"; "a dozen" is the dozen multiplier.
      return _cardinal(i + 1, startsWithHundred: true) ??
          _number(1, i + 1, fraction: false);
    }
    final cardinal = _cardinal(i, startsWithHundred: false);
    if (cardinal != null) return cardinal;
    // One table, so the longest phrase wins: "ثلاثة أرباع" (¾) over
    // "ثلاثة" (3).
    final word = _phrase(_wordNumbers, i);
    if (word != null) {
      return _number(word.$1.value, word.$2, fraction: word.$1.fraction);
    }
    // "dozen eggs": one, multiplied by the dozen that follows.
    if (_in(_dozens, i)) return _number(1, i, fraction: false);
    return null;
  }

  /// A number of digits at chunk [i]: a numeral, a mixed number ("1 1/2"),
  /// or a whole number over an English denominator ("3 quarters").
  _Number _digits(int i) {
    final chunk = chunks[i];
    final value = chunk.numeralValue ?? (throw const _Unparseable());
    final next = i + 1;
    if (_wholeNumber.hasMatch(chunk.folded) && next < chunks.length) {
      final after = chunks[next];
      final part = after.numeralValue;
      if (_fractionNumeral.hasMatch(after.folded) && part != null && part < 1) {
        return (
          value: value + part,
          next: next + 1,
          words: false,
          fraction: false,
        );
      }
      final over = _denominator(value, next);
      if (over != null) {
        return (value: over, next: next + 1, words: false, fraction: true);
      }
    }
    return (value: value, next: next, words: false, fraction: false);
  }

  /// An English cardinal 0–999 at chunk [i] ("twenty five", "two hundred
  /// and fifty"), or over a denominator ("three quarters"). With
  /// [startsWithHundred] only "hundred …" is read (after "a").
  _Number? _cardinal(int i, {required bool startsWithHundred}) {
    var next = i;
    int? total;
    final ones = startsWithHundred ? null : _englishOnes[_key(next)];
    if (ones != null && ones > 0 && _key(next + 1) == _hundred) {
      total = ones * 100;
      next += 2;
    } else if (_key(next) == _hundred) {
      total = 100;
      next++;
    } else if (startsWithHundred) {
      return null;
    }
    if (total != null && _key(next) == _and && _below100(next + 1) != null) {
      next++;
    }
    final below = _below100(next);
    if (below != null) {
      total = (total ?? 0) + below.$1;
      next = below.$2;
    }
    if (total == null) return null;
    final over = _denominator(total.toDouble(), next);
    if (over != null) return _number(over, next + 1, fraction: true);
    return _number(total.toDouble(), next, fraction: false);
  }

  /// An English number below 100 at chunk [i], with the index after it.
  (int, int)? _below100(int i) {
    final tens = _englishTens[_key(i)];
    if (tens != null) {
      final ones = _englishOnes[_key(i + 1)];
      return ones != null && ones > 0 && ones < 10
          ? (tens + ones, i + 2)
          : (tens, i + 1);
    }
    final ones = _englishOnes[_key(i)];
    return ones == null ? null : (ones, i + 1);
  }

  /// [whole] over the English denominator at chunk [i] ("3 quarters"), or
  /// null.
  double? _denominator(double whole, int i) {
    final denominator = _englishDenominators[_key(i)];
    return denominator == null ? null : whole / denominator;
  }

  /// The unit at chunk [i], the longest phrase first ("ملعقة صغيرة" before
  /// "ملعقة", "fl oz" before "oz"). Throws [_Unparseable] for a microgram
  /// unit (µg, μg, mcg), which the search key would otherwise fold to "g".
  _UnitMatch? unit(int i) {
    if (i < chunks.length && chunks[i].isMicro) throw const _Unparseable();
    final match = _phrase(_units, i);
    return match == null ? null : (unit: match.$1, next: match.$2);
  }

  /// The longest phrase of up to [_longestPhrase] chunks at [i] that is a
  /// key of [table], with its value and the index after it.
  (V, int)? _phrase<V>(Map<String, V> table, int i) {
    for (var length = _longestPhrase; length >= 1; length--) {
      if (i + length > chunks.length) continue;
      final words = [for (var k = i; k < i + length; k++) chunks[k].key];
      if (words.any((word) => word.isEmpty)) continue;
      final value = table[words.join(' ')];
      if (value != null) return (value, i + length);
    }
    return null;
  }

  /// The search key of chunk [i], or '' past the end.
  String _key(int i) => i < chunks.length ? chunks[i].key : '';

  /// Whether the key of chunk [i] is in [words].
  bool _in(Set<String> words, int i) => words.contains(_key(i));

  static _Number _number(double value, int next, {required bool fraction}) =>
      (value: value, next: next, words: true, fraction: fraction);
}

/// The longest word phrase in the tables ("and a half").
const int _longestPhrase = 3;

/// A run of the text between separators: a word, a number, or a number
/// glued to a word.
final class _Chunk {
  new(this.start, this.end, this.folded);

  /// UTF-16 offsets of the chunk in the input.
  final int start;
  final int end;

  /// The chunk with fullwidth and Arabic-Indic digits folded to ASCII.
  final String folded;

  /// The search key, for the word tables.
  late final String key = normalizeKey(folded);

  /// Whether the chunk is made of numeral characters only ("2", "1/2",
  /// "1,5", "½"), valid or not.
  late final bool isNumeral =
      folded.split('').every(_numeralChars.contains) &&
      folded.split('').any(_numeralDigits.contains);

  /// The value of the numeral, or null if it isn't one or is malformed.
  late final double? numeralValue = isNumeral ? _numeralValue(folded) : null;

  /// Whether the chunk is a microgram unit, maybe after a number ("µg",
  /// "50μg", "mcg"). `normalizeKey` drops µ, so it is checked as typed.
  late final bool isMicro = _micro.hasMatch(folded.toLowerCase());
}

/// A microgram unit, maybe glued to a number: µ (micro sign) or μ (Greek
/// mu) with an optional g, or mcg.
final RegExp _micro = RegExp(r'^[\d.,/٫½¼¾⅓⅔]*(?:[µμ]g?|mcg)s?$');

/// A count with a times sign: "x2", "2x", "×3".
final RegExp _times = RegExp(
  r'^(?:[x×]([\d.,/٫½¼¾⅓⅔]+)|([\d.,/٫½¼¾⅓⅔]+)[x×])$',
);

/// The chunks of [text]: runs of characters between whitespace and
/// punctuation. `.` `٫` `,` and `/` between two digits stay inside a chunk
/// ("1.5", "1/2"), and so do `.` and `٫` before a digit at the start (".5").
List<_Chunk> _chunks(String text) {
  final runes = <({int rune, int start, int end})>[];
  final iterator = RuneIterator(text);
  while (iterator.moveNext()) {
    runes.add((
      rune: _foldRune(iterator.current),
      start: iterator.rawIndex,
      end: iterator.rawIndex + iterator.currentSize,
    ));
  }
  bool isDigit(int index) =>
      index >= 0 &&
      index < runes.length &&
      runes[index].rune >= _zero &&
      runes[index].rune <= _nine;

  final chunks = <_Chunk>[];
  final current = <int>[];
  var start = 0;
  var end = 0;
  for (final (index, entry) in runes.indexed) {
    final rune = entry.rune;
    // Bidi marks and other invisibles (common next to digits in RTL text)
    // are neither part of a chunk nor a separator.
    if (_isInvisible(rune)) continue;
    final inNumber =
        _numberPunctuation.contains(rune) &&
        isDigit(index + 1) &&
        (isDigit(index - 1) ||
            (_decimalPoints.contains(rune) &&
                (index == 0 || _isSpace(runes[index - 1].rune))));
    if (!inNumber && (_isSpace(rune) || _separators.contains(rune))) {
      if (current.isNotEmpty) {
        chunks.add(_Chunk(start, end, String.fromCharCodes(current)));
        current.clear();
      }
      continue;
    }
    if (current.isEmpty) start = entry.start;
    end = entry.end;
    current.add(rune);
  }
  if (current.isNotEmpty) {
    chunks.add(_Chunk(start, end, String.fromCharCodes(current)));
  }
  return chunks;
}

/// [rune] with fullwidth ASCII and Arabic-Indic and Persian digits folded
/// to ASCII, so numerals can be read.
int _foldRune(int rune) {
  if (rune >= fullwidthFirst && rune <= fullwidthLast) {
    return rune - fullwidthOffset;
  }
  if (rune >= arabicIndicZero && rune <= arabicIndicZero + 9) {
    return _zero + rune - arabicIndicZero;
  }
  if (rune >= persianZero && rune <= persianZero + 9) {
    return _zero + rune - persianZero;
  }
  return rune;
}

/// The food text: chunks [from] to [to] (exclusive) as typed, with the
/// separators between them.
String _rest(String text, List<_Chunk> chunks, int from, int to) =>
    text.substring(chunks[from].start, chunks[to - 1].end);

/// Whether [text] is only whitespace and invisibles.
bool _isBlank(String text) =>
    text.runes.every((rune) => _isSpace(rune) || _isInvisible(rune));

/// Whether [rune] is an invisible format character of normalization step 1
/// (not an apostrophe, which stays inside a word).
bool _isInvisible(int rune) =>
    deletedCharacters.contains(rune) && !_apostrophes.contains(rune);

/// The apostrophes of normalization step 1.
const Set<int> _apostrophes = {0x27, 0x60, 0x02BC, 0x2018, 0x2019};

/// Whitespace (explicit, no Unicode API): ASCII controls 9–13, space, NBSP,
/// ogham space, the U+2000 spaces, line and paragraph separators, narrow
/// NBSP, medium math space, ideographic space.
bool _isSpace(int rune) =>
    (rune >= 0x09 && rune <= 0x0D) ||
    rune == 0x20 ||
    rune == 0xA0 ||
    rune == 0x1680 ||
    (rune >= 0x2000 && rune <= 0x200A) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202F ||
    rune == 0x205F ||
    rune == 0x3000;

/// Punctuation that separates chunks. Everything else (letters, `%`, `'`,
/// `&`, …) belongs to the chunk, so "2%" or "7up" is one word.
const Set<int> _separators = {
  0x21, // !
  0x22, // "
  0x28, // (
  0x29, // )
  0x2C, // ,
  0x2D, // -
  0x2E, // .
  0x2F, // /
  0x3A, // :
  0x3B, // ;
  0x3F, // ?
  0x5B, // [
  0x5D, // ]
  0x7B, // {
  0x7D, // }
  0xAB, // «
  0xBB, // »
  0x060C, // ، Arabic comma
  0x061B, // ؛ Arabic semicolon
  0x061F, // ؟ Arabic question mark
  0x066B, // ٫ Arabic decimal separator
  0x2013, // – en dash
  0x2014, // — em dash
  0x201C, // “
  0x201D, // ”
  0x2026, // …
};

/// Separators that stay inside a numeral between two digits.
const Set<int> _numberPunctuation = {0x2C, 0x2E, 0x2F, 0x066B};

/// Decimal points (`.` and `٫`), which may also start a numeral (".5").
const Set<int> _decimalPoints = {0x2E, 0x066B};

/// Characters of a numeral after folding.
final Set<String> _numeralChars = {..._numeralDigits, '.', ',', '/', '٫'};

/// Characters that make a chunk a numeral: digits and vulgar fractions.
final Set<String> _numeralDigits = {
  for (var digit = 0; digit <= 9; digit++) '$digit',
  ..._vulgarFractions.keys,
};

/// The Unicode vulgar fractions of D12.
const Map<String, double> _vulgarFractions = {
  '½': 1 / 2,
  '¼': 1 / 4,
  '¾': 3 / 4,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
};

final RegExp _wholeNumber = RegExp(r'^\d+$');
final RegExp _decimal = RegExp(r'^\d*[.٫]\d+$');
final RegExp _commaDecimal = RegExp(r'^\d+,\d{1,2}$');
final RegExp _grouped = RegExp(r'^\d{1,3}(?:,\d{3})+(?:[.٫]\d+)?$');
final RegExp _slashFraction = RegExp(r'^(\d+)/(\d+)$');

/// A numeral that is a fraction on its own ("1/2", "½").
final RegExp _fractionNumeral = RegExp(r'^(?:\d+/\d+|[½¼¾⅓⅔])$');

/// The value of a numeral, or null if it is malformed ("1/0", "1.2.3",
/// "1,5000") or too large for a double.
double? _numeralValue(String numeral) {
  final value = _rawNumeralValue(numeral);
  return value != null && value.isFinite ? value : null;
}

double? _rawNumeralValue(String numeral) {
  final vulgar = _vulgarFractions[numeral[numeral.length - 1]];
  if (vulgar != null) {
    final whole = numeral.substring(0, numeral.length - 1);
    if (whole.isEmpty) return vulgar;
    return _wholeNumber.hasMatch(whole) ? double.parse(whole) + vulgar : null;
  }
  if (_wholeNumber.hasMatch(numeral)) return double.parse(numeral);
  if (_decimal.hasMatch(numeral)) {
    return double.parse(numeral.replaceAll('٫', '.'));
  }
  if (_commaDecimal.hasMatch(numeral)) {
    return double.parse(numeral.replaceAll(',', '.'));
  }
  if (_grouped.hasMatch(numeral)) {
    return double.parse(numeral.replaceAll(',', '').replaceAll('٫', '.'));
  }
  final fraction = _slashFraction.firstMatch(numeral);
  if (fraction != null) {
    final denominator = double.parse(fraction[2]!);
    return denominator == 0 ? null : double.parse(fraction[1]!) / denominator;
  }
  return null;
}

const int _zero = 0x30;
const int _nine = 0x39;

/// [table] keyed by the search key of each word.
Map<String, V> _byKey<V>(Map<String, V> table) => {
  for (final MapEntry(:key, :value) in table.entries) normalizeKey(key): value,
};

/// [words] as search keys.
Set<String> _keys(Set<String> words) => {
  for (final w in words) normalizeKey(w),
};

final Map<String, int> _englishOnes = _byKey(englishOnes);
final Map<String, int> _englishTens = _byKey(englishTens);
final Map<String, int> _englishDenominators = _byKey(englishDenominators);
final Map<String, double> _fractions = _byKey(fractionWords);

/// The Arabic and Arabizi number words and the fraction words in one
/// lookup.
final Map<String, ({double value, bool fraction})> _wordNumbers = {
  for (final MapEntry(:key, :value) in arabicNumberWords.entries)
    normalizeKey(key): (value: value.toDouble(), fraction: false),
  for (final MapEntry(:key, :value) in fractionWords.entries)
    normalizeKey(key): (value: value, fraction: true),
};
final Map<String, double> _addedFractions = _byKey(addedFractions);
final String _hundred = normalizeKey(englishHundred);
final String _and = normalizeKey(englishAnd);
final Set<String> _articles = _keys(articleWords);
final Set<String> _dozens = _keys(dozenWords);
final Set<String> _ranges = _keys(rangeWords);
final Set<String> _oneAfterUnit = _keys(oneAfterUnitWords);
final Set<String> _of = _keys(ofWords);
final Set<String> _numberOnlyUnits = _keys(numberOnlyUnitWords.keys.toSet());

/// Every unit word, phrase and derived dual form, by search key.
final Map<String, _Unit> _units = _buildUnits();

Map<String, _Unit> _buildUnits() {
  final units = <String, _Unit>{
    for (final MapEntry(:key, :value) in englishUnitWords.entries)
      normalizeKey(key): (code: value, dual: false, bare: false),
    for (final MapEntry(:key, :value) in arabicUnitWords.entries)
      normalizeKey(key): (code: value, dual: false, bare: true),
    for (final MapEntry(:key, :value) in numberOnlyUnitWords.entries)
      normalizeKey(key): (code: value, dual: false, bare: false),
  };
  for (final word in arabicDualUnits) {
    for (final dual in arabicDualForms(word)) {
      units[dual] = (
        code: units[normalizeKey(word)]!.code,
        dual: true,
        bare: true,
      );
    }
  }
  final spoons = {
    for (final word in arabicSpoonWords) normalizeKey(word): false,
    for (final word in arabicSpoonWords.intersection(arabicDualUnits))
      for (final dual in arabicDualForms(word)) dual: true,
  };
  for (final MapEntry(key: spoon, value: dual) in spoons.entries) {
    for (final MapEntry(key: size, value: code) in spoonSizeWords.entries) {
      units['$spoon ${normalizeKey(size)}'] = (
        code: code,
        dual: dual,
        bare: true,
      );
    }
  }
  return units;
}

/// The search keys of the Arabic dual of [singular] (LC-051): a final ة
/// (ه in the key) becomes ت, then ين or ان is added (حبة → حبتين,
/// حبتان; رغيف → رغيفين, رغيفان).
Set<String> arabicDualForms(String singular) {
  final key = normalizeKey(singular);
  final stem = key.endsWith('ه') ? '${key.substring(0, key.length - 1)}ت' : key;
  return {normalizeKey('$stemين'), normalizeKey('$stemان')};
}
