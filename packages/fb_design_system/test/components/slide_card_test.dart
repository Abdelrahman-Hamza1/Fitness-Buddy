// Covers: HM-009, UX-051
import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('height is final logical pixels at every text scale', (
    tester,
  ) async {
    for (final scale in [1.0, 1.3, 1.4, 2.0]) {
      await pumpFb(
        tester,
        FbSlideCard(
          height: 300,
          index: 0,
          onIndexChanged: (_) {},
          semanticLabel: (s, n, c) => '$s $n $c',
          slides: [
            FbSlide(
              label: 'Nutrition',
              builder: (_) => const Text('Nutrition'),
            ),
          ],
        ),
        textScale: scale,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('fb-slide-card'))).height,
        300,
      );
    }
  });

  testWidgets('pager swipes, dots, external selection and 48dp targets', (
    tester,
  ) async {
    var index = 0;
    late StateSetter update;
    await pumpFb(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return FbSlideCard(
            height: 200,
            index: index,
            semanticLabel: (name, n, count) => '$name, $n of $count',
            onIndexChanged: (i) => setState(() => index = i),
            slides: [
              for (final label in ['Nutrition', 'Weight', 'Workout'])
                FbSlide(label: label, builder: (_) => Text(label)),
            ],
          );
        },
      ),
    );
    expect(find.bySemanticsLabel('Nutrition, 1 of 3'), findsOneWidget);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Nutrition, 1 of 3'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.increase,
    );
    await tester.pumpAndSettle();
    expect(index, 1);
    final weightNode = tester.getSemantics(
      find.bySemanticsLabel('Weight, 2 of 3'),
    );
    tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
      weightNode.id,
      SemanticsAction.decrease,
    );
    await tester.pumpAndSettle();
    expect(index, 0);
    for (var i = 0; i < 3; i++) {
      expect(
        tester.getSize(find.byKey(ValueKey('fb-slide-dot-$i'))),
        const Size(48, 48),
      );
    }
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(index, 1);
    await tester.tap(find.byKey(const ValueKey('fb-slide-dot-2')));
    await tester.pumpAndSettle();
    expect(index, 2);
    update(() => index = 0);
    await tester.pumpAndSettle();
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 0);
  });
  testWidgets('sparkline accepts flat and empty series', (tester) async {
    for (final values in <List<double>>[
      [],
      [1],
      [2, 2],
      [1, 3, 2],
    ]) {
      await pumpFb(tester, FbSparkline(values: values));
      expect(tester.takeException(), isNull);
    }
  });
}
