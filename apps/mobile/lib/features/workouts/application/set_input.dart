import 'package:fb_domain/fb_domain.dart';
import 'package:flutter/foundation.dart' show immutable;

/// One set row's inputs as typed (A37 D7): which fields matter depends on
/// the exercise type (WO-004). Weight is kg (D-085); a dumbbell's is per
/// dumbbell (WO-005).
@immutable
final class SetInput {
  /// The raw texts; blank fields are empty.
  const new({
    this.weight = '',
    this.reps = '',
    this.duration = '',
    this.distance = '',
  });

  /// The inputs showing [values] of an exercise of [type] (a saved set in
  /// edit mode).
  factory of(ExerciseType type, SetValues values) => SetInput(
    weight: switch (values.kg) {
      final kg? => formatNumber(kg),
      null => '',
    },
    reps: values.reps?.toString() ?? '',
    duration: switch (values.durationSeconds) {
      final s? when type == ExerciseType.distanceDuration => formatNumber(
        s / 60,
      ),
      final s? => formatClock(s),
      null => '',
    },
    distance: switch (values.distanceMeters) {
      final m? => formatNumber(m / 1000),
      null => '',
    },
  );

  /// Weight, added load or assistance in kg.
  final String weight;

  /// Reps.
  final String reps;

  /// Time as `m:ss` (or seconds) for timed sets; minutes for cardio.
  final String duration;

  /// Distance in km (cardio).
  final String distance;

  /// Whether nothing was typed (then ✓ accepts the hint).
  bool get isEmpty =>
      weight.trim().isEmpty &&
      reps.trim().isEmpty &&
      duration.trim().isEmpty &&
      distance.trim().isEmpty;

  /// The typed values for [type], canonical units. They may not fit the
  /// type: check with `SetValues.issueFor` (text that isn't a number makes
  /// its field invalid, never silently blank).
  SetValues valuesFor(ExerciseType type) {
    final reps = type.hasReps ? _int(this.reps) : null;
    return switch (type) {
      ExerciseType.weightReps ||
      ExerciseType.assisted => SetValues(reps: reps, kg: _decimal(weight)),
      ExerciseType.bodyweightReps => SetValues(
        reps: reps,
        kg: weight.trim().isEmpty ? null : _decimal(weight) ?? double.nan,
      ),
      ExerciseType.repsOnly => SetValues(reps: reps),
      ExerciseType.duration => SetValues(durationSeconds: _clock(duration)),
      ExerciseType.distanceDuration => SetValues(
        durationSeconds: switch (_decimal(duration)) {
          final minutes? when minutes.isFinite => (minutes * 60).round(),
          _ => null,
        },
        distanceMeters: distance.trim().isEmpty
            ? null
            : switch (_decimal(distance)) {
                final km? => km * 1000,
                null => double.nan,
              },
      ),
    };
  }

  static int? _int(String text) => int.tryParse(text.trim());

  static double? _decimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// `m:ss`, `h:mm:ss` or plain seconds.
  static int? _clock(String text) {
    final parts = text.trim().split(':');
    if (parts.isEmpty || parts.length > 3) return null;
    var seconds = 0;
    for (final (i, part) in parts.indexed) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || (i > 0 && n > 59)) return null;
      seconds = seconds * 60 + n;
    }
    return seconds;
  }

  @override
  bool operator ==(Object other) =>
      other is SetInput &&
      other.weight == weight &&
      other.reps == reps &&
      other.duration == duration &&
      other.distance == distance;

  @override
  int get hashCode => Object.hash(weight, reps, duration, distance);

  @override
  String toString() => 'SetInput';
}

/// [value] without a trailing `.0`, at most 2 decimals: `80`, `82.5`.
String formatNumber(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : fixed;
}

/// [seconds] as `m:ss` (`h:mm:ss` from an hour).
String formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
