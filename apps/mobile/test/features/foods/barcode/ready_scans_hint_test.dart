import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

final class _Scans extends PendingScans {
  new(this.scans);
  final List<PendingScan> scans;

  @override
  Future<List<PendingScan>> build() async => scans;
}

Future<void> _pump(
  WidgetTester tester,
  List<PendingScan> scans,
  RecordingNavigator navigator,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pendingScansProvider.overrideWith(() => _Scans(scans)),
        appNavigatorProvider.overrideWithValue(navigator),
      ],
      child: phoneApp(const ReadyScansTodayHint()),
    ),
  );
  await tester.pumpAndSettle();
}

PendingScan _scan(String code, PendingScanState state) =>
    PendingScan(code: code, scannedAtMs: 0, state: state, name: 'Product');

void main() {
  const hint = ValueKey('today-ready-scans');

  testWidgets('#229 A28a D10 Today counts the waiting scans that became '
      'ready; Show opens the scanner that lists them', (tester) async {
    final navigator = RecordingNavigator();
    await _pump(tester, [
      _scan('1', PendingScanState.ready),
      _scan('2', PendingScanState.ready),
      _scan('3', PendingScanState.waiting),
      _scan('4', PendingScanState.notFound),
    ], navigator);
    expect(find.text('2 scanned products are ready'), findsOneWidget);
    await tester.tap(find.text('Show'));
    expect(navigator.pushed.single, isA<BarcodeScanRoute>());
  });

  testWidgets('#229 nothing while no scan is ready', (tester) async {
    await _pump(tester, [
      _scan('3', PendingScanState.waiting),
    ], RecordingNavigator());
    expect(find.byKey(hint), findsNothing);
  });
}
