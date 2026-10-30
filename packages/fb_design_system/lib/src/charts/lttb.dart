/// Largest-Triangle-Three-Buckets down-sampling (Steinarsson 2013, A15 D4).
///
/// Returns the indices of at most [threshold] points of ([xs], [ys]) that
/// keep the visual shape: the first and last always, and per bucket the
/// point forming the largest triangle with its neighbours, so extremes
/// survive. Below the threshold (or with a threshold under 3) every index
/// is returned. O(n).
List<int> lttbIndices(List<double> xs, List<double> ys, int threshold) {
  assert(xs.length == ys.length, 'xs and ys must have the same length');
  final n = xs.length;
  if (threshold >= n || threshold < 3) {
    return List<int>.generate(n, (i) => i);
  }
  final result = <int>[0];
  final bucketSize = (n - 2) / (threshold - 2);
  var a = 0;
  for (var bucket = 0; bucket < threshold - 2; bucket++) {
    // The average of the next bucket.
    final nextStart = ((bucket + 1) * bucketSize).floor() + 1;
    final nextEnd = (((bucket + 2) * bucketSize).floor() + 1).clamp(0, n);
    var avgX = 0.0;
    var avgY = 0.0;
    final nextCount = nextEnd - nextStart;
    for (var i = nextStart; i < nextEnd; i++) {
      avgX += xs[i];
      avgY += ys[i];
    }
    if (nextCount > 0) {
      avgX /= nextCount;
      avgY /= nextCount;
    } else {
      avgX = xs[n - 1];
      avgY = ys[n - 1];
    }
    // The point of this bucket with the largest triangle.
    final start = (bucket * bucketSize).floor() + 1;
    final end = ((bucket + 1) * bucketSize).floor() + 1;
    var best = start;
    var bestArea = -1.0;
    for (var i = start; i < end; i++) {
      final area =
          ((xs[a] - avgX) * (ys[i] - ys[a]) - (xs[a] - xs[i]) * (avgY - ys[a]))
              .abs();
      if (area > bestArea) {
        bestArea = area;
        best = i;
      }
    }
    result.add(best);
    a = best;
  }
  result.add(n - 1);
  return result;
}
