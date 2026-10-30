import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:fb_mobile/features/progress/application/measurement_graph_providers.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:fb_mobile/features/progress/presentation/graph_range_chips.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// One measurement type (WB-041, WB-042, WB-022, A15b D16/D18): its graph
/// (entries as dots, the trend line from 5 entries, ranges with All by
/// default), the selected entry's details with Edit, and the entries newest
/// first (swipe to delete with undo, tap to edit). Custom types get a menu
/// with Rename and Delete type. [typeKey] is a `MeasurementTypeRef.key`; an
/// unknown or removed one shows the removed state.
class MeasurementTypeScreen extends ConsumerWidget {
  /// The screen of the type [typeKey].
  const new({required this.typeKey, super.key});

  /// The type's route key.
  final String typeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(measurementSeriesProvider(typeKey));
    final length =
        (ref.watch(unitSystemProvider).value ?? UnitSystem.defaultSystem)
            .length;
    final shown = view.value;
    final name = shown == null
        ? l10n.measurementsTitle
        : measurementTypeName(l10n, shown.ref, customName: shown.customName);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (shown?.type case final type?)
            FbIconButton(
              icon: FbIcons.more,
              tooltip: l10n.measurementMenu,
              onPressed: () => unawaited(_menu(context, ref, shown!, type)),
            ),
        ],
      ),
      body: switch (view) {
        AsyncData(value: null) => FbEmptyState(
          icon: FbIcons.chart,
          title: l10n.measurementRemoved,
          message: l10n.measurementRemovedMessage,
        ),
        AsyncData(value: final value?) => _Body(
          typeKey: typeKey,
          view: value,
          name: name,
          unit: measurementDisplayUnit(value.ref.kind, length),
        ),
        AsyncError() => FbEmptyState(
          icon: FbIcons.chart,
          title: l10n.measurementsTitle,
          message: l10n.measurementError,
          action: FbButton.secondary(
            label: l10n.measurementTryAgain,
            onPressed: () => ref.invalidate(measurementsProvider),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsetsDirectional.all(FbSpace.s4),
          child: FbSkeleton.box(width: double.infinity, height: 240),
        ),
      },
      bottomNavigationBar: shown == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  FbSpace.s4,
                  FbSpace.s2,
                  FbSpace.s4,
                  FbSpace.s4,
                ),
                child: FbButton.primary(
                  label: l10n.measurementAdd,
                  icon: FbIcons.add,
                  expand: true,
                  onPressed: () =>
                      unawaited(showMeasurementSheet(context, type: shown.ref)),
                ),
              ),
            ),
    );
  }

  /// Rename or Delete type.
  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    MeasurementTypeView view,
    MeasurementType type,
  ) async {
    final l10n = context.l10n;
    final choice = await showFbSheet<String>(
      context,
      builder: (sheet) => FbOptionList<String>(
        options: [
          FbOption(value: 'rename', label: l10n.measurementRenameType),
          FbOption(value: 'delete', label: l10n.measurementDeleteType),
        ],
        selected: null,
        onSelected: (value) => Navigator.of(sheet).pop(value),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'rename':
        await showCustomTypeSheet(context, rename: type);
      case 'delete':
        await _deleteType(context, ref, view, type);
    }
  }

  /// Deletes [type] with its entries (asks first when it has some; undo
  /// restores type and entries).
  Future<void> _deleteType(
    BuildContext context,
    WidgetRef ref,
    MeasurementTypeView view,
    MeasurementType type,
  ) async {
    final entries = view.series.points;
    if (entries.isNotEmpty) {
      final confirmed = await showFbSheet<bool>(
        context,
        title: context.l10n.measurementDeleteTypeTitle(type.name),
        builder: (sheet) => _DeleteTypeSheet(count: entries.length),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(measurementActionsProvider.notifier)
        .deleteType(type, entries);
    if (!host.mounted) return;
    final l10n = host.l10n;
    switch (outcome) {
      case MeasurementDone(:final undoId):
        ref.read(appNavigatorProvider).pop();
        showUndoFeedback(
          host,
          message: l10n.measurementTypeDeleted(type.name),
          undoEntryId: undoId,
        );
      case MeasurementFailed(:final reason):
        showFbSnackBar(
          host,
          reason == MeasurementFailure.changed
              ? l10n.measurementFailedChanged
              : l10n.measurementFailedInvalid,
        );
      case MeasurementUnchanged() || MeasurementPending():
        break;
    }
  }
}

/// Asks before deleting a type with entries: Keep (the dominant choice) or
/// Delete.
class _DeleteTypeSheet extends StatelessWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(
          l10n.measurementDeleteTypeMessage(count),
          style: FbType.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        FbButton.primary(
          label: l10n.measurementDeleteTypeKeep,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FbButton.secondary(
          label: l10n.measurementDeleteTypeConfirm,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const new({
    required this.typeKey,
    required this.view,
    required this.name,
    required this.unit,
  });

  final String typeKey;
  final MeasurementTypeView view;
  final String name;
  final MeasurementUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final series = view.series;
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    if (series.points.isEmpty) {
      return FbEmptyState(
        icon: FbIcons.chart,
        title: l10n.measurementNoEntries,
        message: l10n.measurementTypeEmpty,
      );
    }
    final window = ref.watch(measurementGraphWindowControllerProvider(typeKey));
    final controller = ref.read(
      measurementGraphWindowControllerProvider(typeKey).notifier,
    );
    final selectedId = ref.watch(selectedMeasurementProvider(typeKey));
    final points = measurementChartOrdered(series.points);
    final chartWindow = ChartWindow.of(
      window.range,
      today,
      firstDate: series.first!.localDate,
      panStart: window.panStart,
    );
    Measurement? selected;
    for (final m in series.points) {
      if (m.id == selectedId) selected = m;
    }
    final latest = series.latest!;
    final first = series.first!;
    final percent = unit == MeasurementUnit.percent;
    final trend = series.trend;
    // Goal phases shaded like the weight graph (A16 D12, TG-012).
    final phases = ref.watch(goalHistoryProvider).value ?? GoalPhases(const []);
    return ListView(
      padding: const EdgeInsetsDirectional.all(FbSpace.s4),
      children: [
        Text(
          l10n.measurementLatest(
            measurementText(l10n, latest.value, unit),
            dayLabel(context, latest.localDate, today),
          ),
          style: FbType.title,
        ),
        if (series.change case final change?)
          Text(
            l10n.measurementChangeSince(
              measurementDiffText(l10n, change, unit),
              dayLabel(context, first.localDate, today),
            ),
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
        const SizedBox(height: FbSpace.s3),
        GraphRangeChips(
          range: window.range,
          onRange: controller.setRange,
          panned: window.panStart != null,
          onToday: controller.reset,
        ),
        const SizedBox(height: FbSpace.s3),
        FbTimeSeriesChart(
          aspectRatio: 1.4,
          range: FbChartRange(start: chartWindow.start, end: chartWindow.end),
          panBounds: chartWindow.pans
              ? FbChartRange(start: chartWindow.panMin, end: chartWindow.panMax)
              : null,
          onRangeChanged: (r) => controller.setPanStart(r.start),
          series: [
            FbSeries(
              style: FbSeriesStyle.points,
              tone: trend == null ? FbSeriesTone.primary : FbSeriesTone.muted,
              selectable: true,
              semanticLabel: l10n.measurementLegendEntries,
              points: [
                for (final m in points)
                  FbPoint(
                    measurementChartTime(m),
                    measurementIn(m.value, unit),
                    key: m.id,
                  ),
              ],
            ),
            if (trend != null)
              FbSeries(
                style: FbSeriesStyle.line,
                semanticLabel: l10n.measurementLegendTrend,
                points: [
                  for (final p in trend)
                    FbPoint(
                      DateTime.utc(
                        p.localDate.year,
                        p.localDate.month,
                        p.localDate.day,
                      ),
                      measurementIn(p.trend, unit),
                    ),
                ],
              ),
          ],
          periods: phasePeriods(
            phases.records,
            phases.history,
            today.plusDays(800),
            (record) => goalPhaseLabel(l10n, record),
          ),
          selected: selected == null
              ? null
              : FbPointRef(series: 0, key: selected.id),
          onSelect: (p) => ref
              .read(selectedMeasurementProvider(typeKey).notifier)
              .select(p?.key as String?),
          formatValue: (v) => percent
              ? l10n.measurementValue(
                  measurementNumber(l10n, v),
                  measurementUnitLabel(l10n, unit),
                )
              : measurementNumber(l10n, v),
          formatDate: (at, step) => graphTickLabel(l10n, at, step),
          semanticLabel: l10n.measurementGraphSemantics(
            name,
            '${series.points.length}',
          ),
        ),
        if (trend == null) ...[
          const SizedBox(height: FbSpace.s2),
          Text(
            l10n.measurementTrendHint,
            style: FbType.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: FbSpace.s3),
        if (selected == null)
          Text(l10n.measurementTapHint, style: FbType.bodySmall)
        else
          _Details(measurement: selected),
        const SizedBox(height: FbSpace.s3),
        FbSectionHeader(title: l10n.measurementEntries),
        for (final m in series.points.reversed)
          FbSwipeActions(
            key: ValueKey<String>(m.id),
            dismissAction: FbSwipeAction(
              label: l10n.measurementDelete,
              icon: FbIcons.delete,
              onTriggered: () => unawaited(_delete(context, ref, m)),
            ),
            child: FbListRow(
              title: measurementInputText(l10n, m.input),
              subtitle: dayLabel(context, m.localDate, today),
              onTap: () => unawaited(showMeasurementSheet(context, edit: m)),
            ),
          ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Measurement measurement,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(measurementActionsProvider.notifier)
        .delete(measurement);
    if (!host.mounted) return;
    switch (outcome) {
      case MeasurementDone(:final undoId):
        showUndoFeedback(
          host,
          message: host.l10n.measurementDeleted,
          undoEntryId: undoId,
        );
      case MeasurementFailed():
        showFbSnackBar(host, host.l10n.measurementFailedChanged);
      case MeasurementUnchanged() || MeasurementPending():
        break;
    }
  }
}

/// The selected entry (WB-022): its value as typed, date and time, Edit.
class _Details extends StatelessWidget {
  const new({required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final local = measurement.time.localDateTime;
    final date = measurement.localDate;
    final when = DateFormat.yMMMd(l10n.localeName).add_jm().format(
      DateTime(date.year, date.month, date.day, local.hour, local.minute),
    );
    return FbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FbSpace.s1,
        children: [
          Text(
            measurementInputText(l10n, measurement.input),
            style: FbType.title,
          ),
          Text(
            when,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbButton.secondary(
              label: l10n.measurementEdit,
              onPressed: () =>
                  unawaited(showMeasurementSheet(context, edit: measurement)),
            ),
          ),
        ],
      ),
    );
  }
}
