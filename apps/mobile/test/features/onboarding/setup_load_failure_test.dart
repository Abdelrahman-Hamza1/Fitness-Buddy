import 'package:fb_mobile/core/ui/load_states.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import 'setup_support.dart';

/// The setup flow's first read fails while [fail] is true.
bool _fail = true;

final class _FailingFlow extends SetupFlow {
  @override
  Future<SetupDraft> build(SetupMode mode) async {
    if (_fail) throw StateError('read failed (test)');
    return await super.build(mode);
  }
}

void main() {
  testWidgets('A57 A47 T-R4 (#286) a failed setup read says so with Try '
      'again, and the retry opens the flow', (tester) async {
    _fail = true;
    final container = await openSetup(
      tester,
      overrides: [setupFlowProvider.overrideWith2((_) => _FailingFlow())],
    );
    expect(find.byKey(LoadFailedView.viewKey), findsOneWidget);
    expect(find.text("Couldn't load your setup."), findsOneWidget);

    _fail = false;
    await tester.tap(find.text('Try again'));
    await settleWrites(tester);
    expect(find.byKey(LoadFailedView.viewKey), findsNothing);
    expect(find.byType(SetupScreen), findsOneWidget);
    await unmountApp(tester, container);
  });
}
