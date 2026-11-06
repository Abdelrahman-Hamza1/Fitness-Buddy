import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/ui/step_transition.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Sign in or create an account (AC-001, AC-003, A51 D6): a benefit-led
/// header, Google's own button when Google sign-in is available, then the
/// email → 6-digit code; a 409 asks merge or discard. "Keep using without
/// an account" closes it (AC-002). [startWithGoogle] starts Google at once
/// (the first run's "Continue with Google"). Renders [SignInController].
class SignInScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({this.startWithGoogle = false, super.key});

  /// Start Google sign-in when the screen opens (when available).
  final bool startWithGoogle;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  /// How long a new code can't be asked for again.
  static const Duration resendWait = Duration(seconds: 30);

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  Timer? _ticker;

  /// What the last started action was, to word the busy button (A57 A79).
  _Action? _action;
  int _wait = 0;

  @override
  void initState() {
    super.initState();
    if (widget.startWithGoogle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !ref.read(googleSignInAvailableProvider)) return;
        unawaited(ref.read(signInControllerProvider.notifier).google());
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  /// A new code went out: clear the boxes and start the countdown.
  void _codeSent() {
    _code.clear();
    _ticker?.cancel();
    setState(() => _wait = resendWait.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _wait--);
      if (_wait <= 0) timer.cancel();
    });
  }

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      ref.read(appNavigatorProvider).go(const TodayRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    ref.listen(signInControllerProvider.select((s) => s.codesSent), (
      previous,
      next,
    ) {
      if (next > (previous ?? 0)) _codeSent();
    });
    final error = switch (state.failure) {
      null => null,
      AccountFailureKind.offline => l10n.signInErrorOffline,
      AccountFailureKind.invalidCode => l10n.signInErrorCode,
      AccountFailureKind.throttled => l10n.signInErrorThrottled,
      AccountFailureKind.googleUnavailable => l10n.signInErrorGoogleUnavailable,
      AccountFailureKind.rejected ||
      AccountFailureKind.cancelled => l10n.signInErrorOther,
    };
    void run(Future<void> Function() action, [_Action? kind]) {
      setState(() => _action = kind);
      unawaited(action());
    }

    final busy = state.busy;
    // Only the button that started the work says so; it keeps its bounds.
    final sending = busy && _action == _Action.email;
    final verifying = busy && _action == _Action.code;
    return Scaffold(
      appBar: AppBar(
        leading: FbIconButton(
          icon: FbIcons.close,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: _close,
        ),
      ),
      body: SafeArea(
        // Each step comes in on a shared axis, from the top (A57 A26).
        child: StepTransition(
          child: ListView(
            key: ValueKey(state.step),
            padding: const EdgeInsetsDirectional.fromSTEB(
              FbSpace.s4,
              FbSpace.s2,
              FbSpace.s4,
              FbSpace.s5,
            ),
            children: switch (state.step) {
              SignInStep.email => [
                _Header(title: l10n.accountSignIn, body: l10n.signInBenefit),
                const SizedBox(height: FbSpace.s5),
                if (ref.watch(googleSignInAvailableProvider)) ...[
                  FbGoogleButton(
                    label: l10n.signInGoogle,
                    onPressed: busy ? null : () => run(controller.google),
                  ),
                  const _Or(),
                ],
                FbTextField(
                  controller: _email,
                  label: l10n.signInEmailLabel,
                  hint: l10n.signInEmailHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.go,
                  onSubmitted: busy
                      ? null
                      : (text) => run(
                          () => controller.submitEmail(text),
                          _Action.email,
                        ),
                  // The note and an error share one reserved place (UX-045).
                  supportingText: l10n.signInEmailNote,
                  supportingLines: 2,
                  errorText: error,
                ),
                const SizedBox(height: FbSpace.s4),
                FbButton.primary(
                  key: const ValueKey('sign-in-email-button'),
                  label: sending ? l10n.signInSending : l10n.signInEmailButton,
                  busy: sending,
                  expand: true,
                  onPressed: busy
                      ? null
                      : () => run(
                          () => controller.submitEmail(_email.text),
                          _Action.email,
                        ),
                ),
                const SizedBox(height: FbSpace.s5),
                FbButton.text(
                  label: l10n.signInWithoutAccount,
                  expand: true,
                  onPressed: busy ? null : _close,
                ),
              ],
              SignInStep.code => [
                _Header(
                  title: l10n.signInCodeTitle,
                  body: l10n.signInCodeSent(state.email ?? ''),
                ),
                const SizedBox(height: FbSpace.s5),
                FbCodeBoxes(
                  controller: _code,
                  label: l10n.signInCodeLabel,
                  autofocus: true,
                  enabled: !busy,
                  supportingText: l10n.signInCodePaste,
                  supportingLines: 2,
                  errorText: error,
                  onCompleted: (code) =>
                      run(() => controller.submitCode(code), _Action.code),
                ),
                const SizedBox(height: FbSpace.s4),
                FbButton.primary(
                  key: const ValueKey('sign-in-verify-button'),
                  label: verifying ? l10n.signInVerifying : l10n.signInVerify,
                  busy: verifying,
                  expand: true,
                  onPressed: busy
                      ? null
                      : () => run(
                          () => controller.submitCode(_code.text),
                          _Action.code,
                        ),
                ),
                const SizedBox(height: FbSpace.s3),
                FbButton.text(
                  label: _wait > 0
                      ? l10n.signInResendIn(_countdown(_wait))
                      : l10n.signInResend,
                  expand: true,
                  onPressed: busy || _wait > 0
                      ? null
                      : () => run(controller.resend),
                ),
                FbButton.text(
                  label: l10n.signInChangeEmail,
                  expand: true,
                  onPressed: busy ? null : controller.changeEmail,
                ),
              ],
              SignInStep.conflict => [
                _Header(
                  title: l10n.signInConflictTitle,
                  body: state.mergeBlocked
                      ? l10n.signInMergeBlocked
                      : l10n.signInConflictBody,
                ),
                const SizedBox(height: FbSpace.s5),
                if (error != null) ...[
                  FbInlineBanner(
                    kind: FbInlineBannerKind.error,
                    message: error,
                  ),
                  const SizedBox(height: FbSpace.s3),
                ],
                if (!state.mergeBlocked) ...[
                  FbButton.primary(
                    label: l10n.signInMerge,
                    expand: true,
                    onPressed: busy
                        ? null
                        : () => run(
                            () => controller.choose(ConflictChoice.merge),
                          ),
                  ),
                  const SizedBox(height: FbSpace.s2),
                ],
                FbButton.secondary(
                  label: l10n.signInDiscard,
                  expand: true,
                  onPressed: busy
                      ? null
                      : () => run(
                          () => controller.choose(ConflictChoice.discard),
                        ),
                ),
              ],
              SignInStep.done => [
                _Header(title: l10n.signInDone),
                const SizedBox(height: FbSpace.s5),
                // M2 (A63 D10): after an email sign-in, once; skippable,
                // editable later in Account & data. Kept on this phone.
                if (state.askName) ...[
                  FbTextField(
                    key: const ValueKey('sign-in-name'),
                    controller: _name,
                    label: l10n.signInNameLabel,
                    supportingText: l10n.signInNameHint,
                    maxLength: LocalIdentity.nameMax,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: FbSpace.s3),
                ],
                FbButton.primary(
                  key: const ValueKey('sign-in-done'),
                  label: l10n.signInDoneButton,
                  expand: true,
                  onPressed: () async {
                    if (state.askName) await controller.saveName(_name.text);
                    if (!mounted) return;
                    ref.read(appNavigatorProvider).pop();
                  },
                ),
              ],
            },
          ),
        ),
      ),
    );
  }

  /// "0:42".
  static String _countdown(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// The step's title (a heading for a screen reader) and its line.
class _Header extends StatelessWidget {
  const new({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FbSpace.s2,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: FbType.headline.copyWith(color: scheme.onSurface),
          ),
        ),
        if (body case final body?)
          Text(
            body,
            style: FbType.body.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// The actions whose button words its own busy state.
enum _Action { email, code }

/// "or" between two hairlines.
class _Or extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s4),
      child: Row(
        spacing: FbSpace.s3,
        children: [
          Expanded(child: Divider(color: scheme.outlineVariant)),
          Text(
            context.l10n.signInOr,
            style: FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant),
          ),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ],
      ),
    );
  }
}
