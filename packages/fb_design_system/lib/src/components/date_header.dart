import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The day header with previous/next navigation (HM-009). [label] is the
/// formatted date ("Today", "Fri 17 Oct"). [onNext] null disables the next
/// button (e.g. on today). The chevrons mirror in right-to-left layouts.
class FbDateHeader extends StatelessWidget {
  /// Creates the header.
  const new({
    required this.label,
    required this.onPrevious,
    this.onNext,
    super.key,
  });

  /// The (already formatted) date.
  final String label;

  /// Called to go to the previous day.
  final VoidCallback onPrevious;

  /// Called to go to the next day; null disables the button.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: l10n.fbDatePrevious,
          icon: const Icon(FbIcons.previous),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: FbType.title.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: l10n.fbDateNext,
          icon: const Icon(FbIcons.next),
        ),
      ],
    );
  }
}
