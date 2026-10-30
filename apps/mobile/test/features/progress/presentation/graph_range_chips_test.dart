import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:fb_mobile/features/progress/presentation/graph_range_chips.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart'
    show phoneApp, usePhone;

void main() {
  testWidgets('WB-020 A45 the range row keeps its size when a range is picked '
      'and when the Today chip appears', (tester) async {
    usePhone(tester);
    var todayTaps = 0;
    Future<void> pump(GraphRange range, {required bool panned}) =>
        tester.pumpWidget(
          phoneApp(
            Scaffold(
              body: Padding(
                padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: GraphRangeChips(
                    range: range,
                    onRange: (_) {},
                    panned: panned,
                    onToday: () => todayTaps++,
                  ),
                ),
              ),
            ),
          ),
        );
    Size row() => tester.getSize(find.byType(GraphRangeChips));

    await pump(GraphRange.m3, panned: false);
    final before = row();
    // The Today slot is laid out but hidden: not tappable, not announced.
    await tester.tap(find.byType(FbChoiceChip).last, warnIfMissed: false);
    expect(todayTaps, 0);

    for (final range in GraphRange.values) {
      await pump(range, panned: false);
      expect(row(), before, reason: '$range picked');
    }
    await pump(GraphRange.m1, panned: true);
    expect(row(), before, reason: 'the Today chip appeared');
    await tester.tap(find.byType(FbChoiceChip).last);
    expect(todayTaps, 1);
  });
}
