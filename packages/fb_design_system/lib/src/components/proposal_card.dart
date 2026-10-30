import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/components/button.dart';
import 'package:fb_design_system/src/components/card.dart';
import 'package:fb_design_system/src/components/skeleton.dart';
import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The one card layout every proposal kind uses (UX-020, A22 D13): the
/// fixed parts in a fixed order, so food, edit, weigh-in and later cards
/// read the same way.
///
/// 1. [header]: what it is and when ("Breakfast · 08:40"), tappable when
///    [onHeaderTap] is set;
/// 2. [title]: the dish name, when there is one;
/// 3. [details]: the items, or a before → after (UX-026);
/// 4. [assumptions]: the assumption chips, wrapped;
/// 5. [questions]: in-card questions with answer chips;
/// 6. [impact]: totals and "today after this", under a divider;
/// 7. [actions]: Discard and the dominant primary action
///    ([FbProposalActions]).
///
/// [FbProposalCard.skeleton] is the calm placeholder while Buddy thinks
/// (AI-030, UX-051).
class FbProposalCard extends StatelessWidget {
  /// A card with its parts.
  const new({
    required String this.header,
    required Widget this.details,
    this.onHeaderTap,
    this.title,
    this.assumptions = const [],
    this.questions,
    this.impact,
    this.actions,
    super.key,
  }) : semanticLabel = null;

  /// The placeholder card shown before the proposal arrives.
  const new skeleton({this.semanticLabel, super.key})
    : header = null,
      details = null,
      onHeaderTap = null,
      title = null,
      assumptions = const [],
      questions = null,
      impact = null,
      actions = null;

  /// What and when, e.g. "Breakfast · 08:40". Left out when empty.
  final String? header;

  /// The skeleton's one screen-reader label ("Buddy is making a card").
  final String? semanticLabel;

  /// Called when the header is tapped (change slot or time).
  final VoidCallback? onHeaderTap;

  /// The dish name.
  final String? title;

  /// The items or the before → after.
  final Widget? details;

  /// Assumption chips.
  final List<Widget> assumptions;

  /// Questions with answer chips.
  final Widget? questions;

  /// Totals and the effect on today.
  final Widget? impact;

  /// Discard and the primary action.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final header = this.header;
    if (header == null) {
      return Semantics(
        container: true,
        label: semanticLabel ?? FbLocalizations.of(context).fbLoading,
        excludeSemantics: true,
        child: const FbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FbSpace.s3,
            children: [
              FbSkeleton.line(width: 120),
              FbSkeleton.line(width: 200, height: 18),
              FbSkeleton.line(),
              FbSkeleton.line(),
              FbSkeleton.line(width: 160),
            ],
          ),
        ),
      );
    }
    final headerText = Text(
      header,
      style: FbType.label.copyWith(color: scheme.onSurfaceVariant),
    );
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          if (header.isEmpty)
            const SizedBox.shrink()
          else if (onHeaderTap case final onTap?)
            // A 48 dp tap target however short the text (UX-040).
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(FbRadius.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: FbSpace.s1,
                      children: [
                        Flexible(child: headerText),
                        Icon(
                          FbIcons.expand,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            headerText,
          if (title case final title?)
            Text(title, style: FbType.title.copyWith(color: scheme.onSurface)),
          ?details,
          if (assumptions.isNotEmpty)
            Wrap(
              spacing: FbSpace.s2,
              runSpacing: FbSpace.s2,
              children: assumptions,
            ),
          ?questions,
          if (impact case final impact?) ...[
            Divider(color: scheme.outlineVariant, height: FbSpace.s3),
            impact,
          ],
          if (actions case final actions?)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: FbSpace.s2),
              child: actions,
            ),
        ],
      ),
    );
  }
}

/// One item of a proposal: name, amount, calories and its source mark
/// ([marker]: an `FbSourceBadge` or an `FbEstimateMarker`). Tappable when
/// [onTap] is set. [note] is a short line under the amount (an assumption
/// the item rests on).
///
/// With [onDecrease] or [onIncrease] the amount sits between − and +
/// buttons (an assumed amount adjusted in place, AI-040); a null one is
/// disabled. [onNameTap] makes the name tappable (swap the food, AI-041),
/// [onAmountTap] the amount (its number pad, AI-040).
class FbProposalLine extends StatelessWidget {
  /// A line.
  const new({
    required this.name,
    required this.amount,
    required this.kcal,
    required this.marker,
    this.note,
    this.onTap,
    this.onNameTap,
    this.onAmountTap,
    this.onDecrease,
    this.onIncrease,
    this.decreaseTooltip,
    this.increaseTooltip,
    this.stepper = false,
    super.key,
  });

  /// The food's name.
  final String name;

  /// The amount as text.
  final String amount;

  /// The calories as text.
  final String kcal;

  /// The source badge or estimate marker.
  final Widget marker;

  /// An optional note under the amount.
  final String? note;

  /// Called on tap.
  final VoidCallback? onTap;

  /// Called when the name is tapped.
  final VoidCallback? onNameTap;

  /// Called when the amount is tapped (open its number pad, AI-040).
  final VoidCallback? onAmountTap;

  /// One step less; null disables − (already the smallest amount).
  final VoidCallback? onDecrease;

  /// One step more.
  final VoidCallback? onIncrease;

  /// The −'s (already translated) tooltip and screen-reader label.
  final String? decreaseTooltip;

  /// The +'s (already translated) tooltip and screen-reader label.
  final String? increaseTooltip;

