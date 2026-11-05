import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  for (final disabled in [false, true]) {
    testWidgets('UX-046 A57 T-M1 FbMotion.localOf/structuralOf are zero '
        'only under disableAnimations ($disabled)', (tester) async {
      late Duration local;
      late Duration structural;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disabled),
          child: Builder(
            builder: (context) {
              local = FbMotion.localOf(context);
              structural = FbMotion.structuralOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(local, disabled ? Duration.zero : FbMotion.local);
      expect(structural, disabled ? Duration.zero : FbMotion.structural);
    });
  }

  Widget reveal({required bool visible}) => Column(
    children: [
      const SizedBox(key: ValueKey('above'), height: 40),
      FbReveal(
        visible: visible,
        child: const SizedBox(key: ValueKey('content'), height: 100),
      ),
      const SizedBox(key: ValueKey('below'), height: 10),
    ],
  );

  testWidgets('UX-046 A57 D17 FbReveal grows downward over FbMotion.local; '
      'what is above stays put', (tester) async {
    await pumpFb(tester, reveal(visible: false), disableAnimations: false);
    final above = tester.getTopLeft(find.byKey(const ValueKey('above')));
    final below0 = tester.getTopLeft(find.byKey(const ValueKey('below'))).dy;
    await pumpFb(tester, reveal(visible: true), disableAnimations: false);
    await tester.pump(FbMotion.local ~/ 2);
    final belowMid = tester.getTopLeft(find.byKey(const ValueKey('below'))).dy;
    expect(belowMid, greaterThan(below0));
    expect(belowMid, lessThan(below0 + 100));
    expect(tester.getTopLeft(find.byKey(const ValueKey('above'))), above);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('below'))).dy,
      below0 + 100,
    );
  });

  testWidgets('UX-046 A57 T-M1 FbReveal and FbSizeFade are instant under '
      'reduced motion', (tester) async {
    await pumpFb(tester, reveal(visible: false));
    final below0 = tester.getTopLeft(find.byKey(const ValueKey('below'))).dy;
    await pumpFb(tester, reveal(visible: true));
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('below'))).dy,
      below0 + 100,
    );
    Widget fade(double h) => Column(
      children: [
        FbSizeFade(
          child: SizedBox(key: ValueKey(h), height: h),
        ),
        const SizedBox(key: ValueKey('below'), height: 10),
      ],
    );
    await pumpFb(tester, fade(20));
    final top = tester.getTopLeft(find.byKey(const ValueKey('below'))).dy;
    await pumpFb(tester, fade(60));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('below'))).dy, top + 40);
  });

  testWidgets('A57 D17 a hidden FbReveal takes no taps and no semantics', (
    tester,
  ) async {
    var taps = 0;
    await pumpFb(
      tester,
      FbReveal(
        visible: false,
        child: TextButton(onPressed: () => taps++, child: const Text('Go')),
      ),
    );
    expect(find.text('Go'), findsNothing);
    expect(find.bySemanticsLabel('Go'), findsNothing);
    expect(taps, 0);
  });

  testWidgets('A57 D17 FbReveal.entering grows in on mount', (tester) async {
    await pumpFb(
      tester,
      const Column(
        children: [
          FbReveal.entering(child: SizedBox(key: ValueKey('c'), height: 80)),
          SizedBox(key: ValueKey('below'), height: 10),
        ],
      ),
      disableAnimations: false,
    );
    final start = tester.getTopLeft(find.byKey(const ValueKey('below'))).dy;
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('below'))).dy,
      greaterThan(start),
    );
  });

  testWidgets('A57 D17 mid-swap only the incoming FbSizeFade state takes '
      'taps, focus and semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    final taps = <String>[];
    // The new button sits lower, so a tap on the old one can't reach it.
    Widget state(String name) => FbSizeFade(
      child: Padding(
        key: ValueKey(name),
        padding: EdgeInsetsDirectional.only(top: name == 'old' ? 0 : 80),
        child: TextButton(onPressed: () => taps.add(name), child: Text(name)),
      ),
    );
    await pumpFb(tester, state('old'), disableAnimations: false);
    await pumpFb(tester, state('new'), disableAnimations: false);
    await tester.pump(FbMotion.structural ~/ 2);
    expect(find.text('old'), findsOne, reason: 'still fading out');
    expect(find.semantics.byLabel('old'), findsNothing);
    expect(find.semantics.byLabel('new'), findsOne);
    expect(Focus.of(tester.element(find.text('old'))).canRequestFocus, isFalse);
    await tester.tap(find.text('old'), warnIfMissed: false);
    expect(taps, isEmpty);
    await tester.tap(find.text('new'));
    expect(taps, ['new']);
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}
