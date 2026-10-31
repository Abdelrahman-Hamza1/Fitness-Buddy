import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/migrations/from_13_to_14.dart';

/// When this app began storing per-weekday factors in `targetSettings`'
/// `shift*` fields (D-090, TD-112), for an install that never ran the v14
/// step (a fresh install): the A53 release day.
final int a53ReleaseMs = DateTime.utc(2026, 11).millisecondsSinceEpoch;

/// [payload] (a `targetSettings` v1 document written at [wallMs]) with
/// v13 weekday weights turned into factors, when it predates [sinceMs]
/// (the install's v14 marker, else [a53ReleaseMs]); otherwise unchanged.
/// The conversion is the v14 step's, without a floor (A53 D2).
Map<String, Object?> legacyTargetSettings(
  Map<String, Object?> payload, {
  required int wallMs,
  int? sinceMs,
}) {
  if (wallMs >= (sinceMs ?? a53ReleaseMs)) return payload;
  final fields = TargetWireFields.shifts.values.toList();
  final weights = [for (final f in fields) (payload[f] as num?)?.toDouble()];
  if (weights.every((w) => w == null)) return payload;
  final base = (payload['baseKcal'] as num?)?.toDouble();
  if (base == null || base <= 0) return payload;
  final factors = v13Factors(
    weights: weights,
    baseKcal: base,
    fixed: payload['mode'] == 'fixed',
    manualAcknowledged:
        payload['manual'] == true && payload['acknowledged'] == true,
  );
  return {...payload, for (final (i, f) in fields.indexed) f: factors[i]};
}
