import 'dart:ui' show Tristate;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

const List<FbOption<int>> _options = [
  FbOption(value: 1, label: 'Metric', subtitle: 'Grams'),
  FbOption(value: 2, label: 'Imperial', subtitle: 'Ounces'),
];

/// A shell like the app's: the opener lives in a nested (tab) navigator.
class _Shell extends StatelessWidget {
  const new({required this.picked});

  final List<int?> picked;

  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () async => picked.add(
            await showFbOptionSheet<int>(
              context,
              title: 'Units',
              options: _options,
              selected: 1,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('UX-011 showFbOptionSheet: the selected option is checked; a '
      'tap returns it; opens on the root navigator', (tester) async {
    final handle = tester.ensureSemantics();
    final picked = <int?>[];
    await pumpFb(tester, _Shell(picked: picked));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Checked and announced as selected.
    expect(find.text('Units'), findsOneWidget);
    expect(find.byIcon(FbIcons.check), findsOneWidget);
    final metric = tester.getSemantics(find.widgetWithText(ListTile, 'Metric'));
    final imperial = tester.getSemantics(
      find.widgetWithText(ListTile, 'Imperial'),
    );
    expect(metric.flagsCollection.isSelected, Tristate.isTrue);
    expect(imperial.flagsCollection.isSelected, Tristate.isFalse);

    // On the root navigator, above the shell's own navigator.
    final root = Navigator.of(
      tester.element(find.text('Units')),
      rootNavigator: true,
    );
    final inner = Navigator.of(tester.element(find.text('open')));
    expect(identical(root, inner), isFalse);
    expect(
      find.descendant(
        of: find.byWidget(inner.widget),
        matching: find.text('Units'),
      ),
      findsNothing,
    );

    // A tap returns the value and closes the sheet.
    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();
    expect(picked, [2]);
    expect(find.text('Units'), findsNothing);
    handle.dispose();
  });

  testWidgets('UX-011 showFbOptionSheet: dismissing returns null', (
    tester,
  ) async {
    final picked = <int?>[];
    await pumpFb(tester, _Shell(picked: picked));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(picked, [null]);
  });
}
