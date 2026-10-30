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
  String Function(AppLocalizations l10n) done,
) async {
  final container = ProviderScope.containerOf(context);
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await command(container.read(adaptiveActionsProvider));
  if (!host.mounted) return;
  final l10n = host.l10n;
  switch (outcome) {
    case AdaptiveDone(:final undoEntryId):
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

/// This week's check-in (TG-034, AI-056; shown on Progress until A39a's
/// weekly summary): the proposal with Keep current / Use, adjustable in
/// 50 kcal steps within ±150 of the current base and never below the
/// floor; a check-in the targets outgrew (Dismiss only); or an automatic
/// change with Change back. Nothing without one.
class CheckInCard extends ConsumerWidget {
  /// Creates the card.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applied = ref.watch(appliedCheckInCardProvider).value;
    final view = ref.watch(checkInCardProvider).value;
    Widget gap(Widget child) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The unseen automatic change first: a newer proposal never hides
        // its Change back (A38 review 5).
        if (applied != null) gap(_AppliedCard(view: applied)),
        if (view != null)
          gap(switch (view.kind) {
            CheckInCardKind.pending => _ProposalCard(
              key: ValueKey('check-in-${view.record.id}'),
              view: view,
            ),
            CheckInCardKind.stale => _StaleCard(view: view),
            CheckInCardKind.applied => _AppliedCard(view: view),
          }),
      ],
    );
  }
}

class _ProposalCard extends StatefulWidget {
  const new({required this.view, super.key});

  final CheckInCardView view;

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
          _report(context, (a) => a.keep(id), (l10n) => l10n.checkInKeptDone),
        ),
        onConfirm: () => unawaited(
          _report(
            context,
            (a) => a.accept(id, kcal: adjusted ? _kcal : null),
            (l10n) => l10n.checkInAcceptedDone,
          ),
        ),
      ),
    );
  }
}

class _StaleCard extends StatelessWidget {
  const new({required this.view});

  final CheckInCardView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FbProposalCard(
      header: l10n.checkInTitle,
      details: Text(l10n.checkInStale, style: FbType.body),
      actions: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FbButton.secondary(
          key: const ValueKey('check-in-dismiss'),
          label: l10n.checkInDismiss,
          onPressed: () => unawaited(
            _report(
              context,
              (a) => a.keep(view.record.id),
              (l10n) => l10n.checkInKeptDone,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppliedCard extends ConsumerWidget {
  const new({required this.view});

  final CheckInCardView view;

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
                onPressed: () => unawaited(
                  ref.read(adaptiveActionsProvider).dismissNote(id),
                ),
              ),
              FbButton.secondary(
                key: const ValueKey('check-in-change-back'),
                label: l10n.checkInChangeBack,
                onPressed: () => unawaited(
                  _report(
                    context,
                    (a) => a.changeBack(id),
                    (l10n) => l10n.checkInChangedBackDone,
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
    final suggestion = ref.watch(incompleteDaySuggestionProvider).value;
    if (suggestion == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final date = suggestion.date;
    final day = DateFormat.MMMEd(l10n.localeName)
        .format(DateTime(date.year, date.month, date.day));
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: FbDensity.cardGap),
      child: FbProposalCard(
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
            ),
          ),
          onConfirm: () => unawaited(
            _report(
              context,
              (a) => a.markIncomplete(date),
              (l10n) => l10n.diaryDayMarkedIncomplete,
            ),
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
    final view = ref.watch(expenditureViewProvider).value;
    if (view == null) return const SizedBox.shrink();
    final l10n = context.l10n;
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
            if (r.weighInsToLog > 0)
              Text(
                l10n.adaptiveWeighInsToGo(r.weighInsToLog),
                style: FbType.body,
              )
            else if (r.spanDaysToGo > 0)
              Text(l10n.adaptiveSpanToGo(r.spanDaysToGo), style: FbType.body),
            if (days > 0) Text(l10n.adaptiveDaysToGo(days), style: FbType.body),
            Text(l10n.adaptiveIntro, style: muted),
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
