import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
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
    this.email,
    this.codesSent = 0,
    this.askName = false,
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

  /// The address the code went to, shown on the code step (memory only;
  /// never in [toString]).
  final String? email;

  /// How many codes this screen has sent: a new one restarts the resend
  /// countdown (A51).
  final int codesSent;

  /// The done step asks "What should we call you?" (an email sign-in,
  /// M2, A63 D10).
  final bool askName;

  @override
  String toString() => 'SignInState(${step.name}, busy: $busy)';
}

/// Orchestrates the sign-in screen (A33 D4–D5, D9).
@riverpod
class SignInController extends _$SignInController {
  EmailChallengeRef? _challenge;
  String? _email;
  late SignInFlow _flow;

  /// The profile the last sign-in committed to, for the name step (PA2).
  String? _signedInKey;

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
    final address = email.trim();
    _email = address;
    _challenge = await _flow.startEmail(address);
    return SignInState(
      step: SignInStep.code,
      email: address,
      codesSent: state.codesSent + 1,
    );
  });

  /// Sends a new code to the same address (A51: "Resend code").
  Future<void> resend() async {
    final email = _email;
    if (email == null || state.step != SignInStep.code) return;
    await submitEmail(email);
  }

  /// Back to the email step ("Use a different email"): the pending code
  /// is dropped.
  void changeEmail() {
    if (state.busy) return;
    _challenge = null;
    state = SignInState(codesSent: state.codesSent);
  }

  /// Verifies [code].
  Future<void> submitCode(String code) => _run(() async {
    final challenge = _challenge;
    if (challenge == null) return const SignInState();
    return await _after(
      await _flow.verifyEmail(challenge, code.trim()),
      askName: true,
    );
  });

  /// Google sign-in.
  Future<void> google() => _run(() async {
    return await _after(await _flow.signInWithGoogle());
  });

  /// The merge/discard answer after a conflict.
  Future<void> choose(ConflictChoice choice) => _run(() async {
    final result = await _flow.chooseOnConflict(choice);
    if (result != null) return await _after(result);
    // Email: the conflict consumed the link code; send a sign-in code.
    final email = _email;
    if (email == null) return const SignInState();
    _challenge = await _flow.startEmail(email);
    return SignInState(
      step: SignInStep.code,
      email: email,
      codesSent: state.codesSent + 1,
    );
  });

  /// The name typed on the done step (M2): stored for the signed-in
  /// profile; empty skips. Either way it was asked, so it isn't offered
  /// again. Never sent or logged.
  Future<void> saveName(String name) async {
    final key = _signedInKey;
    if (key == null) return;
    ref.read(recentSignInProvider.notifier).nameAsked();
    if (LocalIdentity.cleanName(name) == null) return;
    final store = ref.read(localIdentityStoreProvider);
    try {
      await store.setName(key, name);
    } on Object {
      // Editable later in Account & data.
    }
    if (ref.mounted) ref.invalidate(accountStatusProvider);
  }

  Future<SignInState> _after(
    SignInResult result, {
    bool askName = false,
  }) async {
    final outcome = result.outcome;
    // Who signed in is already stored by the service (it outlives this
    // screen). A profile switch disposes this controller: nothing to show.
    if (result.identity case final who?) _signedInKey = who.profileKey;
    if (!ref.mounted) return const SignInState(step: SignInStep.done);
    ref.invalidate(accountStatusProvider);
    return switch (outcome) {
      AccountOutcome.needsConflictChoice => const SignInState(
        step: SignInStep.conflict,
      ),
      AccountOutcome.mergeBlocked => const SignInState(
        step: SignInStep.conflict,
        mergeBlocked: true,
      ),
      AccountOutcome.cancelled => SignInState(
        step: state.step,
        email: state.email,
        codesSent: state.codesSent,
      ),
      _ => SignInState(
        step: SignInStep.done,
        outcome: outcome,
        askName: askName && result.identity != null,
      ),
    };
  }

  Future<void> _run(Future<SignInState> Function() action) async {
    final before = state;
    state = SignInState(
      step: before.step,
      busy: true,
      email: before.email,
      codesSent: before.codesSent,
      mergeBlocked: before.mergeBlocked,
    );
    try {
      final next = await action();
      if (ref.mounted) state = next;
    } on AccountFailure catch (failure) {
      if (ref.mounted) {
        state = SignInState(
          step: before.step,
          failure: failure.kind,
          email: before.email,
          codesSent: before.codesSent,
          mergeBlocked: before.mergeBlocked,
        );
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
