import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

/// The question screens on a fixed draft (no database).
class _Fixed extends SetupFlow {
  new(this.draft);

  final SetupDraft draft;

  @override
  Future<SetupDraft> build(SetupMode mode) async => draft;
}

/// A filled-in metric draft on [page].
SetupDraft _draft(SetupPage page, {SetupMode mode = SetupMode.setup}) =>
    SetupDraft(
      today: LocalDate(2026, 10, 29),
      units: UnitSystem.metric,
      weekStart: DayOfWeek.saturday,
      halal: true,
      mode: mode,
      page: page,
      sex: FormulaSex.male,
      birthYear: '1990',
      height: const HeightDraft(cm: '180'),
      weight: const BodyWeightDraft(text: '90'),
      activity: ActivityLevel.moderate,
      goal: const GoalDraft().withType(GoalType.lose),
      training: TrainingChoice.mixItUp,
      touched: true,
    );

/// The fixed [draft], not set up yet, a guest with Google available.
List<Override> _overrides(SetupDraft draft) => [
  setupFlowProvider.overrideWith2((_) => _Fixed(draft)),
  setupStatusProvider.overrideWith((ref) async => SetupStatus.notSetUp),
  accountStatusProvider.overrideWith((ref) async => AccountStatus.guest),
  googleSignInAvailableProvider.overrideWithValue(true),
  appNavigatorProvider.overrideWithValue(RecordingNavigator()),
];

Future<void> _golden(
  String description,
  String file,
  Widget screen,
  List<Override> overrides,
) => goldenTest(
  description,
  fileName: file,
  builder: () => GoldenTestGroup(
    columns: 4,
    children: [
      for (final scale in const [1.0, 2.0])
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$label, x$scale',
            child: SizedBox(
              width: 360,
              height: 760,
              child: ProviderScope(
                overrides: overrides,
                child: phoneApp(
                  screen,
                  brightness: brightness,
                  textScale: scale,
                ),
              ),
            ),
          ),
    ],
  ),
);

Future<void> main() async {
  // The key screens only (TD-104): the welcome, a question, the plan and
  // the account step.
  await _golden(
    'D-088 UX-070 first run welcome, light/dark at text scale 1.0 and 2.0',
    'first_run_welcome',
    const WelcomeScreen(),
    _overrides(_draft(SetupPage.goal)),
  );
  await _golden(
    'UX-060 UX-070 setup goal question, light/dark at text scale 1.0 and 2.0',
    'setup_goal',
    const SetupScreen(),
    _overrides(_draft(SetupPage.goal)),
  );
  await _golden(
    'UX-060 TG-021 UX-070 setup plan, light/dark at text scale 1.0 and 2.0',
    'setup_plan',
    const SetupScreen(),
    _overrides(_draft(SetupPage.plan)),
  );
  await _golden(
    'D-088 AC-002 UX-070 first run account step, light/dark at text scale '
        '1.0 and 2.0',
    'first_run_account',
    const SetupScreen(mode: SetupMode.firstRun),
    _overrides(_draft(SetupPage.account, mode: SetupMode.firstRun)),
  );
}
