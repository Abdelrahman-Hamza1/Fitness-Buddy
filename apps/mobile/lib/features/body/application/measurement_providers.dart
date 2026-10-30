import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/data/measurement_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_providers.g.dart';

/// The live custom types and measurements (A15b D25): reactive, local. No
/// automatic retry: the screens show the error with Try again (UX-052).
@Riverpod(retry: _noAutomaticRetry)
Stream<MeasurementData> measurements(Ref ref) =>
    ref.watch(measurementRepositoryProvider).watch();

Duration? _noAutomaticRetry(int retryCount, Object error) => null;

/// One measurement type as the screens show it: its ref, its custom name
/// (null for built-ins) and its series.
final class MeasurementTypeView {
  /// [ref] with [series]; a custom type also has its [type] row.
  const new({required this.ref, required this.series, this.type});

  /// Which series.
  final MeasurementTypeRef ref;

  /// The custom type's row at the version read, or `null` for a built-in
  /// kind.
  final MeasurementType? type;

  /// The custom type's name, or `null` for a built-in kind. User content.
  String? get customName => type?.name;

  /// The entries, day choices and trend.
  final MeasurementSeries series;

  @override
  String toString() => 'MeasurementTypeView(${ref.key})';
}

/// Every type in display order (WB-040, A15b D18): the built-in kinds
/// (waist, chest, hips, arm, thigh, neck, body fat), then custom types by
/// name, each with its series (its latest value and date come from it).
@riverpod
Future<List<MeasurementTypeView>> latestByType(Ref ref) async {
  final data = await ref.watch(measurementsProvider.future);
  return viewsOf(data);
}

/// The type of route key [key] (`MeasurementTypeRef.key`), or `null` when
/// the key is unknown or the custom type was removed.
@riverpod
Future<MeasurementTypeView?> measurementSeries(Ref ref, String key) async {
  final data = await ref.watch(measurementsProvider.future);
  final target = MeasurementTypeRef.parse(key);
  if (target == null) return null;
  for (final view in viewsOf(data)) {
    if (view.ref == target) return view;
  }
  return null;
}

/// The views of [data], in display order.
List<MeasurementTypeView> viewsOf(MeasurementData data) {
  final byKey = <String, List<Measurement>>{};
  for (final m in data.measurements) {
    (byKey[m.type.key] ??= []).add(m);
  }
  MeasurementSeries series(MeasurementTypeRef ref) =>
      MeasurementSeries.of(byKey[ref.key] ?? const []);
  return [
    for (final kind in MeasurementKind.builtIns)
      MeasurementTypeView(
        ref: MeasurementTypeRef.builtIn(kind),
        series: series(MeasurementTypeRef.builtIn(kind)),
      ),
    for (final type in data.types)
      MeasurementTypeView(ref: type.ref, type: type, series: series(type.ref)),
  ];
}
