import 'dart:math' as math;

/// Rune-based optimal-string-alignment distance, with adjacent transpositions.
/// Returns [max] + 1 when the distance exceeds [max].
int osaDistance(String a, String b, int max) {
  if (max < 0) throw ArgumentError.value(max, 'max');
  final left = a.runes.toList();
  final right = b.runes.toList();
  if ((left.length - right.length).abs() > max) return max + 1;
  var previous = List<int>.generate(right.length + 1, (i) => i);
  var beforePrevious = previous;
  for (var i = 1; i <= left.length; i++) {
    final current = List<int>.filled(right.length + 1, 0)..[0] = i;
    for (var j = 1; j <= right.length; j++) {
      current[j] = math.min(
        math.min(previous[j] + 1, current[j - 1] + 1),
        previous[j - 1] + (left[i - 1] == right[j - 1] ? 0 : 1),
      );
      if (i > 1 &&
          j > 1 &&
          left[i - 1] == right[j - 2] &&
          left[i - 2] == right[j - 1]) {
        current[j] = math.min(current[j], beforePrevious[j - 2] + 1);
      }
    }
    beforePrevious = previous;
    previous = current;
  }
  return math.min(previous.last, max + 1);
}
