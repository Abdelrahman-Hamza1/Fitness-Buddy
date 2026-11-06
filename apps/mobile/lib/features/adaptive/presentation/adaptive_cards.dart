import 'dart:async';
import 'dart:math' as math;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/adaptive/application/adaptive_actions.dart';
import 'package:fb_mobile/features/adaptive/application/adaptive_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// Says how a check-in or suggestion command ended (UX-030, UX-052).
Future<void> _report(
  BuildContext context,
  Future<AdaptiveOutcome> Function(AdaptiveActions actions) command,
  String Function(AppLocalizations l10n) done, {
  VoidCallback? onDone,
}) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await command(container.read(adaptiveActionsProvider));
  if (!host.mounted) return;
  final l10n = host.l10n;
  switch (outcome) {
    case AdaptiveDone(:final undoEntryId):
      onDone?.call();
      showUndoFeedback(host, message: done(l10n), undoEntryId: undoEntryId);
    case AdaptiveFailed(:final reason):
      showFbSnackBar(host, switch (reason) {
        AdaptiveFailure.stale => l10n.checkInFailedStale,
        AdaptiveFailure.outOfRange => l10n.checkInFailedRange,
        AdaptiveFailure.invalid ||
        AdaptiveFailure.unavailable => l10n.checkInFailed,
      });
    case AdaptivePending():
      break;
  }
}

/// The confidence words (TG-033).
String confidenceText(AppLocalizations l10n, ExpenditureConfidence c) =>
    switch (c) {
      ExpenditureConfidence.low => l10n.adaptiveConfidenceLow,
      ExpenditureConfidence.medium => l10n.adaptiveConfidenceMedium,
      ExpenditureConfidence.high => l10n.adaptiveConfidenceHigh,
    };

/// This week's check-in (TG-034, AI-056) as one-line notices (UX-047,
/// A63 D6): a proposal ("Weekly check-in · new target 2,050" · Review)
/// whose sheet holds Keep current / Use, adjustable in 50 kcal steps within
/// ±150 of the current base and never below the floor; a check-in the
/// targets outgrew (Dismiss); or an automatic change (Review: Got it /
/// Change back). Nothing is written until a button in the sheet is tapped
/// (D-079); the sheet closes after a tap that wrote. Nothing without one.
class CheckInCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliedAsync = ref.watch(appliedCheckInCardProvider);
    final viewAsync = ref.watch(checkInCardProvider);
    // `.value` keeps the last read through a later failure, so a shown
    // Change back never disappears on an error (A57 A48).
    final applied = appliedAsync.value;
    final view = viewAsync.value;
    final failed =
        (appliedAsync.hasError && !appliedAsync.hasValue) ||
        (viewAsync.hasError && !viewAsync.hasValue);
    Widget gap(Widget child) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The unseen automatic change first: a newer proposal never hides
        // its Change back (A38 review 5).
        if (applied != null) gap(_AppliedRow(view: applied)),
        if (failed)
          gap(
            _CardLoadFailed(
              key: const ValueKey('check-in-load-failed'),
              message: context.l10n.checkInLoadFailed,
              onRetry: () => ref
                ..invalidate(appliedCheckInCardProvider)
                ..invalidate(checkInCardProvider),
            ),
          ),
        if (view != null)
          gap(switch (view.kind) {
            CheckInCardKind.pending => FbNoticeRow(
              key: const ValueKey('check-in-row'),
              icon: FbIcons.target,
              text: context.l10n.checkInRowPending(
                DisplayRounding.kcal(view.draft.toKcal),
              ),
              actionLabel: context.l10n.noticeReview,
              actionKey: const ValueKey('check-in-review'),
              onAction: () => _openSheet(
                context,
                (close) => _ProposalCard(
                  key: ValueKey('check-in-${view.record.id}'),
                  view: view,
                  onDone: close,
                ),
              ),
            ),
            CheckInCardKind.stale => FbNoticeRow(
              key: const ValueKey('check-in-row'),
              icon: FbIcons.info,
              text: context.l10n.checkInRowStale,
              actionLabel: context.l10n.checkInDismiss,
              actionKey: const ValueKey('check-in-dismiss'),
              onAction: () => unawaited(
                _report(
                  context,
                  (a) => a.keep(view.record.id),
                  (l10n) => l10n.checkInKeptDone,
                ),
              ),
            ),
            CheckInCardKind.applied => _AppliedRow(view: view),
          }),
      ],
    );
  }
}

/// Opens [body] (the full card of a notice row) in a sheet; [body]'s close
/// callback pops it after a tap that wrote.
void _openSheet(
  BuildContext context,
  Widget Function(VoidCallback close) body,
) {
  unawaited(
    showFbSheet<void>(
      context,
      builder: (sheet) => body(() {
        if (sheet.mounted) Navigator.of(sheet).pop();
      }),
    ),
  );
}

