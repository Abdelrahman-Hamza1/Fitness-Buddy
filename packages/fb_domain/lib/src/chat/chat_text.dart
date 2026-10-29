import 'package:fb_domain/src/proposals/proposal_sync_codes.dart';

/// Text rules of chat messages, in UTF-16 code units (B18 handoff, A22 D7).
///
/// The server counts string lengths like .NET `string.Length` (a
/// supplementary character is 2 units) and rejects U+0000 and unpaired
/// surrogates. Every stored row goes through [sanitize], so it is always
/// admissible; [admits] is the check the op handler repeats.
abstract final class ChatText {
  /// The composer's cap (`contracts/openapi/modules/buddy.yaml`
  /// `text.maxLength`).
  static const int composerLimit = 1000;

  /// The stored `chatMessage.text` cap.
  static const int storedLimit = ChatProposalSyncBounds.text;

  /// The replacement for an unpaired surrogate.
  static const int replacement = 0xFFFD;

  /// [text] made admissible: U+0000 removed, unpaired surrogates replaced by
  /// U+FFFD, then cut to at most [limit] units at a code-point boundary
  /// (never between the two halves of a surrogate pair). Nothing else
  /// changes: no trimming, no normalization.
  static String sanitize(String text, {int limit = storedLimit}) {
    _checkLimit(limit);
    final out = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (unit == 0) continue;
      if (_isHigh(unit) &&
          i + 1 < text.length &&
          _isLow(text.codeUnitAt(i + 1))) {
        out
          ..writeCharCode(unit)
          ..writeCharCode(text.codeUnitAt(++i));
      } else if (_isHigh(unit) || _isLow(unit)) {
        out.writeCharCode(replacement);
      } else {
        out.writeCharCode(unit);
      }
    }
    return truncate(out.toString(), limit);
  }

  /// The longest prefix of [text] with at most [limit] units that doesn't
  /// end between the two halves of a surrogate pair. [text] itself when it
  /// fits.
  static String truncate(String text, int limit) {
    _checkLimit(limit);
    if (text.length <= limit) return text;
    var end = limit;
    if (end > 0 &&
        _isHigh(text.codeUnitAt(end - 1)) &&
        _isLow(text.codeUnitAt(end))) {
      end--;
    }
    return text.substring(0, end);
  }

  /// Whether every surrogate in [text] is half of a high-low pair.
  static bool isWellFormed(String text) {
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (_isHigh(unit)) {
        if (i + 1 >= text.length || !_isLow(text.codeUnitAt(i + 1))) {
          return false;
        }
        i++;
      } else if (_isLow(unit)) {
        return false;
      }
    }
    return true;
  }

  /// Whether the server admits [text] as a string of at most [limit] units:
  /// within the limit, no U+0000 and well-formed UTF-16.
  static bool admits(String text, {int limit = storedLimit}) =>
      text.length <= limit && !text.contains('\u0000') && isWellFormed(text);

  static bool _isHigh(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  static bool _isLow(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

  static void _checkLimit(int limit) {
    if (limit < 0) throw ArgumentError.value(limit, 'limit', 'must be >= 0');
  }
}
