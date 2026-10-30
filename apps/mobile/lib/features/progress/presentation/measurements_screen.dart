import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Body measurements (WB-040, A15b D18): a row per type (waist, chest,
/// hips, arm, thigh, neck, body fat, then custom types by name) with its
/// latest value and date, "Add measurement" and "Add custom measurement".
/// A row opens the type's graph.
class MeasurementsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final views = ref.watch(latestByTypeProvider);
    final length =
        (ref.watch(unitSystemProvider).value ?? UnitSystem.defaultSystem)
            .length;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.measurementsTitle)),
      body: switch (views) {
        AsyncData(:final value)
            when value.every(
              (v) => v.series.points.isEmpty && v.type == null,
            ) =>
          FbEmptyState(
            icon: FbIcons.chart,
            title: l10n.measurementEmptyTitle,
            message: l10n.measurementEmptyMessage,
            action: _AddButtons(views: value),
          ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2),
          children: [
            for (final view in value)
              FbListRow(
                title: measurementTypeName(
                  l10n,
                  view.ref,
                  customName: view.customName,
                ),
                subtitle: _latest(context, ref, view, length),
                trailing: const Icon(FbIcons.next),
                onTap: () => ref
                    .read(appNavigatorProvider)
                    .push(MeasurementTypeRoute(view.ref.key)),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: _AddButtons(views: value),
            ),
          ],
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
          child: Column(
            spacing: FbSpace.s3,
            children: [
              FbSkeleton.line(height: 56),
              FbSkeleton.line(height: 56),
              FbSkeleton.line(height: 56),
            ],
          ),
        ),
      },
    );
  }

  static String _latest(
    BuildContext context,
    WidgetRef ref,
    MeasurementTypeView view,
    LengthUnit length,
  ) {
    final l10n = context.l10n;
    final latest = view.series.latest;
    if (latest == null) return l10n.measurementNoEntries;
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    return l10n.measurementLatest(
      measurementText(
        l10n,
        latest.value,
        measurementDisplayUnit(view.ref.kind, length),
      ),
      dayLabel(context, latest.localDate, today),
    );
  }
}

/// "Add measurement" (primary) and "Add custom measurement".
class _AddButtons extends ConsumerWidget {
  const new({required this.views});

  final List<MeasurementTypeView> views;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: [
        FbButton.primary(
          label: l10n.measurementAdd,
          icon: FbIcons.add,
          expand: true,
          onPressed: () => unawaited(showMeasurementSheet(context)),
        ),
        FbButton.text(
          label: l10n.measurementAddCustom,
          expand: true,
          onPressed: () => unawaited(_addCustom(context, ref)),
        ),
      ],
    );
  }

  /// Creates a custom type, then opens its form.
  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final id = await showCustomTypeSheet(context);
    if (id == null || !context.mounted) return;
    await showMeasurementSheet(context, type: MeasurementTypeRef.custom(id));
  }
}
