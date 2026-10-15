/// A string literal found in Dart source.
final class StringLiteral {
  /// Creates a literal spanning `[start, end)` of the source.
  const new({required this.start, required this.end, required this.staticText});

  /// Offset of its first character (the `r` prefix or the opening quote).
  final int start;

  /// Offset just after the closing quote.
  final int end;

  /// The literal's own characters: interpolations (`$x`, `${…}`) removed,
  /// each escape sequence (`\n`, `\u{…}`) replaced by one space.
  final String staticText;
}

/// Dart source split into code, comments and string literals, without a
/// parser: enough to find widget arguments and directives reliably.
final class ScannedSource {
  new _(this.source, this.code, this.literals, this._lineStarts);

  /// Scans [source].
  factory scan(String source) => _Scanner(source).run();

  /// The original source.
  final String source;

  /// [source] with every comment and every string literal (quotes included)
  /// replaced by spaces. Newlines are kept, so offsets and lines match
  /// [source].
  final String code;

  /// The outermost string literals by start offset. Literals nested inside
  /// another literal's interpolation are not listed.
  final Map<int, StringLiteral> literals;

  final List<int> _lineStarts;

  /// The number of lines (a final newline starts an empty last line).
  int get lineCount => _lineStarts.length;

  /// The 1-based line of [offset].
  int lineOf(int offset) {
    var low = 0;
    var high = _lineStarts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_lineStarts[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }

  /// The text of the 1-based [line], without its newline.
  String lineText(int line) {
    final start = _lineStarts[line - 1];
    final end = line < _lineStarts.length
        ? _lineStarts[line] - 1
        : source.length;
    return source.substring(start, end);
  }
}

class _Scanner {
  new(this.source);

  final String source;
  final _code = StringBuffer();
  final _literals = <int, StringLiteral>{};

  ScannedSource run() {
    var i = 0;
    while (i < source.length) {
      if (_startsWith('//', i)) {
        i = _blankUntil(i, _lineCommentEnd(i));
      } else if (_startsWith('/*', i)) {
        i = _blankUntil(i, _blockCommentEnd(i));
      } else if (_stringStart(i) case final quoteAt?) {
        final literal = _readString(i, quoteAt);
        _literals[i] = literal;
        i = _blankUntil(i, literal.end);
      } else {
        _code.write(source[i]);
        i++;
      }
    }
    final lineStarts = [0];
    for (var j = 0; j < source.length; j++) {
      if (source.codeUnitAt(j) == _newline) lineStarts.add(j + 1);
    }
    return ScannedSource._(source, '$_code', _literals, lineStarts);
  }

  static const int _newline = 0x0A;

  bool _startsWith(String pattern, int at) => source.startsWith(pattern, at);

  /// Writes spaces for `[from, to)` (newlines kept) and returns [to].
  int _blankUntil(int from, int to) {
    for (var j = from; j < to; j++) {
      _code.write(source.codeUnitAt(j) == _newline ? '\n' : ' ');
    }
    return to;
  }

  int _lineCommentEnd(int at) {
    final newline = source.indexOf('\n', at);
    return newline == -1 ? source.length : newline;
  }

  /// Dart block comments nest.
  int _blockCommentEnd(int at) {
    var depth = 0;
    var i = at;
    while (i < source.length) {
      if (_startsWith('/*', i)) {
        depth++;
        i += 2;
      } else if (_startsWith('*/', i)) {
        depth--;
        i += 2;
        if (depth == 0) return i;
      } else {
        i++;
      }
    }
    return source.length;
  }

  /// If a string literal starts at [at] (a quote, or `r` + quote that isn't
  /// the end of an identifier), returns the offset of its opening quote.
  int? _stringStart(int at) {
    final c = source[at];
    if (c == "'" || c == '"') return at;
    if (c == 'r' &&
        at + 1 < source.length &&
        (source[at + 1] == "'" || source[at + 1] == '"') &&
        (at == 0 || !_isIdentifierChar(source[at - 1]))) {
      return at + 1;
    }
    return null;
  }

  StringLiteral _readString(int start, int quoteAt) {
    final raw = quoteAt != start;
    final q = source[quoteAt];
    final triple = _startsWith('$q$q$q', quoteAt);
    final close = triple ? '$q$q$q' : q;
    final text = StringBuffer();
    var i = quoteAt + close.length;
    while (i < source.length) {
      final c = source[i];
      if (_startsWith(close, i)) {
        i += close.length;
        break;
      }
      if (!triple && c == '\n') break; // Unterminated: stop at the line end.
      if (!raw && c == r'\') {
        i = _escapeEnd(i);
        text.write(' ');
      } else if (!raw && c == r'$' && _startsWith(r'${', i)) {
        i = _interpolationEnd(i + 2);
      } else if (!raw && c == r'$') {
        i++;
        while (i < source.length && _isIdentifierChar(source[i])) {
          i++;
        }
      } else {
        text.write(c);
        i++;
      }
    }
    return StringLiteral(start: start, end: i, staticText: '$text');
  }

  /// [at] is a backslash; returns the offset after the escape sequence.
  int _escapeEnd(int at) {
    final next = at + 1 < source.length ? source[at + 1] : '';
    if (next == 'u' && _startsWith('{', at + 2)) {
      final close = source.indexOf('}', at + 3);
      return close == -1 ? source.length : close + 1;
    }
    final length = switch (next) {
      'u' => 6,
      'x' => 4,
      _ => 2,
    };
    return (at + length).clamp(0, source.length);
  }

  /// [at] is just after `${`; returns the offset after the matching `}`.
  int _interpolationEnd(int at) {
    var depth = 1;
    var i = at;
    while (i < source.length) {
      if (_stringStart(i) case final quoteAt?) {
        i = _readString(i, quoteAt).end;
        continue;
      }
      final c = source[i];
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) return i + 1;
      }
      i++;
    }
    return source.length;
  }

  static bool _isIdentifierChar(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 0x30 && u <= 0x39) || // 0-9
        (u >= 0x41 && u <= 0x5A) || // A-Z
        (u >= 0x61 && u <= 0x7A) || // a-z
        u == 0x5F || // _
        u == 0x24; // $
  }
}
