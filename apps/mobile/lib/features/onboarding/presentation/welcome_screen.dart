import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/onboarding/application/first_run_gate.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/page_parts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The first run's welcome (D-088, TD-110): the brand, what the app does in
/// three lines, and three ways on: the questions, Today without them, or
/// sign-in. Leaving by any of them marks the first run as had. Fully
/// offline.
class WelcomeScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// Whether this screen's own "Sign in" was used: only that sign-in goes
  /// to Today from here (the first run's account step finishes itself).
  bool _signingIn = false;

  void _leave(void Function(AppNavigator navigator) go) {
    unawaited(ref.read(firstRunGateProvider).markSeen());
    go(ref.read(appNavigatorProvider));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Signed in from here (A33): Today, with the account's data.
    ref.listen(accountStatusProvider, (previous, next) {
      if (_signingIn &&
          previous?.value == AccountStatus.guest &&
          next.value == AccountStatus.signedIn) {
        ref.read(appNavigatorProvider).go(const TodayRoute());
      }
    });
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  FbSpace.s5,
                  FbSpace.s6,
                  FbSpace.s5,
                  FbSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FbSpace.s4,
                  children: [
                    FbBrandLockup(
                      name: l10n.appTitle,
                      size: FbLockupSize.large,
                    ),
                    const SizedBox(height: FbSpace.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.welcomeTitle,
                        style: FbType.headline.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    SetupHint(l10n.welcomeMessage),
                    const SizedBox(height: FbSpace.s2),
                    SetupBenefit(
                      icon: FbIcons.fast,
                      title: l10n.welcomeLogTitle,
                      body: l10n.welcomeLogBody,
                    ),
                    SetupBenefit(
                      icon: FbIcons.goalLose,
                      title: l10n.welcomeTargetsTitle,
                      body: l10n.welcomeTargetsBody,
                    ),
                    SetupBenefit(
                      icon: FbIcons.navWorkouts,
                      title: l10n.welcomeWorkoutsTitle,
                      body: l10n.welcomeWorkoutsBody,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                FbSpace.s4,
                FbSpace.s2,
                FbSpace.s4,
                FbSpace.s3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FbSpace.s1,
                children: [
                  FbButton.primary(
                    label: l10n.welcomeStart,
                    expand: true,
                    onPressed: () =>
                        _leave((n) => n.push(const FirstRunSetupRoute())),
                  ),
                  FbButton.text(
                    label: l10n.welcomeSkip,
                    expand: true,
                    onPressed: () => _leave((n) => n.go(const TodayRoute())),
                  ),
                  FbButton.text(
                    label: l10n.welcomeSignIn,
                    expand: true,
                    onPressed: () {
                      _signingIn = true;
                      _leave((n) => n.push(const SignInRoute()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
