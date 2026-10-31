import 'package:alchemist/alchemist.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/sync/sync.dart';
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

/// Everything synced, last sync a minute ago.
const _synced = SyncView(
  enabled: true,
  running: false,
  restoring: false,
  restoredRows: 0,
  problem: SyncProblem.none,
  pending: 0,
  parked: 0,
  lastSuccessMs: 1760351174567,
  oldestPendingMs: null,
  nowMs: 1760351234567,
);

Future<void> main() async {
  for (final status in [AccountStatus.guest, AccountStatus.signedIn]) {
    await _golden(
      'AC-002 AC-004 UX-070 Me › Account (${status.name})',
      'account_section_${status.name}',
      () =>
          const Scaffold(body: SingleChildScrollView(child: AccountSection())),
      overrides: [
        accountStatusProvider.overrideWith((ref) async => status),
        // A34: the sync line shows a settled state.
        syncViewProvider.overrideWithValue(_synced),
      ],
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
}
