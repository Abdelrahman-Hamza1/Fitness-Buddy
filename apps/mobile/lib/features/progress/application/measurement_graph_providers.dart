import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_graph_providers.g.dart';

/// A measurement graph's range and pan position (A15b D16/D24):
/// session-only, one per type key, All by default.
typedef MeasurementGraphWindow = ({GraphRange range, DateTime? panStart});

/// Holds the [MeasurementGraphWindow] of the type [key]
/// (`MeasurementTypeRef.key`); survives leaving and returning.
@Riverpod(keepAlive: true)
class MeasurementGraphWindowController
    extends _$MeasurementGraphWindowController {
  @override
  MeasurementGraphWindow build(String key) =>
      (range: GraphRange.all, panStart: null);

  /// Picks [range] and returns to today.
  void setRange(GraphRange range) => state = (range: range, panStart: null);

  /// Moves the window to start at [start] (a drag ended).
  void setPanStart(DateTime start) =>
      state = (range: state.range, panStart: start);

  /// Back to the window ending today.
  void reset() => state = (range: state.range, panStart: null);
}

/// The selected entry's ID on the graph of type [key], or null.
@riverpod
class SelectedMeasurement extends _$SelectedMeasurement {
  @override
  String? build(String key) => null;

  /// Selects [id] (null clears).
  // A method, not a setter: the screen passes it as a callback.
  // ignore: use_setters_to_change_properties
  void select(String? id) => state = id;
}

/// The chart time of an entry: its local day and clock time (naive
/// wall-clock UTC, A15a PA7).
DateTime measurementChartTime(Measurement measurement) {
  final local = measurement.time.localDateTime;
  return DateTime.utc(
    measurement.localDate.year,
    measurement.localDate.month,
    measurement.localDate.day,
    local.hour,
    local.minute,
  );
}

/// [measurements] in chart order: by [measurementChartTime] (the wall clock
/// the chart's x uses), then the instant, then the ID. After a clock
/// rollback (DST) the UTC order differs from the wall-clock order; the
/// chart's binary search and hit-testing need x order (A15a review, PA6).
List<Measurement> measurementChartOrdered(Iterable<Measurement> measurements) {
  final keyed = [for (final m in measurements) (measurementChartTime(m), m)]
    ..sort((a, b) {
      final byX = a.$1.compareTo(b.$1);
      if (byX != 0) return byX;
      final byInstant = a.$2.time.occurredAtUtc.compareTo(
        b.$2.time.occurredAtUtc,
      );
      return byInstant != 0 ? byInstant : a.$2.id.compareTo(b.$2.id);
    });
  return [for (final (_, m) in keyed) m];
}
