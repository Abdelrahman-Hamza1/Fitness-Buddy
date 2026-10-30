import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The range chips of every graph (WB-020, A15a D5; shared by the weight
/// and measurement graphs, A15b D24): 1M · 3M · 6M · 1Y · All, plus a
/// "Today" chip once the window was panned.
///
/// The row never changes size (A45 D4): the chips are steady and the Today
/// chip's slot is always laid out, hidden (no taps, no semantics) until the
/// window is panned, so it never wraps the row and pushes the graph down.
class GraphRangeChips extends StatelessWidget {
  /// Chips with [range] selected; [onRange] picks another. With [panned]
  /// the Today chip shows and calls [onToday].
  const new({
    required this.range,
    required this.onRange,
    this.panned = false,
    this.onToday,
    super.key,
  });

  /// The selected range.
  final GraphRange range;

  /// Called with the tapped range.
  final ValueChanged<GraphRange> onRange;

  /// Whether the window was panned away from today.
  final bool panned;

  /// Back to the window ending today.
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: FbSpace.s2,
      runSpacing: FbSpace.s2,
      children: [
        for (final r in GraphRange.values)
          FbChoiceChip(
            label: graphRangeLabel(l10n, r),
            selected: r == range,
            dropdown: false,
            onTap: () => onRange(r),
          ),
        Visibility(
          visible: panned,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: FbChoiceChip(
            label: l10n.weightGraphToday,
            dropdown: false,
            onTap: onToday,
          ),
        ),
      ],
    );
  }
}

/// The chip text of [range]: "1M", "3M", "6M", "1Y", "All".
String graphRangeLabel(AppLocalizations l10n, GraphRange range) =>
    switch (range) {
      GraphRange.m1 => l10n.weightGraphRange1M,
      GraphRange.m3 => l10n.weightGraphRange3M,
      GraphRange.m6 => l10n.weightGraphRange6M,
      GraphRange.y1 => l10n.weightGraphRange1Y,
      GraphRange.all => l10n.weightGraphRangeAll,
    };

/// A chart axis label for [at] at [step]: "Oct 17", "Oct", "2026".
String graphTickLabel(AppLocalizations l10n, DateTime at, FbTimeStep step) {
  final local = DateTime(at.year, at.month, at.day);
  return switch (step) {
    FbTimeStep.day => DateFormat.MMMd(l10n.localeName).format(local),
    FbTimeStep.month => DateFormat.MMM(l10n.localeName).format(local),
    FbTimeStep.year => DateFormat.y(l10n.localeName).format(local),
  };
}