  /// Shows the − / + around the amount.
  final bool stepper;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = FbType.numeric(FbType.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    final nameText = Text(
      name,
      style: FbType.body.copyWith(color: scheme.onSurface),
    );
    Widget tappable(Widget child) => switch (onAmountTap) {
      final onTap? => Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FbRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
      null => child,
    };
    final amountText = stepper
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                tooltip: decreaseTooltip,
                onPressed: onDecrease,
                icon: const Icon(FbIcons.remove, size: 18),
              ),
              Flexible(
                child: tappable(
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: FbSpace.s2,
                    ),
                    child: Text(
                      amount,
                      style: FbType.numeric(FbType.label)
                          .copyWith(color: scheme.onSurface),
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: increaseTooltip,
                onPressed: onIncrease,
                icon: const Icon(FbIcons.add, size: 18),
              ),
            ],
          )
        : tappable(Text(amount, style: small));
    final row = Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onNameTap case final onNameTap?)
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: onNameTap,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: 1,
                          child: nameText,
                        ),
                      ),
                    ),
                  )
                else
                  nameText,
                amountText,
                if (note case final note?) Text(note, style: small),
              ],
            ),
          ),
          const SizedBox(width: FbSpace.s2),
          Text(
            kcal,
            style: FbType.numeric(FbType.body)
                .copyWith(color: scheme.onSurface),
          ),
          const SizedBox(width: FbSpace.s1),
          marker,
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

/// The action row of a proposal card: the secondary [discardLabel] at the
/// start and the dominant primary [confirmLabel] filling the rest (UX-021).
/// From text scale 1.5 the two stack, primary on top.
///
/// A null [onConfirm] disables the primary action (it can't be confirmed
/// yet, or it is being applied); [reason] then says why, in one line above
/// the buttons.
class FbProposalActions extends StatelessWidget {
  /// The row.
  const new({
    required this.discardLabel,
    required this.confirmLabel,
    required this.onDiscard,
    required this.onConfirm,
    this.reason,
    super.key,
  });

  /// The secondary label.
  final String discardLabel;

  /// The primary label.
  final String confirmLabel;

  /// Called on Discard; null disables it.
  final VoidCallback? onDiscard;

  /// Called on the primary action; null disables it.
  final VoidCallback? onConfirm;

  /// Why the primary action is disabled.
  final String? reason;

  /// From this text scale on, the buttons stack.
  static const double stackFromScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stack = MediaQuery.textScalerOf(context).scale(1) >= stackFromScale;
    final discard = FbButton.secondary(
      label: discardLabel,
      onPressed: onDiscard,
      expand: stack,
    );
    final confirm = FbButton.primary(
      label: confirmLabel,
      icon: FbIcons.check,
      onPressed: onConfirm,
      expand: true,
    );
    final buttons = stack
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FbSpace.s2,
            children: [confirm, discard],
          )
        : Row(
            spacing: FbSpace.s3,
            children: [
              discard,
              Expanded(child: confirm),
            ],
          );
    final reason = this.reason;
    if (reason == null) return buttons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        Text(
          reason,
          style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        ),
        buttons,
      ],
    );
  }
}

/// What a proposal card collapses to once it's resolved (AI-035): an
/// [icon], one line of [text] ("Logged ✓ 191 kcal · 1,240 left today") and
/// at most one Undo ([undoLabel] + [onUndo]).
class FbProposalResolvedRow extends StatelessWidget {
  /// The row.
  const new({
    required this.icon,
    required this.text,
    this.undoLabel,
    this.onUndo,
    this.note,
    super.key,
  });

  /// The leading icon (from `FbIcons`).
  final IconData icon;

  /// The one-line reply.
  final String text;

  /// The Undo label; shown with [onUndo].
  final String? undoLabel;

  /// Called on Undo.
  final VoidCallback? onUndo;

  /// A second, smaller line (why Undo didn't work).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final undoLabel = this.undoLabel;
    final onUndo = this.onUndo;
    return FbCard(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: FbSpace.s4,
        vertical: FbSpace.s2,
      ),
      child: Row(
        spacing: FbSpace.s2,
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: FbType.body.copyWith(color: scheme.onSurface),
                ),
                if (note case final note?)
                  Text(
                    note,
                    style: FbType.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (undoLabel != null && onUndo != null)
            FbButton.text(label: undoLabel, onPressed: onUndo),
        ],
      ),
    );
  }
}

/// Briefly tints [child] when [token] changes (UX-024): something on the
/// card just changed. The tint fades over [duration]; with animations off
/// it shows without fading and then goes.
class FbChangeHighlight extends StatefulWidget {
  /// A highlight keyed by [token]; null means nothing changed.
  const new({required this.token, required this.child, super.key});

  /// Changes whenever the content changes; the first value never tints.
  final Object? token;

  /// The content.
  final Widget child;

  /// How long the tint lasts.
  static const Duration duration = Duration(milliseconds: 1200);

  @override
  State<FbChangeHighlight> createState() => _FbChangeHighlightState();
}

class _FbChangeHighlightState extends State<FbChangeHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FbChangeHighlight.duration,
    value: 1,
  );

  @override
  void didUpdateWidget(FbChangeHighlight old) {
    super.didUpdateWidget(old);
    if (widget.token != null && widget.token != old.token) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.primaryContainer;
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final strength = t >= 1 ? 0.0 : (still ? 1.0 : 1 - t);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.6 * strength),
            borderRadius: BorderRadius.circular(FbRadius.sm),
          ),
          child: child,
        );
      },
    );
  }
}
