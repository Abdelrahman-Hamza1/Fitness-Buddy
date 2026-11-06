import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/presentation/measurement_text.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:material_ui/material_ui.dart';

/// A weigh-in version for Earlier versions (#236): its weight as typed,
/// "214.0 lb" (user content: shown, never logged).
String? weighInVersionSummary(
  BuildContext context,
  Map<String, Object?> payload,
) => weighInVersionText(context.l10n, payload);

/// A measurement version for Earlier versions (#236): its value as typed.
String? measurementVersionSummary(
  BuildContext context,
  Map<String, Object?> payload,
) => measurementVersionText(context.l10n, payload);

/// [weighInVersionSummary]'s text; null (the time only) for a payload it
/// can't read or a scrubbed tombstone (weight 0, #136).
String? weighInVersionText(
  AppLocalizations l10n,
  Map<String, Object?> payload,
) {
  final value = payload['inputValue'];
  final kg = payload['kg'];
  final unit = switch (payload['inputUnit']) {
    final String code => MassUnit.fromCode(code),
    _ => null,
  };
  if (value is! num || value <= 0 || kg is! num || kg <= 0 || unit == null) {
    return null;
  }
  return weighInInputText(l10n, WeighInInput(value.toDouble(), unit));
}

/// [measurementVersionSummary]'s text; null for a payload it can't read.
String? measurementVersionText(
  AppLocalizations l10n,
  Map<String, Object?> payload,
) {
  final value = payload['inputValue'];
  final unit = switch (payload['inputUnit']) {
    final String code => MeasurementUnit.fromCode(code),
    _ => null,
  };
  if (value is! num || value <= 0 || unit == null) return null;
  return measurementInputText(l10n, MeasurementInput(value.toDouble(), unit));
}
