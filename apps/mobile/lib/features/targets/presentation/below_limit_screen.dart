import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/targets/presentation/targets_text.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the full-screen warning (SF-011, SF-012, D14, D16) for a manual
/// target (or one [weekday]'s number, A53 D4) of [kcal] that breaks the
/// limits in [need]. Resolves true only
/// when the user checked the acknowledgement and tapped "Use …"; Go back
/// or closing resolves false or null (nothing is written either way here).
///
/// Flow-local exception to typed routes (A13c review): the warning is one
/// step of the own-target flow, opened over its sheet with
/// `Navigator.push(fullscreenDialog)` so the kcal value and the limits never
/// travel in a URL and the sheet keeps the number underneath; it has no
/// deep link and no tab of its own.
Future<bool?> showBelowLimitScreen(
  BuildContext context, {
  required double kcal,
  required TargetsNeedsAcknowledgement need,
  required UnitSystem units,
  String? weekday,
}) => Navigator.of(context, rootNavigator: true).push<bool>(
  MaterialPageRoute<bool>(
    fullscreenDialog: true,
    builder: (_) => BelowLimitScreen(
      kcal: kcal,
      need: need,
      units: units,
      weekday: weekday,
    ),
  ),
);

/// The warning screen: calm copy (no moral words, no alarm colour), the
/// acknowledgement checkbox and a primary that stays off until it is
/// checked.
class BelowLimitScreen extends StatefulWidget {
  /// The warning for [kcal] and [need].
  const new({
    required this.kcal,
    required this.need,
    required this.units,
    this.weekday,
    super.key,
  });

  /// The manual target, kcal.
  final double kcal;

  /// The limits it breaks.
  final TargetsNeedsAcknowledgement need;

  /// The unit setting (the implied rate).
  final UnitSystem units;

  /// For one weekday's number (A53 D4), its name: the warning says only
  /// that day changes, instead of "the same every day".
  final String? weekday;

  @override
  State<BelowLimitScreen> createState() => _BelowLimitScreenState();
}

class _BelowLimitScreenState extends State<BelowLimitScreen> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final kcal = DisplayRounding.kcal(widget.kcal);
    final need = widget.need;
    final belowFloor = need.warnings.contains(TargetWarning.manualBelowFloor);
    final style = FbType.body.copyWith(color: scheme.onSurface);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.targetsWarningTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                children: [
                  if (belowFloor) ...[
                    Text(
                      l10n.targetsWarningFloor(
                        kcal,
                        DisplayRounding.kcal(need.floorKcal),
                      ),
                      style: style,
                    ),
                    const SizedBox(height: FbSpace.s3),
                    Text(switch (widget.weekday) {
                      final day? => l10n.targetsWarningDay(day),
                      null => l10n.targetsWarningFixed,
                    }, style: style),
                  ] else
                    Text(
                      l10n.targetsWarningRate(
                        kcal,
                        rateText(
                          l10n,
                          need.impliedKgPerWeek.abs(),
                          widget.units.bodyMass,
                        ),
                      ),
                      style: style,
                    ),
                  const SizedBox(height: FbSpace.s4),
                  FbCheckboxRow(
                    title: l10n.targetsWarningAcknowledge(kcal),
                    value: _checked,
                    onChanged: (value) => setState(() => _checked = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FbSpace.s2,
                children: [
                  FbButton.primary(
                    label: l10n.targetsWarningUse(kcal),
                    expand: true,
                    onPressed: _checked
                        ? () => Navigator.of(context).pop(true)
                        : null,
                  ),
                  FbButton.secondary(
                    label: l10n.targetsWarningBack,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
