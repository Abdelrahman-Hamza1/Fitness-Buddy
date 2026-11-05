import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/layout_stability.dart';
import '../helpers/pump.dart';

const _longError =
    'This number is far outside what a food can hold, so check the label '
    'again and type it the way it is printed on the package.';

void main() {
  for (final scale in stabilityScales) {
    testWidgets('UX-045 A57 T-S3 FbNumberField keeps its height when an '
        'error appears and wraps (scale $scale)', (tester) async {
      final controller = TextEditingController(text: '12');
      addTearDown(controller.dispose);
      Future<void> pump(String? error) => pumpFb(
        tester,
        Column(
          children: [
            FbNumberField(
              key: const ValueKey('field'),
              controller: controller,
              label: 'Protein',
              unit: 'g',
              supportingText: 'Per 100 g',
              errorText: error,
            ),
            const SizedBox(key: ValueKey('below'), height: 10),
          ],
        ),
        textScale: scale,
      );
      await pump(null);
      final below = find.byKey(const ValueKey('below'));
      await expectStable(
        tester,
        find.byKey(const ValueKey('field')),
        () => pump('Too high'),
        anchor: below,
        reason: 'short error',
      );
      expect(find.text('Too high'), findsOneWidget);
      await expectStable(
        tester,
        find.byKey(const ValueKey('field')),
        () => pump(_longError),
        anchor: below,
        reason: 'long error',
      );
      await expectStable(
        tester,
        find.byKey(const ValueKey('field')),
        () => pump(null),
        anchor: below,
        reason: 'error cleared',
      );
      expect(find.text('Per 100 g'), findsOneWidget);
    });

    testWidgets('UX-045 A57 T-S3 FbTextField keeps its height when an error '
        'appears and wraps, with the counter in the same line '
        '(scale $scale)', (tester) async {
      final controller = TextEditingController(text: 'Oats');
      addTearDown(controller.dispose);
      Future<void> pump(String? error) => pumpFb(
        tester,
        FbTextField(
          key: const ValueKey('field'),
          controller: controller,
          label: 'Name',
          maxLength: 40,
          errorText: error,
        ),
        textScale: scale,
      );
      await pump(null);
      expect(find.text('4/40'), findsOneWidget);
      await expectStable(
        tester,
        find.byKey(const ValueKey('field')),
        () => pump(_longError),
      );
      await expectStable(
        tester,
        find.byKey(const ValueKey('field')),
        () => pump(null),
      );
    });

    testWidgets('UX-045 A57 T-S3 FbCodeBoxes keep their height when an error '
        'appears (scale $scale)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Future<void> pump(String? error) => pumpFb(
        tester,
        FbCodeBoxes(
          key: const ValueKey('code'),
          controller: controller,
          label: 'Code',
          errorText: error,
        ),
        textScale: scale,
      );
      await pump(null);
      await expectStable(
        tester,
        find.byKey(const ValueKey('code')),
        () => pump(_longError),
      );
    });
  }

  testWidgets('A57 D12 supportingLines 0 reserves nothing; the error shows '
      'as the outline only', (tester) async {
    final controller = TextEditingController(text: '1');
    addTearDown(controller.dispose);
    await pumpFb(
      tester,
      FbNumberField(
        controller: controller,
        label: 'kg',
        supportingLines: 0,
        errorText: 'Too high',
      ),
    );
    expect(find.text('Too high'), findsNothing);
    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.error, isNotNull);
  });

  testWidgets('A57 A60 T-A4 FbCodeBoxes accept Arabic-Indic and Persian '
      'digits, typed and pasted', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final done = <String>[];
    await pumpFb(
      tester,
      FbCodeBoxes(controller: controller, label: 'Code', onCompleted: done.add),
    );
    await tester.enterText(find.byType(TextField), '٤٨١');
    expect(controller.text, '481');
    await tester.enterText(find.byType(TextField), '٤٨١ ۹۲۰');
    expect(controller.text, '481920');
    expect(done, ['481920']);
    expect(
      normalizeDigits('٠١٢٣٤٥٦٧٨٩ ۰۱۲۳۴۵۶۷۸۹ x'),
      '0123456789 0123456789 x',
    );
  });

  for (final scale in stabilityScales) {
    testWidgets('UX-045 A57 D14 FbNumberSlot has one width for 85 and 1,240 '
        '(scale $scale)', (tester) async {
      Future<void> pump(String text) => pumpFb(
        tester,
        Row(
          children: [
            const Expanded(child: Text('name', key: ValueKey('name'))),
            FbNumberSlot(
              key: const ValueKey('slot'),
              text: text,
              style: FbType.body,
            ),
          ],
        ),
        textScale: scale,
      );
      await pump('85');
      await expectStable(
        tester,
        find.byKey(const ValueKey('name')),
        () => pump('1,240'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('UX-045 A57 A04 T-S6 FbMacroBars keep their mode when a value '
      'gains a digit', (tester) async {
    List<FbMacroValue> macros(String protein) => [
      FbMacroValue(
        kind: FbMacroKind.protein,
        value: 1,
        target: 2,
        label: 'Protein',
        valueText: protein,
      ),
      const FbMacroValue(
        kind: FbMacroKind.carbs,
        value: 1,
        target: 2,
        label: 'Carbs',
        valueText: '9 / 250 g',
      ),
      const FbMacroValue(
        kind: FbMacroKind.fat,
        value: 1,
        target: 2,
        label: 'Fat',
        valueText: '9 / 80 g',
      ),
      const FbMacroValue(
        kind: FbMacroKind.fiber,
        value: 1,
        target: 2,
        label: 'Fiber',
        valueText: '9 / 30 g',
      ),
    ];
    for (final scale in [1.0, 1.3]) {
      Future<void> pump(String protein) => pumpFb(
        tester,
        FbMacroBars(key: const ValueKey('bars'), macros: macros(protein)),
        textScale: scale,
      );
      await pump('9 / 180 g');
      await expectStable(
        tester,
        find.byKey(const ValueKey('bars')),
        () => pump('999 / 180 g'),
        reason: 'scale $scale',
      );
    }
  });

  testWidgets('A57 D9 FbInputBar shows a badge without growing, and reads '
      'the tap hint', (tester) async {
    Future<void> pump(String? badge) => pumpFb(
      tester,
      FbInputBar(
        key: const ValueKey('bar'),
        hint: 'Tell Buddy what you ate',
        badge: badge,
        badgeKey: const ValueKey('badge'),
        semanticsHint: 'open waiting cards',
        onTap: () {},
        onCamera: () {},
        onBarcode: () {},
      ),
    );
    await pump(null);
    expect(find.byKey(const ValueKey('badge')), findsNothing);
    await expectStable(
      tester,
      find.byKey(const ValueKey('bar')),
      () => pump('2 waiting'),
    );
    expect(find.byKey(const ValueKey('badge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
