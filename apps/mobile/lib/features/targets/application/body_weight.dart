import 'package:fb_domain/fb_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'body_weight.g.dart';

/// The body weight targets use on [date], kg (A13 D8, TD-090): A14's trend
/// weight on or before [date], else null, and the projection then falls back
/// to the effective version's `basis_weight_kg`. Weigh-ins are the only
/// stored body weight; there is no profile weight.
///
/// **Seam (A13a WP4):** A14 (`features/body/`) isn't on `main` yet, so this
/// returns null and every number uses the basis weight. A13b WP6 wires it
/// after A14 merges, by replacing the body with:
///
/// ```dart
/// final trend = await ref.watch(weightTrendProvider.future);
/// return trend.trendOn(date)?.trendKg;
/// ```
///
/// (importing `features/body/body.dart`). Callers ([TargetsTimeline.day],
/// `TargetsActions`) already treat null as "use the basis weight", so the
/// wiring touches only this function.
///
/// Kept alive (one small entry per date asked for) so the session-owned
/// `TargetsActions` can read it.
@Riverpod(keepAlive: true)
Future<double?> bodyWeight(Ref ref, LocalDate date) async => null;
