import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/components/sheet.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The `~` shown next to an estimated number (AI-032, SF-041). Tapping it
/// shows the likely range and the reason (see [showFbEstimateRange]).
class FbEstimateMarker extends StatelessWidget {
  /// Creates the marker.
  const new({required this.rangeText, required this.reason, super.key});

  /// The formatted range, e.g. "450 to 650 kcal".
  final String rangeText;

  /// Why it is an estimate, in a sentence.
  final String reason;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.fbSourceEstimateTitle,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () =>
            showFbEstimateRange(context, rangeText: rangeText, reason: reason),
        radius: FbSpace.s4,
        // At least 24 x 24 dp, the same touch area as the source badge.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.all(FbSpace.s1),
              child: Text(
                l10n.fbSourceBadgeEstimate,
                style: FbType.title.copyWith(color: context.fbColors.badge),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the range and the reason of an estimate in a sheet (AI-032).
Future<void> showFbEstimateRange(
  BuildContext context, {
  required String rangeText,
  required String reason,
}) => showFbSheet<void>(
  context,
  title: FbLocalizations.of(context).fbEstimateRangeTitle,
  builder: (context) =>
      FbEstimateRangeBody(rangeText: rangeText, reason: reason),
);

/// The content of the estimate range sheet. Public only so goldens can
/// render it without a route.
@visibleForTesting
class FbEstimateRangeBody extends StatelessWidget {
  /// Creates the content.
  const new({required this.rangeText, required this.reason, super.key});

  /// The formatted range.
  final String rangeText;

  /// Why it is an estimate.
  final String reason;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = FbType.caption.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.fbEstimateRangeLabel, style: label),
        Text(
          rangeText,
          style: FbType.numeric(FbType.headline)
              .copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: FbSpace.s4),
        Text(l10n.fbEstimateReasonLabel, style: label),
        Text(reason, style: FbType.body.copyWith(color: scheme.onSurface)),
      ],
    );
  }
}
