import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weight_providers.g.dart';

/// The live weigh-ins, ordered by local date, measured time and ID (A14
/// D12).
@riverpod
Stream<List<WeighIn>> weighIns(Ref ref) =>
    ref.watch(weighInRepositoryProvider).watchLive();

/// The weight trend over the live weigh-ins (WB-010–012, A14 D1/D2/D12):
/// recomputed once per change of the weigh-ins, derived, never stored.
@riverpod
Stream<WeightTrend> weightTrend(Ref ref) async* {
  final weighIns = await ref.watch(weighInsProvider.future);
  yield TrendWeight().compute(weighIns);
}

/// The app's current weight in kg: the latest trend, `null` without
/// weigh-ins (A14 PA1, a fixed name: targets (A13) read weight only through
/// this and `weightTrendProvider`'s `trendOn(date)`; there is no profile
/// weight).
@riverpod
Stream<double?> currentWeightKg(Ref ref) async* {
  final trend = await ref.watch(weightTrendProvider.future);
  yield trend.latest?.trendKg;
}

/// The trend weight on a date, from one read of the stored weigh-ins.
typedef BodyWeightReader = Future<double?> Function(LocalDate date);

/// [BodyWeightReader] for commands that run outside any screen (A13's
/// session-owned `TargetsActions`, D8/TD-090): each call reads the weigh-ins
/// once and computes the trend, so no auto-disposed provider is created,
/// held or disposed while it loads. Screens keep using [weightTrendProvider].
@Riverpod(keepAlive: true)
BodyWeightReader bodyWeightReader(Ref ref) {
  final repository = ref.watch(weighInRepositoryProvider);
  return (date) async =>
      TrendWeight().compute(await repository.readLive()).trendOn(date);
}

/// Every live weigh-in, from one read (A38's weekly check-in runs outside
/// any screen, like [bodyWeightReader]).
typedef WeighInsReader = Future<List<WeighIn>> Function();

/// [WeighInsReader] over the stored weigh-ins.
@Riverpod(keepAlive: true)
WeighInsReader weighInsReader(Ref ref) =>
    ref.watch(weighInRepositoryProvider).readLive;
