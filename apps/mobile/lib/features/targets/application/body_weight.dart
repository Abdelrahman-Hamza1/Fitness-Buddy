import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'body_weight.g.dart';

/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date] (`WeightTrend.trendOn`), else null, and the
/// projection then falls back to the effective version's `basis_weight_kg`.
/// Weigh-ins are the only stored body weight; there is no profile weight.
/// Callers ([TargetsTimeline.day] through `dayTargetsProvider`) treat null as
/// "use the basis weight". Commands don't watch this: `TargetsActions` reads
/// the same trend once per command through A14's `bodyWeightReaderProvider`.
///
/// Follows every weigh-in change (A14's `weightTrendProvider`, which is
/// auto-disposed, so this is too).
@riverpod
Future<double?> bodyWeight(Ref ref, LocalDate date) async {
  final trend = await ref.watch(weightTrendProvider.future);
  return trend.trendOn(date);
}
