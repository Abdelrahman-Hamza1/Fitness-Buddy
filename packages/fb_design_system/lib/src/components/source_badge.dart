import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/components/sheet.dart';
import 'package:fb_design_system/src/tokens/colors.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Where a number comes from (FD-010; `spec/11` §2). Labels you scanned and
/// values you edited are [yours].
enum FbSource {
  /// Entered, scanned or edited by the user.
  yours,

  /// From the food database.
  database,

  /// From a reference dish.
  referenceDish,

  /// A rough estimate.
  estimate,
}

extension on FbSource {
  String letter(FbLocalizations l10n) => switch (this) {
    FbSource.yours => l10n.fbSourceBadgeYours,
    FbSource.database => l10n.fbSourceBadgeDatabase,
    FbSource.referenceDish => l10n.fbSourceBadgeReference,
    FbSource.estimate => l10n.fbSourceBadgeEstimate,
  };

  String title(FbLocalizations l10n) => switch (this) {
    FbSource.yours => l10n.fbSourceYoursTitle,
    FbSource.database => l10n.fbSourceDatabaseTitle,
    FbSource.referenceDish => l10n.fbSourceReferenceTitle,
    FbSource.estimate => l10n.fbSourceEstimateTitle,
  };

  String body(FbLocalizations l10n) => switch (this) {
    FbSource.yours => l10n.fbSourceYoursBody,
    FbSource.database => l10n.fbSourceDatabaseBody,
    FbSource.referenceDish => l10n.fbSourceReferenceBody,
    FbSource.estimate => l10n.fbSourceEstimateBody,
  };
}

/// Diameter of the badge circle.
const double _badgeSize = 16;

class _BadgeGlyph extends StatelessWidget {
  const new(this.source);

  final FbSource source;

  @override
  Widget build(BuildContext context) {
    final color = context.fbColors.badge;
    return SizedBox(
      width: _badgeSize,
      height: _badgeSize,
      child: DecoratedBox(
        key: const ValueKey('fb-source-badge-circle'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        // The badge is a fixed-size mark: it doesn't follow the text scale.
        child: Center(
          child: MediaQuery.withNoTextScaling(
            child: Text(
              source.letter(FbLocalizations.of(context)),
              style: FbType.caption.copyWith(
                color: color,
                fontSize: 10,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small outlined circle with a letter for the source of a number
/// (FD-010, UX-044): monochrome, 16 dp. Tapping opens the legend with all
/// four sources, unless [onTap] is given.
class FbSourceBadge extends StatelessWidget {
  /// Creates a badge.
  const new({required this.source, this.onTap, super.key});

  /// The source to show.
  final FbSource source;

  /// Overrides the default tap (open the legend).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    return Semantics(
      button: true,
      label: source.title(l10n),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap ?? () => showFbSourceLegend(context),
        radius: FbSpace.s4,
        // 4 dp around the 16 dp circle: a 24 dp touch area.
        child: Padding(
          padding: const EdgeInsets.all(FbSpace.s1),
          child: _BadgeGlyph(source),
        ),
      ),
    );
  }
}

/// Shows the legend of the four sources in a sheet (UX-044).
Future<void> showFbSourceLegend(BuildContext context) => showFbSheet<void>(
  context,
  title: FbLocalizations.of(context).fbSourceLegendTitle,
  builder: (context) => const FbSourceLegendBody(),
);

/// The rows of the source legend: a badge, its title and what it means.
/// Public only so goldens can render the sheet content without a route.
@visibleForTesting
class FbSourceLegendBody extends StatelessWidget {
  /// Creates the legend rows.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final source in FbSource.values)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: FbSpace.s2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BadgeGlyph(source),
                const SizedBox(width: FbSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title(l10n),
                        style: FbType.label.copyWith(color: scheme.onSurface),
                      ),
                      Text(
                        source.body(l10n),
                        style: FbType.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
