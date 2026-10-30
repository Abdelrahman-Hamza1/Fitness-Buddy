import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_controller.g.dart';

/// What Me › Account shows (A33): no email or id, only the state.
enum AccountStatus {
  /// A guest (sync off, AC-002).
  guest,

  /// Signed in.
  signedIn,

  /// Signed in, but the session expired: "sign in again" (D9).
  sessionExpired,

  /// A read-only copy kept after sign-out (D2).
  readOnlyCopy,
}

/// The account status from the local registry and the session state.
/// Kept alive: Today's guest prompt depends on it.
@Riverpod(keepAlive: true)
Future<AccountStatus> accountStatus(Ref ref) async {
  final session = ref.watch(sessionStateProvider);
  final profile = (await ref.watch(profileRegistryProvider).read()).active;
  if (profile.kind == ProfileKind.guest) return AccountStatus.guest;
  if (profile.readOnly) return AccountStatus.readOnlyCopy;
  if (session.status == SessionStatus.sessionExpired) {
    return AccountStatus.sessionExpired;
  }
  return AccountStatus.signedIn;
}

/// Whether Google sign-in can be offered on this build (A33 D7).
@riverpod
bool googleSignInAvailable(Ref ref) =>
    ref.watch(accountServiceProvider).googleAvailable;

/// The sign-in screen's steps.
enum SignInStep {
  /// Enter an email (or pick Google).
  email,

  /// Enter the 6-digit code.
  code,

  /// The identity has an account: merge or discard (AC-003).
  conflict,

  /// Done.
  done,
}

/// Sign-in screen state; the email is never stored beyond this view model.
final class SignInState {
  /// Creates the state.
  const new({
    this.step = SignInStep.email,
    this.busy = false,
    this.failure,
    this.outcome,
    this.mergeBlocked = false,
  });

  /// Current step.
  final SignInStep step;

  /// A request is in flight.
  final bool busy;

  /// The last failure, if any.
  final AccountFailureKind? failure;

  /// The completed outcome.
  final AccountOutcome? outcome;

  /// Merge was refused because a kept copy of the account is on the phone.
  final bool mergeBlocked;

  @override
  String toString() => 'SignInState(${step.name}, busy: $busy)';
}

/// Orchestrates the sign-in screen (A33 D4–D5, D9).
@riverpod
class SignInController extends _$SignInController {
  EmailChallengeRef? _challenge;
  String? _email;
  late SignInFlow _flow;

  @override
  SignInState build() {
    // One flow per screen: leaving the screen discards consent and any
    // pending Google token (A33 review 6).
    final flow = _flow = ref.read(accountServiceProvider).newFlow();
    ref.onDispose(flow.cancel);
    return const SignInState();
  }

  /// Sends a code to [email].
  Future<void> submitEmail(String email) => _run(() async {
    _email = email;
    _challenge = await _flow.startEmail(email);
    return const SignInState(step: SignInStep.code);
  });

  /// Verifies [code].
  Future<void> submitCode(String code) => _run(() async {
    final challenge = _challenge;
    if (challenge == null) return const SignInState();
    return _after(await _flow.verifyEmail(challenge, code.trim()));
  });

  /// Google sign-in.
  Future<void> google() => _run(() async {
    return _after(await _flow.signInWithGoogle());
  });

  /// The merge/discard answer after a conflict.
  Future<void> choose(ConflictChoice choice) => _run(() async {
    final outcome = await _flow.chooseOnConflict(choice);
    if (outcome != null) return _after(outcome);
    // Email: the conflict consumed the link code; send a sign-in code.
    final email = _email;
    if (email == null) return const SignInState();
    _challenge = await _flow.startEmail(email);
    return const SignInState(step: SignInStep.code);
  });

  SignInState _after(AccountOutcome outcome) {
    ref.invalidate(accountStatusProvider);
    return switch (outcome) {
      AccountOutcome.needsConflictChoice => const SignInState(
        step: SignInStep.conflict,
      ),
      AccountOutcome.mergeBlocked => const SignInState(
        step: SignInStep.conflict,
        mergeBlocked: true,
      ),
      AccountOutcome.cancelled => SignInState(step: state.step),
      _ => SignInState(step: SignInStep.done, outcome: outcome),
    };
  }

  Future<void> _run(Future<SignInState> Function() action) async {
    state = SignInState(step: state.step, busy: true);
    try {
      final next = await action();
      if (ref.mounted) state = next;
    } on AccountFailure catch (failure) {
      if (ref.mounted) {
        state = SignInState(step: state.step, failure: failure.kind);
      }
    }
  }
}

/// Sign-out from Me › Account (AC-004). Kept alive: the section only reads
/// it, and a sign-out outlives the frame that started it.
@Riverpod(keepAlive: true)
class AccountActions extends _$AccountActions {
  @override
  void build() {}

  /// Signs out with [choice].
  Future<void> signOut(SignOutChoice choice) async {
    await ref.read(accountServiceProvider).signOut(choice);
    ref.invalidate(accountStatusProvider);
  }

  /// Opens a guest profile, leaving the read-only copy.
  Future<void> continueAsGuest() async {
    await ref.read(accountServiceProvider).continueAsGuest();
    ref.invalidate(accountStatusProvider);
  }
}
