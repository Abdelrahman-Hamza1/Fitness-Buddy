import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart' show settleWrites;
import 'targets_screens_support.dart';

const ValueKey<String> _row = ValueKey('profile-current-weight');

/// Logs [kg] [daysAgo] days before the rig's day, at 09:00 UTC.
Future<void> _weigh(TargetsScreenRig rig, double kg, int daysAgo) => rig.settle(
  rig.container
      .read(weighInActionsProvider.notifier)
      .log(
        WeighInDraft(
          time: EntryTime.local(
            LocalDateTime(rig.today.plusDays(-daysAgo), hour: 9),
            0,
          ),
          input: WeighInInput(kg, MassUnit.kilogram),
        ),
      ),
);

String _label(WidgetTester tester) =>
    tester.getSemantics(find.byKey(_row)).label;

// Covers: WB-011
void main() {
  testWidgets('WB-011 Me › Profile: weekly weigh-ins show the latest as '
      'entered, its day and the change since the one before, also spoken', (
    tester,
  ) async {
    // Setup logs 80 kg now (Saturday); one 81.1 kg ten days before.
    final rig = await TargetsScreenRig.open(tester);
    await _weigh(rig, 81.1, 10);
    await settleWrites(tester);
    await rig.show(const ProfileRoute());
    expect(
      find.text('80.0 kg · today\n−1.1 kg since last weigh-in (10 days)'),
      findsOneWidget,
    );
    expect(_label(tester), contains('since the weigh-in before'));
    expect(_label(tester), startsWith('Current weight: Weight 80.0'));
    await rig.close();
  });

  testWidgets('WB-011 Me › Profile: frequent weigh-ins show the trend with '
      'the latest next to it, also spoken', (tester) async {
    final rig = await TargetsScreenRig.open(tester);
    for (var ago = 1; ago <= 13; ago++) {
      await _weigh(rig, 80 + ago * .1, ago);
    }
    await settleWrites(tester);
    await rig.show(const ProfileRoute());
    expect(
      find.textContaining('(trend)\nlast 80.0 kg · today'),
      findsOneWidget,
    );
    expect(_label(tester), contains('last weigh-in 80.0 kilograms today'));
    await rig.close();
  });
}
