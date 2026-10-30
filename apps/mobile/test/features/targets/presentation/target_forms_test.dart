import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import 'target_forms_support.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(phoneApp(screen));
  await tester.pump();
}

void main() {
  testWidgets('TG-011 the goal form shows the weekly rate, the monthly figure '
      'and, with a target weight, the projected month', (tester) async {
    final weekly = loseDraft();
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: weekly,
          onChanged: (_) {},
          today: formToday,
          calculation: calculationFor(weekly),
        ),
      ),
    );
    expect(find.text('≈ −0.5 kg a week · −2.2 kg in October'), findsOneWidget);
    expect(find.text('Lose each week'), findsOneWidget);

    final paced = loseDraft()
        .withKind(GoalExpressionKind.targetRate)
        .copyWith(targetWeight: '85', pace: '0.5');
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: paced,
          onChanged: (_) {},
          today: formToday,
          calculation: calculationFor(paced),
        ),
      ),
    );
    expect(
      find.text(
        '≈ −0.5 kg a week · −2.2 kg in October · goal reached around '
        'January 2027',
      ),
      findsOneWidget,
    );

    // The same goal in lb.
    final inPounds = loseDraft().withUnit(MassUnit.pound);
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: inPounds,
          onChanged: (_) {},
          today: formToday,
          calculation: calculationFor(inPounds),
        ),
      ),
    );
    expect(find.text('≈ −1.1 lb a week · −4.9 lb in October'), findsOneWidget);
  });

  testWidgets('UX-052 a refused Next shows the messages of the goal fields, '
      'keeping the text', (tester) async {
    final draft = loseDraft()
        .withKind(GoalExpressionKind.targetDate)
        .copyWith(targetWeight: '700');
    await _pump(
      tester,
      formScreen(
        GoalForm(
          draft: draft,
          onChanged: (_) {},
          today: formToday,
          showErrors: true,
        ),
      ),
    );
    expect(find.text('Enter a weight between 20 and 500 kg.'), findsOneWidget);
    expect(find.text('700'), findsOneWidget);
    expect(find.text('Pick a target date.'), findsOneWidget);
  });
}
