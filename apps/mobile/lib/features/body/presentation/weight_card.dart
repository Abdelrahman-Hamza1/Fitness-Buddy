import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/application/weight_card_state.dart';
import 'package:fb_mobile/features/body/application/weight_providers.dart';
import 'package:fb_mobile/features/body/application/weight_tip.dart';
import 'package:fb_mobile/features/body/presentation/weigh_in_sheet.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The weight card of a day page (HM-005, HM-009, WB-011, A14 D9): the trend
/// as of [date] with its weekly rate, the latest weigh-in on or before it
/// smaller, and on today's page the honest note about sparse weigh-ins and
/// the monthly suggestion (WB-012, D10).
///
/// The first row logs a weigh-in on [date] (2 taps from Today: this row,
/// then Save); the second edits the latest weigh-in. Neutral throughout: a
/// change is a signed number, never a colour or a judgement.
class WeightCard extends ConsumerWidget {
  /// The card of [date]; [isToday] adds the cadence note and suggestion.
  const new({required this.date, required this.isToday, super.key});

  /// The page's day.
  final LocalDate date;

  /// Whether [date] is today.
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(weightCardProvider(date, isToday: isToday));
    final state = card.value;
    // (A reload keeps the last state on screen: no skeleton flash.)
    final Widget child;
    if (state != null) {
      child = _content(context, ref, state);
    } else if (card.hasError) {
      final l10n = context.l10n;
      child = FbInlineBanner(
        kind: FbInlineBannerKind.error,
        message: l10n.weightCardLoadFailed,
        actionLabel: l10n.weightCardTryAgain,
        onAction: () => ref.invalidate(weighInsProvider),
      );
    } else {
      child = const FbSkeleton.card(height: 72);
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FbSpace.s4,
        0,
        FbSpace.s4,
        FbSpace.s3,
      ),
      child: child,
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, WeightCardState state) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final asOf = state.asOf;
    final unit = state.units.bodyMass;

    // Row 1: the trend (title), the weekly rate on its own line, then at
    // most one quiet note; and what a screen reader says, units in full.
    final String main;
    String? rate;
    String? note;
    final String rowLabel;
    final trendKg = asOf.trendKg;
    if (trendKg == null) {
      main = state.hasHistory ? l10n.weightCardEmptyPast : l10n.weightCardEmpty;
      rowLabel = l10n.weightCardEmptySemantics(main);
    } else {
      final trend = weightText(l10n, trendKg, unit);
      final spoken = weightSpoken(l10n, trendKg, unit);
      final String summary;
      if (asOf.isStale) {
        final from = dayLabelInline(
          context,
          asOf.lastWeighIn!.localDate,
          today,
        );
        main = l10n.weightCardTrendFrom(trend, from);
        summary = l10n.weightCardTrendFromSemantics(spoken, from);
      } else if (asOf.weeklyRateKg case final perWeek?) {
        main = l10n.weightCardTrend(trend);
        rate = weightRateText(l10n, perWeek, unit);
        summary = l10n.weightCardTrendRateSemantics(
          spoken,
          weightSpokenChange(l10n, perWeek, unit),
        );
        if (state.cadence case final cadence?
            when cadence.kind == CadenceKind.sparse) {
          note = l10n.weightCardSparse(cadence.countLast28);
        }
      } else {
        main = l10n.weightCardTrend(trend);
        summary = l10n.weightCardTrendSemantics(spoken);
        note = l10n.weightCardRateLater;
      }
      rowLabel = note == null
          ? l10n.weightCardLogSemantics(summary)
          : l10n.weightCardLogNoteSemantics(summary, note);
    }

    if (state.showTip) _markTipShown(ref);
    // Row 2: the latest weigh-in. When stale, the trend row already says
    // its day, so this one doesn't repeat it.
    final latest = state.latest;
    final String? last;
    final String? lastLabel;
    if (latest == null) {
      last = null;
      lastLabel = null;
    } else if (asOf.isStale) {
      last = l10n.weightCardLastValue(weightText(l10n, latest.kg, unit));
      lastLabel = l10n.weightCardLastValueSemantics(
        weightSpoken(l10n, latest.kg, unit),
      );
    } else {
      final when = dayLabel(context, latest.localDate, today);
      last = l10n.weightCardLast(weightText(l10n, latest.kg, unit), when);
      lastLabel = l10n.weightCardLastSemantics(
        weightSpoken(l10n, latest.kg, unit),
        when,
      );
    }
    return FbCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardRow(
            semanticLabel: rowLabel,
            icon: FbIcons.add,
            onTap: () => unawaited(
              showWeighInSheet(context, date: isToday ? null : date),
            ),
            children: [
              Text(
                l10n.weightTitle,
                style: FbType.label.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                main,
                style: state.isEmpty
                    ? FbType.body.copyWith(color: scheme.onSurface)
                    : FbType.numeric(FbType.title)
                          .copyWith(color: scheme.onSurface),
              ),
              if (rate != null)
                Text(
                  rate,
                  style: FbType.numeric(FbType.body)
                      .copyWith(color: scheme.onSurface),
                ),
              if (note != null) Text(note, style: muted),
            ],
          ),
          if (state.showTip)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                FbSpace.s3,
                0,
                FbSpace.s3,
                FbSpace.s3,
              ),
              child: FbInlineBanner(
                kind: FbInlineBannerKind.info,
                message: l10n.weightCardTip,
                actionLabel: l10n.weightCardTipDismiss,
                // At large text sizes the message keeps the card's width.
                actionBelow:
                    MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.4,
                onAction: () => unawaited(
                  ref.read(weightTipControllerProvider.notifier).dismiss(),
                ),
              ),
            ),
          if (latest != null && last != null && lastLabel != null) ...[
            Divider(height: 1, color: scheme.outlineVariant),
            _CardRow(
              semanticLabel: l10n.weightCardEditSemantics(lastLabel),
              icon: FbIcons.edit,
              onTap: () => unawaited(showWeighInSheet(context, edit: latest)),
              children: [
                Text(
                  last,
                  style: FbType.numeric(FbType.bodySmall)
                      .copyWith(color: scheme.onSurface),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Records that the suggestion showed today, after this frame (never
  /// inside a build, A14 D10). Idempotent: the same day writes nothing.
  void _markTipShown(WidgetRef ref) {
    if (ref.read(weightTipControllerProvider).value?.shownOn == date) return;
    final controller = ref.read(weightTipControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(controller.markShown(date)),
    );
  }
}

/// One tappable row of the card: its texts, and an icon at the end that
/// says what the tap does. One button for a screen reader, at least 48 dp
/// high.
class _CardRow extends StatelessWidget {
  const new({
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
    required this.children,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FbSpace.s7),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: FbSpace.s4,
            vertical: FbSpace.s3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FbSpace.s1,
                  children: children,
                ),
              ),
              const SizedBox(width: FbSpace.s3),
              Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ),
  );
}
