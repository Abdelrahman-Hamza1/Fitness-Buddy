/// Removes comments from Dart and C# sources, so commented-out code never
/// counts as a test.
///
/// Comment characters become spaces and line breaks are kept, so offsets and
/// line numbers stay the same. String literals are copied unchanged: a `//`
/// or `/*` inside a string is not a comment.
library;

/// [source] with its Dart comments blanked out.
///
/// Knows `//` and `///` line comments, nested `/* … */` block comments, raw
/// strings (`r'…'`), triple-quoted strings, escapes and `${…}` interpolation.
String stripDartComments(String source) =>
    (_Stripper(source, dart: true)..code()).output;

/// [source] with its C# comments blanked out.
///
/// Knows `//` and `///` line comments, `/* … */` block comments (not nested),
/// regular, verbatim (`@"…"`), interpolated (`$"…"`) and raw (`"""…"""`)
/// strings, and char literals (`'"'`).
String stripCSharpComments(String source) =>
    (_Stripper(source, dart: false)..code()).output;

final RegExp _identifierChar = RegExp(r'[\w$]');

class _Stripper {
  new(this.source, {required this.dart});

  final String source;
  final bool dart;
  final StringBuffer _out = StringBuffer();
  int _i = 0;

  String get output => _out.toString();

  bool _at(String text) => source.startsWith(text, _i);

  void _copy(int length) {
    final end = (_i + length).clamp(0, source.length);
    _out.write(source.substring(_i, end));
    _i = end;
  }

  void _blank(int length) {
    final end = (_i + length).clamp(0, source.length);
    for (; _i < end; _i++) {
      final c = source[_i];
      _out.write(c == '\n' || c == '\r' ? c : ' ');
    }
  }

  /// Copies code up to the end of the source, or (inside a Dart `${…}`) up
  /// to the unmatched `}`, which is left for the caller.
  void code({bool interpolation = false}) {
    var depth = 0;
    while (_i < source.length) {
      final c = source[_i];
      if (_at('//')) {
        _lineComment();
      } else if (_at('/*')) {
        _blockComment();
      } else if (dart && _startsDartString()) {
        _dartString();
      } else if (!dart && _startsCSharpString()) {
        _csharpString();
      } else if (interpolation && c == '}' && depth == 0) {
        return;
      } else {
        if (c == '{') depth++;
        if (c == '}' && depth > 0) depth--;
        _copy(1);
      }
    }
  }

  void _lineComment() {
    var end = source.indexOf('\n', _i);
    if (end == -1) end = source.length;
    _blank(end - _i);
  }

  void _blockComment() {
    var depth = 0;
    while (_i < source.length) {
      if (_at('/*')) {
        depth++;
        _blank(2);
      } else if (_at('*/')) {
        _blank(2);
        // C# block comments don't nest: the first `*/` ends the comment.
        if (!dart || --depth == 0) return;
      } else {
        _blank(1);
      }
    }
  }

  bool _startsDartString() {
    final c = source[_i];
    if (c == "'" || c == '"') return true;
    return c == 'r' &&
        _i + 1 < source.length &&
        (source[_i + 1] == "'" || source[_i + 1] == '"') &&
        (_i == 0 || !_identifierChar.hasMatch(source[_i - 1]));
  }

  void _dartString() {
    final raw = source[_i] == 'r';
    if (raw) _copy(1);
    final quote = source[_i];
    final triple = _at(quote * 3);
    final close = triple ? quote * 3 : quote;
    _copy(close.length);
    while (_i < source.length) {
      final c = source[_i];
      if (_at(close)) {
        _copy(close.length);
        return;
      } else if (!triple && c == '\n') {
        return; // Unterminated: stop at the line end.
      } else if (!raw && c == r'\') {
        _copy(2);
      } else if (!raw && _at(r'${')) {
        _copy(2);
        code(interpolation: true);
        _copy(1); // The closing `}`.
      } else {
        _copy(1);
      }
    }
  }

  bool _startsCSharpString() {
    var j = _i;
    while (j < source.length && (source[j] == r'$' || source[j] == '@')) {
      j++;
    }
    if (j >= source.length) return false;
    final quote = source[j];
    // A char literal (`'"'`) only, never a prefixed one.
    return quote == '"' || (quote == "'" && j == _i);
  }

  void _csharpString() {
    var verbatim = false;
    while (source[_i] == r'$' || source[_i] == '@') {
      verbatim = verbatim || source[_i] == '@';
      _copy(1);
    }
    final quote = source[_i];
    var quotes = 0;
    while (_i + quotes < source.length && source[_i + quotes] == quote) {
      quotes++;
    }
    if (!verbatim && quote == '"' && quotes >= 3) {
      // Raw string literal: ends at the same number of quotes. Raw literals
      // never take `@`, so `@""""` is a verbatim string holding one quote.
      final close = '"' * quotes;
      _copy(quotes);
      final end = source.indexOf(close, _i);
      _copy((end == -1 ? source.length : end + quotes) - _i);
      return;
    }
    _copy(1);
    while (_i < source.length) {
      final c = source[_i];
      if (verbatim && _at('""')) {
        _copy(2);
      } else if (c == quote) {
        _copy(1);
        return;
      } else if (!verbatim && c == '\n') {
        return; // Unterminated: stop at the line end.
      } else if (!verbatim && c == r'\') {
        _copy(2);
      } else {
        _copy(1);
      }
    }
  }
}
