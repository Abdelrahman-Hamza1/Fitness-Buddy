import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/progress/application/progress_period.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/presentation/progress_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The period selector shared by every chart on the tab (IN-009, A16 D3):
/// Week · Month · Phase choices of equal width, then `‹ label ›`. › stops
/// at the current period; ‹ stops at the earliest data. The Phase choice
/// shows only when a phase has started.
class ProgressPeriodBar extends ConsumerWidget {
  /// Creates the bar for [view].
  const new({required this.view, super.key});

  /// What is shown.
  final ProgressView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(progressPeriodControllerProvider.notifier);
    final kind = view.selection.kind;
    final kinds = [
      (ProgressPeriodKind.week, l10n.progressPeriodWeek),
      (ProgressPeriodKind.month, l10n.progressPeriodMonth),
      if (view.hasPhases) (ProgressPeriodKind.phase, l10n.progressPeriodPhase),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: FbSpace.s2,
          children: [
            for (final (value, label) in kinds)
              Expanded(
                child: FbChoiceChip(
                  key: ValueKey('progress-period-${value.name}'),
                  label: label,
                  dropdown: false,
                  selected: kind == value,
                  onTap: () => controller.setKind(value),
                ),
              ),
          ],
        ),
        const SizedBox(height: FbSpace.s2),
        Row(
          children: [
            FbIconButton(
              key: const ValueKey('progress-period-previous'),
              icon: FbIcons.previous,
              tooltip: l10n.progressPeriodPrevious,
              onPressed: view.canPrevious ? controller.previous : null,
            ),
            Expanded(
              child: Text(
                periodLabel(l10n, view),
                textAlign: TextAlign.center,
                style: FbType.title,
              ),
            ),
            FbIconButton(
              key: const ValueKey('progress-period-next'),
              icon: FbIcons.next,
              tooltip: l10n.progressPeriodNext,
              onPressed: view.canNext ? controller.next : null,
            ),
          ],
        ),
      ],
    );
  }
}
