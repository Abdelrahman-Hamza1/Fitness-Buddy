import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/edit_proposal_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/food_proposal_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/progress_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/today_mockup.dart';
import 'package:fb_mobile/features/design_preview/presentation/mockups/weight_card_mockup.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Phone width and minimum height of a mockup golden, in dp (A02 D8). A
/// taller mockup (text x2) is shown whole, not cropped.
const double _width = 360;
const double _height = 800;

/// [mockup] as a screen: the theme of [brightness], text [scale], LTR only
/// in R1 (`09` §3), animations off.
Widget _screen(Widget mockup, Brightness brightness, double scale) {
  final theme = brightness == Brightness.light
      ? FbTheme.light()
      : FbTheme.dark();
  return Theme(
    data: theme,
    child: Localizations(
      locale: const Locale('en'),
      delegates: const [
        AppLocalizations.delegate,
        FbLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: DefaultTextStyle(
              style: theme.textTheme.bodyMedium!,
              child: SizedBox(
                width: _width,
                child: Material(
                  color: theme.colorScheme.surface,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _height),
                    child: mockup,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _mockupGolden(String name, String file, Widget mockup) =>
    goldenTest(
      name,
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
                child: _screen(mockup, brightness, scale),
              ),
        ],
      ),
    );

Future<void> main() async {
  await _mockupGolden(
    'HM-001 HM-003 HM-008 Today mockup',
    'mockup_today',
    const TodayMockup(),
  );
  await _mockupGolden(
    'AI-031 AI-032 AI-033 AI-034 food proposal mockup',
    'mockup_food_proposal',
    const FoodProposalMockup(),
  );
  await _mockupGolden(
    'UX-026 AI-050 edit proposal mockup',
    'mockup_edit_proposal',
    const EditProposalMockup(),
  );
  await _mockupGolden(
    'HM-005 weight card mockup',
    'mockup_weight_card',
    const WeightCardMockup(),
  );
  await _mockupGolden(
    'IN-001 Progress overview mockup',
    'mockup_progress',
    const ProgressMockup(),
  );
}
