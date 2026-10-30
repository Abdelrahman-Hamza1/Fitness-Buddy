import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Sign in or create an account (AC-001, AC-003): email → code, or Google
/// when configured; a 409 asks merge or discard. Renders [SignInController].
class SignInScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    final error = switch (state.failure) {
      null => null,
      AccountFailureKind.offline => l10n.signInErrorOffline,
      AccountFailureKind.invalidCode => l10n.signInErrorCode,
      AccountFailureKind.throttled => l10n.signInErrorThrottled,
      AccountFailureKind.googleUnavailable ||
      AccountFailureKind.rejected ||
      AccountFailureKind.cancelled => l10n.signInErrorOther,
    };
    void run(Future<void> Function() action) => unawaited(action());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSignIn)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        children: [
          ...switch (state.step) {
            SignInStep.email => [
              FbTextField(
                controller: _email,
                label: l10n.signInEmailLabel,
                keyboardType: TextInputType.emailAddress,
                errorText: error,
              ),
              const SizedBox(height: FbSpace.s3),
              FbButton.primary(
                label: l10n.signInSendCode,
                onPressed: state.busy
                    ? null
                    : () => run(() => controller.submitEmail(_email.text)),
              ),
              if (ref.watch(googleSignInAvailableProvider)) ...[
                const SizedBox(height: FbSpace.s3),
                FbButton.secondary(
                  label: l10n.signInGoogle,
                  onPressed: state.busy ? null : () => run(controller.google),
                ),
              ],
            ],
            SignInStep.code => [
              FbTextField(
                controller: _code,
                label: l10n.signInCodeLabel,
                keyboardType: TextInputType.number,
                maxLength: 6,
                errorText: error,
              ),
              const SizedBox(height: FbSpace.s3),
              FbButton.primary(
                label: l10n.signInVerify,
                onPressed: state.busy
                    ? null
                    : () => run(() => controller.submitCode(_code.text)),
              ),
            ],
            SignInStep.conflict => [
              Text(
                l10n.signInConflictTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: FbSpace.s2),
              Text(
                state.mergeBlocked
                    ? l10n.signInMergeBlocked
                    : l10n.signInConflictBody,
              ),
              const SizedBox(height: FbSpace.s3),
              if (!state.mergeBlocked) ...[
                FbButton.primary(
                  label: l10n.signInMerge,
                  onPressed: state.busy
                      ? null
                      : () =>
                            run(() => controller.choose(ConflictChoice.merge)),
                ),
                const SizedBox(height: FbSpace.s2),
              ],
              FbButton.secondary(
                label: l10n.signInDiscard,
                onPressed: state.busy
                    ? null
                    : () =>
                          run(() => controller.choose(ConflictChoice.discard)),
              ),
            ],
            SignInStep.done => [
              Text(l10n.signInDone),
              const SizedBox(height: FbSpace.s3),
              FbButton.primary(
                label: l10n.signInDoneButton,
                onPressed: ref.read(appNavigatorProvider).pop,
              ),
            ],
          },
        ],
      ),
    );
  }
}
