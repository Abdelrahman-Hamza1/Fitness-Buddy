import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('A65 m12 a destructive button is filled in the error-container '
      'tone, not brand ink', (tester) async {
    await pumpFb(
      tester,
      FbButton.destructive(label: 'Delete', onPressed: () {}),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final context = tester.element(find.byType(FilledButton));
    final scheme = Theme.of(context).colorScheme;
    expect(button.style?.backgroundColor?.resolve({}), scheme.errorContainer);
    expect(button.style?.foregroundColor?.resolve({}), scheme.error);
  });

  testWidgets('A65 M4 a row group shows its header, the rows in one card and '
      'its note; nothing without rows', (tester) async {
    await pumpFb(
      tester,
      const Column(
        children: [
          FbRowGroup(
            title: 'Header',
            note: 'A quiet note',
            children: [
              FbListRow(title: 'One'),
              FbListRow(title: 'Two'),
            ],
          ),
          FbRowGroup(key: ValueKey('empty'), title: 'Empty', children: []),
        ],
      ),
    );
    expect(find.byType(FbSectionHeader), findsOneWidget);
    expect(find.byType(FbCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FbCard),
        matching: find.byType(FbListRow),
      ),
      findsNWidgets(2),
    );
    expect(find.text('A quiet note'), findsOneWidget);
    expect(find.text('Empty'), findsNothing);
  });

  testWidgets('A65 m18 a trailing action sits at the end at 1.0 and under the '
      'text at large text', (tester) async {
    Widget row() => const FbListRow(
      title: 'Push day',
      subtitle: '5 exercises',
      trailingAction: Text('Log', key: ValueKey('action')),
    );
    await pumpFb(tester, row());
    expect(tester.widget<ListTile>(find.byType(ListTile)).trailing, isNotNull);
    await pumpFb(tester, row(), textScale: 2);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.trailing, isNull);
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byKey(const ValueKey('action')),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A65 m9 an action sheet lists destructive choices last and '
      'returns the chosen value', (tester) async {
    String? picked;
    await pumpFb(
      tester,
      Builder(
        builder: (context) => FbButton.primary(
          label: 'open',
          onPressed: () async {
            picked = await showFbActionSheet<String>(
              context,
              title: 'Menu',
              actions: const [
                FbAction(value: 'delete', label: 'Delete', destructive: true),
                FbAction(value: 'rename', label: 'Rename', icon: FbIcons.edit),
              ],
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final rename = tester.getTopLeft(find.text('Rename')).dy;
    final delete = tester.getTopLeft(find.text('Delete')).dy;
    expect(rename, lessThan(delete));
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(picked, 'rename');
  });

  // Only the handle: the discard guard itself (Back, a tap outside, Keep
  // editing, Discard, Save) is exercised on the real estimate and macro
  // sheets in the app's tests (A65 review 5).
  testWidgets('A65 m8 a sheet shown without drag hides its handle', (
    tester,
  ) async {
    await pumpFb(
      tester,
      Builder(
        builder: (context) => FbButton.primary(
          label: 'open',
          onPressed: () => showFbSheet<void>(
            context,
            enableDrag: false,
            builder: (_) => const Text('form'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('form'), findsOneWidget);
    expect(find.bySemanticsLabel('Drag handle'), findsNothing);
  });

  testWidgets('A65 N5 a tag is a static label', (tester) async {
    await pumpFb(tester, const FbTag(label: '3 days', selected: true));
    expect(find.text('3 days'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}
