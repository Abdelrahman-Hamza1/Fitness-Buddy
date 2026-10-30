import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart' show phoneApp;

/// Setup on a fixed draft (no database).
class _Fixed extends SetupFlow {
  new(this.draft);

  final SetupDraft draft;

  @override
  Future<SetupDraft> build() async => draft;
}

/// A filled-in metric draft on [page].
SetupDraft _draft(SetupPage page) => SetupDraft(
  today: LocalDate(2026, 10, 29),
  units: UnitSystem.metric,
  weekStart: DayOfWeek.saturday,
  halal: true,
  page: page,
  sex: FormulaSex.male,
  birthYear: '1990',
  height: const HeightDraft(cm: '180'),
  weight: const BodyWeightDraft(text: '90'),
  activity: ActivityLevel.moderate,
  goal: const GoalDraft().withType(GoalType.lose),
  touched: true,
);

/// Setup on [page]'s fixed draft, not set up yet.
List<Override> _overrides(SetupPage page) => [
  setupFlowProvider.overrideWith(() => _Fixed(_draft(page))),
  setupStatusProvider.overrideWith((ref) async => SetupStatus.notSetUp),
];

Future<void> _golden(SetupPage page) => goldenTest(
  'UX-060 UX-070 setup page ${page.index + 1} (${page.name}), light/dark at '
  'text scale 1.0 and 2.0',
  fileName: 'setup_${page.name}',
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
                overrides: _overrides(page),
                child: phoneApp(
                  const SetupScreen(),
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
  // Only the first page is a key screen (TD-104).
  await _golden(SetupPage.you);
}
