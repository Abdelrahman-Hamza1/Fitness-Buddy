import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The day header with previous/next navigation (HM-009). [label] is the
/// formatted date ("Today", "Fri 17 Oct"). [onNext] null disables the next
/// button (e.g. on today). [onLabelTap] makes the label a button that opens
/// a date picker (HM-009). [trailing] (e.g. a day menu button, A16 D11)
/// sits after the next button. The chevrons mirror in right-to-left layouts.
class FbDateHeader extends StatelessWidget {
  /// Creates the header.
  const new({
    required this.label,
    required this.onPrevious,
    this.onNext,
    this.onLabelTap,
    this.trailing,
    super.key,
  });

  /// The (already formatted) date.
  final String label;

  /// Called to go to the previous day.
  final VoidCallback onPrevious;

  /// Called to go to the next day; null disables the button.
  final VoidCallback? onNext;

  /// Called when the date is tapped (to pick another day); null leaves the
  /// label as plain text.
  final VoidCallback? onLabelTap;

  /// A widget after the next button, or null for none.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = FbLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: l10n.fbDatePrevious,
          icon: const Icon(FbIcons.previous),
        ),
        Expanded(
          child: _Label(label: label, onTap: onLabelTap),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: l10n.fbDateNext,
          icon: const Icon(FbIcons.next),
        ),
        ?trailing,
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: FbType.title.copyWith(color: scheme.onSurface),
    );
    if (onTap == null) return Semantics(header: true, child: text);
    return Semantics(
      header: true,
      button: true,
      onTapHint: FbLocalizations.of(context).fbDateChoose,
      child: InkWell(
        onTap: onTap,
        borderRadius: FbRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: text),
              const SizedBox(width: FbSpace.s1),
              const ExcludeSemantics(child: Icon(FbIcons.expand, size: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
