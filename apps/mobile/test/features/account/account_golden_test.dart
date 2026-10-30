import 'package:alchemist/alchemist.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/presentation/sign_out_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

final class _FixedSignIn extends SignInController {
  new(this._state);

  final SignInState _state;

  @override
  SignInState build() => _state;
}

/// The overrides every scenario needs, plus [extra].
List<Override> _base(List<Override> extra) => [
  appNavigatorProvider.overrideWithValue(RecordingNavigator()),
  googleSignInAvailableProvider.overrideWithValue(false),
  ...extra,
];

/// One golden per surface: light and dark at text scale 1.0 and 2.0, on a
/// 360 dp phone (UX-070).
Future<void> _golden(
  String description,
  String file,
  Widget Function() screen, {
  List<Override> overrides = const [],
  double height = 800,
}) => goldenTest(
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
              height: height,
              child: ProviderScope(
                overrides: _base(overrides),
                child: phoneApp(
                  screen(),
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
  for (final status in [AccountStatus.guest, AccountStatus.signedIn]) {
    await _golden(
      'AC-002 AC-004 UX-070 Me › Account (${status.name})',
      'account_section_${status.name}',
      () =>
          const Scaffold(body: SingleChildScrollView(child: AccountSection())),
      overrides: [accountStatusProvider.overrideWith((ref) async => status)],
      height: 700,
    );
  }

  await _golden(
    'AC-001 AC-003 UX-070 sign-in: email step',
    'sign_in_email',
    () => const SignInScreen(),
    overrides: [
      signInControllerProvider.overrideWith(
        () => _FixedSignIn(const SignInState()),
      ),
    ],
  );

  await _golden(
    'AC-003 UX-070 sign-in: merge refused, both copies stay',
    'sign_in_merge_blocked',
    () => const SignInScreen(),
    overrides: [
      signInControllerProvider.overrideWith(
        () => _FixedSignIn(
          const SignInState(step: SignInStep.conflict, mergeBlocked: true),
        ),
      ),
    ],
  );

  await _golden(
    'AC-004 UX-070 the sign-out sheet: keep a read-only copy or remove',
    'sign_out_sheet',
    () => Scaffold(body: SignOutSheetBody(onSelected: (_) {})),
    height: 500,
  );
}