/// An automatic change as one row (A57 A48: shown until the note is seen);
/// Review opens Got it / Change back.
class _AppliedRow extends StatelessWidget {
  const new({required this.view});

  final CheckInCardView view;

  @override
  Widget build(BuildContext context) {
    const kcal = DisplayRounding.kcal;
    return FbNoticeRow(
      key: const ValueKey('check-in-applied-row'),
      icon: FbIcons.target,
      text: context.l10n.checkInRowApplied(
        kcal(view.draft.toKcal),
        kcal(view.draft.fromKcal),
      ),
      actionLabel: context.l10n.noticeReview,
      actionKey: const ValueKey('check-in-applied-review'),
      onAction: () => _openSheet(
        context,
        (close) => _AppliedCard(view: view, onDone: close),
      ),
    );
  }
}

/// A card's read failed: a calm sentence and Try again in its place
/// (A57 A48), never a silent gap.
class _CardLoadFailed extends StatelessWidget {
  const new({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FbInlineBanner(
    kind: FbInlineBannerKind.info,
    message: message,
    actionLabel: context.l10n.foodTryAgain,
    onAction: onRetry,
  );
}

class _ProposalCard extends StatefulWidget {
  const new({required this.view, this.onDone, super.key});

  final CheckInCardView view;

  /// Called after a tap that wrote (the sheet closes).
  final VoidCallback? onDone;

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  static const double _step = 50;
  late double _kcal = widget.view.draft.toKcal;

  void _move(double by) => setState(() {
    final v = widget.view;
    _kcal = math.min(v.maxKcal, math.max(v.minKcal, _kcal + by));
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = widget.view;
    final draft = view.draft;
    final scheme = Theme.of(context).colorScheme;
    final id = view.record.id;
    const kcal = DisplayRounding.kcal;
    final adjusted = (_kcal - draft.toKcal).abs() >= .5;
    return FbProposalCard(
      header: l10n.checkInTitle,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Row(
            children: [
              FbIconButton(
                key: const ValueKey('check-in-lower'),
                icon: FbIcons.remove,
                tooltip: l10n.checkInLower,
                onPressed: _kcal > view.minKcal + .5
                    ? () => _move(-_step)
                    : null,
              ),
              Expanded(
                child: Text(
                  l10n.checkInChange(kcal(draft.fromKcal), kcal(_kcal)),
                  key: const ValueKey('check-in-change'),
                  textAlign: TextAlign.center,
                  style: FbType.numeric(FbType.title)
                      .copyWith(color: scheme.onSurface),
                ),
              ),
              FbIconButton(
                key: const ValueKey('check-in-raise'),
                icon: FbIcons.add,
                tooltip: l10n.checkInRaise,
                onPressed: _kcal < view.maxKcal - .5
                    ? () => _move(_step)
                    : null,
              ),
            ],
          ),
          Text(
            l10n.checkInWhy(
              kcal(draft.expenditureKcal),
              confidenceText(l10n, draft.confidence).toLowerCase(),
            ),
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (draft.hold case final hold?)
            Text(
              switch (hold) {
                CheckInHold.anomaly => l10n.checkInHeldAnomaly,
                CheckInHold.lowConfidence => l10n.checkInHeldLowConfidence,
              },
              key: const ValueKey('check-in-held'),
              style: FbType.body.copyWith(color: scheme.onSurface),
            ),
          if (draft.anomalyDates.isNotEmpty) ...[
            Text(
              l10n.checkInAnomalyDays(
                [
                  for (final d in draft.anomalyDates)
                    DateFormat.MMMEd(l10n.localeName)
                        .format(DateTime(d.year, d.month, d.day)),
                ].join(', '),
              ),
              key: const ValueKey('check-in-anomalies'),
              style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FbButton.text(
                key: const ValueKey('check-in-confirm-days'),
                label: l10n.checkInConfirmDays,
                onPressed: () => unawaited(
                  _report(
                    context,
                    (a) => a.confirmDays(draft.anomalyDates),
                    (l10n) => l10n.checkInConfirmedDaysDone,
                    onDone: widget.onDone,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: FbProposalActions(
        discardLabel: l10n.checkInKeep,
        confirmLabel: l10n.checkInUse(kcal(_kcal)),
        onDiscard: () => unawaited(
          _report(
            context,
            (a) => a.keep(id),
            (l10n) => l10n.checkInKeptDone,
            onDone: widget.onDone,
          ),
        ),
        onConfirm: () => unawaited(
          _report(
            context,
            (a) => a.accept(id, kcal: adjusted ? _kcal : null),
            (l10n) => l10n.checkInAcceptedDone,
            onDone: widget.onDone,
          ),
        ),
      ),
    );
  }
}

class _AppliedCard extends ConsumerWidget {
  const new({required this.view, this.onDone});

  final CheckInCardView view;

  /// Called after a tap that wrote (the sheet closes).
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const kcal = DisplayRounding.kcal;
    final id = view.record.id;
    return FbCard(
      key: const ValueKey('check-in-applied'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Text(l10n.checkInTitle, style: FbType.title),
          Text(
            l10n.checkInApplied(
              kcal(view.draft.fromKcal),
              kcal(view.draft.toKcal),
            ),
            style: FbType.body,
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: FbSpace.s2,
            children: [
              FbButton.text(
                label: l10n.checkInGotIt,
                onPressed: () {
                  unawaited(ref.read(adaptiveActionsProvider).dismissNote(id));
                  onDone?.call();
                },
              ),
              FbButton.secondary(
                key: const ValueKey('check-in-change-back'),
                label: l10n.checkInChangeBack,
                onPressed: () => unawaited(
                  _report(
                    context,
                    (a) => a.changeBack(id),
                    (l10n) => l10n.checkInChangedBackDone,
                    onDone: onDone,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The incomplete-day suggestion (DY-004): the most recent day of the last
/// two weeks under half of its target in fewer than two meals, asked about,
/// never marked automatically. Nothing without one.
class IncompleteDayCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incompleteDaySuggestionProvider);
    final suggestion = async.value;
    final l10n = context.l10n;
    if (suggestion == null) {
      return async.hasError
          ? Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: FbDensity.cardGap,
              ),
              child: _CardLoadFailed(
                key: const ValueKey('incomplete-day-load-failed'),
                message: l10n.incompleteDayLoadFailed,
                onRetry: () => ref.invalidate(incompleteDaySuggestionProvider),
              ),
            )
          : const SizedBox.shrink();
    }
    final date = suggestion.date;
    final day = DateFormat.MMMEd(l10n.localeName)
        .format(DateTime(date.year, date.month, date.day));
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: FbNoticeRow(
        key: const ValueKey('incomplete-day-row'),
        icon: FbIcons.diary,
        text: l10n.incompleteDayRow(day, DisplayRounding.kcal(suggestion.kcal)),
        actionLabel: l10n.noticeReview,
        actionKey: const ValueKey('incomplete-day-review'),
        onAction: () => _openSheet(
          context,
          (close) => _IncompleteDayProposal(
            suggestion: suggestion,
            day: day,
            onDone: close,
          ),
        ),
      ),
    );
  }
}

/// The incomplete-day question in full (the sheet of its row): Complete /
/// Mark incomplete; nothing is written before a tap (DY-004).
class _IncompleteDayProposal extends StatelessWidget {
  const new({
    required this.suggestion,
    required this.day,
    required this.onDone,
  });

  final IncompleteDaySuggestion suggestion;
  final String day;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = suggestion.date;
    return FbProposalCard(
      key: ValueKey('incomplete-day-$date'),
      header: l10n.incompleteDayTitle,
      details: Text(
        l10n.incompleteDayBody(
          day,
          DisplayRounding.kcal(suggestion.kcal),
          suggestion.mealCount,
        ),
        style: FbType.body,
      ),
      actions: FbProposalActions(
        discardLabel: l10n.incompleteDayComplete,
        confirmLabel: l10n.diaryMarkIncomplete,
        onDiscard: () => unawaited(
          _report(
            context,
            (a) => a.confirmComplete(date),
            (l10n) => l10n.incompleteDayConfirmedDone,
            onDone: onDone,
          ),
        ),
        onConfirm: () => unawaited(
          _report(
            context,
            (a) => a.markIncomplete(date),
            (l10n) => l10n.diaryDayMarkedIncomplete,
            onDone: onDone,
          ),
        ),
      ),
    );
  }
}

/// The Expenditure card (IN-005, TG-031, TG-033): before enough data, what
/// is still needed ("2 more weigh-ins until your targets can adapt"); then
/// the estimate with its confidence and the weekly chart with its likely
/// range; and the ask / automatic switch (TG-034). Nothing before setup.
class ExpenditureCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenditureViewProvider);
    final view = async.value;
    final l10n = context.l10n;
    if (view == null) {
      return async.hasError
          ? _CardLoadFailed(
              key: const ValueKey('expenditure-load-failed'),
              message: l10n.expenditureLoadFailed,
              onRetry: () => ref.invalidate(expenditureViewProvider),
            )
          : const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final latest = view.latest;
    final r = view.readiness;
    final days = math.max(r.daysToLog, r.completeDaysToLog);
    return FbCard(
      key: const ValueKey('progress-expenditure'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FbSpace.s2,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.adaptiveTitle, style: FbType.title),
          ),
          if (latest == null) ...[
            // Numbers first (UX-047, A63 D8.6): what is still to go, then
            // the explanation on tap.
            Row(
              key: const ValueKey('expenditure-to-go'),
              spacing: FbSpace.s2,
              children: [
                if (r.weighInsToLog > 0)
                  _ToGoTile(
                    value: l10n.adaptiveToGoWeighIns(r.weighInsToLog),
                    caption: l10n.adaptiveToGoCaption,
                  )
                else if (r.spanDaysToGo > 0)
                  _ToGoTile(
                    value: l10n.adaptiveToGoDays(r.spanDaysToGo),
                    caption: l10n.adaptiveToGoSpanCaption,
                  ),
                if (days > 0)
                  _ToGoTile(
                    value: l10n.adaptiveToGoDays(days),
                    caption: l10n.adaptiveToGoLogCaption,
                  ),
              ],
            ),
            FbListRow(
              key: const ValueKey('expenditure-how'),
              leading: const Icon(FbIcons.help),
              title: l10n.adaptiveHowItWorks,
              trailing: const Icon(FbIcons.next),
              onTap: () => _openSheet(
                context,
                (_) => Padding(
                  padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                  child: Text(
                    l10n.adaptiveIntro,
                    key: const ValueKey('expenditure-intro'),
                    style: FbType.body,
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              l10n.adaptiveEstimate(DisplayRounding.kcal(latest.kcal)),
              key: const ValueKey('expenditure-estimate'),
              style: FbType.numeric(FbType.title)
                  .copyWith(color: scheme.onSurface),
            ),
            Text(confidenceText(l10n, latest.confidence), style: muted),
            _ExpenditureChart(view: view),
            Text(l10n.adaptiveExplain, style: muted),
          ],
          FbSwitchRow(
            key: const ValueKey('adaptive-automatic'),
            title: l10n.adaptiveAutomatic,
            subtitle: l10n.adaptiveAutomaticHint,
            value: view.mode == CheckInMode.automatic,
            onChanged: (on) => unawaited(_setMode(context, ref, on)),
          ),
        ],
      ),
    );
  }
}

/// Saves the check-in mode and says so with Undo, or that it failed
/// (A38 review 8).
Future<void> _setMode(BuildContext context, WidgetRef ref, bool on) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await ref
      .read(settingsActionsProvider)
      .setCheckInMode(on ? CheckInMode.automatic : CheckInMode.ask);
  if (!host.mounted) return;
  reportSettingsOutcome(
    host,
    outcome,
    () => on ? host.l10n.adaptiveAutomaticOn : host.l10n.adaptiveAutomaticOff,
  );
}

class _ExpenditureChart extends StatelessWidget {
  const new({required this.view});

  final ExpenditureView view;

  static DateTime _day(LocalDate d) => DateTime.utc(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final points = view.points;
    final last = points.last.windowEnd;
    final first = points.first.windowEnd;
    // At least four weeks wide, so one point isn't a lonely dot at an edge.
    final start = first.isBefore(last.plusDays(-28))
        ? first.plusDays(-3)
        : last.plusDays(-31);
    return FbTimeSeriesChart(
      key: const ValueKey('expenditure-chart'),
      aspectRatio: 2,
      range: FbChartRange(start: _day(start), end: _day(last.plusDays(4))),
      series: [
        FbSeries(
          points: [
            for (final e in points)
              FbPoint(_day(e.windowEnd), e.kcal.roundToDouble()),
          ],
          semanticLabel: l10n.adaptiveTitle,
        ),
      ],
      bands: [
        FbBand(
          points: [
            for (final e in points)
              FbBandPoint(
                _day(e.windowEnd),
                lower: (e.kcal - e.sigmaKcal).roundToDouble(),
                upper: (e.kcal + e.sigmaKcal).roundToDouble(),
              ),
          ],
        ),
      ],
      formatValue: (v) => '${DisplayRounding.kcal(v)}',
      formatDate: (at, step) => switch (step) {
        FbTimeStep.day => DateFormat.MMMd(l10n.localeName).format(at),
        FbTimeStep.month => DateFormat.MMM(l10n.localeName).format(at),
        FbTimeStep.year => DateFormat.y(l10n.localeName).format(at),
      },
      semanticLabel: l10n.adaptiveChartSemantics(
        DisplayRounding.kcal(points.last.kcal),
      ),
      emptyLabel: l10n.adaptiveChartEmpty,
    );
  }
}

/// A number still to go before targets can adapt, with its caption.
class _ToGoTile extends StatelessWidget {
  const new({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: FbRadius.mdAll,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(FbSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: FbType.numeric(FbType.title)),
                Text(
                  caption,
                  style: FbType.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
