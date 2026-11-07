/// Grams or millilitres in one of a written unit (D-045: what a scale or a
/// jug reads). Keys are lower-case words as typed; (isVolume, factor).
const Map<String, (bool, double)> _units = {
  'g': (false, 1),
  'gr': (false, 1),
  'gm': (false, 1),
  'gram': (false, 1),
  'grams': (false, 1),
  'غ': (false, 1),
  'غم': (false, 1),
  'غرام': (false, 1),
  'جرام': (false, 1),
  'جم': (false, 1),
  'kg': (false, 1000),
  'kilo': (false, 1000),
  'kilos': (false, 1000),
  'كغ': (false, 1000),
  'كيلو': (false, 1000),
  'oz': (false, 28.349523125),
  'lb': (false, 453.59237),
  'lbs': (false, 453.59237),
  'ml': (true, 1),
  'مل': (true, 1),
  'l': (true, 1000),
  'liter': (true, 1000),
  'litre': (true, 1000),
  'لتر': (true, 1000),
};

/// The contract unit codes an explicit photo amount may keep.
const Map<String, (bool, double)> _codes = {
  'g': (false, 1),
  'kg': (false, 1000),
  'oz': (false, 28.349523125),
  'lb': (false, 453.59237),
  'ml': (true, 1),
  'l': (true, 1000),
};

/// How many words around a written quantity name its food.
const int _near = 3;

/// A weight or volume the user wrote: grams or ml, which, and the words
/// right before and after it.
typedef _Span = ({bool volume, double amount, Map<String, int> near});

/// [intent] with every food amount of a photo turn made an estimate
/// (A69 D7, AI-011, D-045), unless the **user's own message** [text]
/// states it: an item's `amount.explicit` stays `true` only when its unit
/// is a weight or volume and the same quantity is a whole "number + unit"
/// span of [text] ("150 g", "0,5 l") bound to that item: for a one-item
/// intent, the message's only weight or volume; otherwise a span with one
/// of the item's food words (the matched food's names) within three words,
/// nearer than any other item claiming the same quantity (a tie is
/// nobody's). The model's `mention` is never trusted; each span backs at
/// most one item. Otherwise `explicit` becomes `false`, so the engine marks
/// the line an estimate with a range. Other intent kinds come back as they
/// are. Pure; user content: never logged.
Map<String, Object?> photoEstimates(Map<String, Object?> intent, String text) {
  if (intent['kind'] != 'foodLog') return intent;
  final items = intent['items'];
  if (items is! List<Object?>) return intent;
  final spans = _spans(text);
  final stated = [for (final item in items) _statedOf(item)];
  final words = [
    for (final item in items)
      if (item is Map<String, Object?>) _foodWords(item) else <String>{},
  ];
  bool matches(_Span s, int item) => switch (stated[item]) {
    (final volume, final amount) =>
      s.volume == volume && (s.amount - amount).abs() <= 1e-6 * (1 + s.amount),
    null => false,
  };
  int? distance(_Span s, int item) {
    int? best;
    for (final MapEntry(key: w, value: d) in s.near.entries) {
      if (words[item].any((f) => _sameWord(w, f)) &&
          (best == null || d < best)) {
        best = d;
      }
    }
    return best;
  }

  final used = <int>{};
  bool kept(int item) {
    if (stated[item] == null) return false;
    if (items.length == 1) return spans.length == 1 && matches(spans[0], 0);
    for (final (i, s) in spans.indexed) {
      if (used.contains(i) || !matches(s, item)) continue;
      final mine = distance(s, item);
      if (mine == null) continue;
      final rivals = [
        for (var j = 0; j < items.length; j++)
          if (j != item &&
              matches(s, j) &&
              (distance(s, j) ?? _near + 1) <= mine)
            j,
      ];
      if (rivals.isEmpty) {
        used.add(i);
        return true;
      }
    }
    return false;
  }

  final out = <Object?>[];
  for (final (index, item) in items.indexed) {
    if (item is! Map<String, Object?> || !_explicit(item) || kept(index)) {
      out.add(item);
    } else {
      out.add({
        ...item,
        'amount': {
          ...item['amount']! as Map<String, Object?>,
          'explicit': false,
        },
      });
    }
  }
  return {...intent, 'items': out};
}

bool _explicit(Map<String, Object?> item) {
  final amount = item['amount'];
  return amount is Map<String, Object?> && amount['explicit'] == true;
}

/// An explicit weight or volume amount: (isVolume, g or ml), else `null`.
(bool, double)? _statedOf(Object? item) {
  if (item is! Map<String, Object?>) return null;
  if (item['amount'] case {
    'explicit': true,
    'value': final num value,
    'unit': final String unit,
  }) {
    final code = _codes[unit.toLowerCase()];
    return code == null ? null : (code.$1, value.toDouble() * code.$2);
  }
  return null;
}

/// The matched food's name words (catalog or the user's own food, never
/// the model's free text), at least three letters long.
Set<String> _foodWords(Map<String, Object?> item) {
  final match = item['match'];
  if (match is! Map<String, Object?>) return {};
  return {
    for (final name in [match['nameEn'], match['nameAr']])
      if (name is String) ..._tokens(name).where((w) => w.length >= 3),
  };
}

/// Words share a stem: one starts with the other, at least three letters.
bool _sameWord(String a, String b) =>
    a.length >= 3 && b.length >= 3 && (a.startsWith(b) || b.startsWith(a));

String _normalize(String text) {
  var t = text.toLowerCase();
  for (var i = 0; i < 10; i++) {
    t = t
        .replaceAll(String.fromCharCode(0x660 + i), '$i')
        .replaceAll(String.fromCharCode(0x6f0 + i), '$i');
  }
  return t;
}

List<String> _tokens(String text) => [
  for (final m in RegExp(
    r'[\p{L}]+',
    unicode: true,
  ).allMatches(_normalize(text)))
    m[0]!,
];

/// The whole "number + weight/volume unit" spans of [text] (Western or
/// Arabic-Indic digits, `.` or `,` decimal; "150g", "150 g"), with the
/// words just before and after each.
List<_Span> _spans(String text) {
  final t = _normalize(text);
  final out = <_Span>[];
  for (final m in RegExp(
    r'(?<![\p{L}\p{N}.,٫])(\d+(?:[.,٫]\d+)?)\s*(\p{L}+)(?![\p{L}\p{N}])',
    unicode: true,
  ).allMatches(t)) {
    final n = double.tryParse(m[1]!.replaceAll(RegExp('[,٫]'), '.'));
    final u = _units[m[2]!];
    if (n == null || u == null) continue;
    final before = _tokens(t.substring(0, m.start));
    final after = _tokens(t.substring(m.end));
    out.add((
      volume: u.$1,
      amount: n * u.$2,
      near: {
        for (var k = 1; k <= _near && k <= after.length; k++) after[k - 1]: k,
        for (var k = 1; k <= _near && k <= before.length; k++)
          before[before.length - k]: k,
      },
    ));
  }
  return out;
}
