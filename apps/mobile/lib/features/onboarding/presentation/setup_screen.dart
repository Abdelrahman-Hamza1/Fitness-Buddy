import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/account_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/activity_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/goal_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/plan_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/training_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/you_page.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The question screens (UX-060, D-088, A51): one topic per page outside
/// the tabs, a segmented progress bar, Skip on every question, Continue
/// pinned at the bottom (UX-070), every answer kept in memory until the
/// plan is confirmed. Fully offline. "Looks good" writes one change set
/// (profile, first weigh-in, goal, targets, units) and offers Undo; then
/// the first run shows the optional account step, setup goes to Today (or
/// the starter plans for "I want a plan"). Closing with something answered
/// asks first (UX-052). A profile this app version can't read shows
/// "Update the app" instead (A13a security review #3).
class SetupScreen extends ConsumerWidget {
  /// Creates the screen for [mode].
  const new({this.mode = SetupMode.setup, super.key});

  /// Setup from Today or Me, or the first run.
  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(setupStatusProvider).value;
    if (status == SetupStatus.profileUnreadable) {
      return const _UpdateNeeded();
    }
    final draft = ref.watch(setupFlowProvider(mode)).value;
    // Local reads only: the first frame has the bar and no body, never a
    // spinner.
    if (draft == null) return const _Shell();
    if (draft.alreadySetUp) return const _AlreadySetUp();
    return _Flow(draft: draft);
  }
}

/// The bar alone: the first frame, and the moment before leaving.
class _Shell extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: _bar(context, onClose: () => _Flow._close(context, ref)),
  );
}

AppBar _bar(BuildContext context, {required VoidCallback onClose}) {
  final l10n = context.l10n;
  return AppBar(
    leading: IconButton(
      icon: const Icon(FbIcons.close),
      tooltip: l10n.setupClose,
      onPressed: onClose,
    ),
    title: Text(l10n.setupTitle),
  );
}

/// Today and "Your targets are already set up.": setup ran already (an old
/// link, or another device).
void _alreadySetUp(BuildContext host, WidgetRef ref) {
  ref.read(appNavigatorProvider).go(const TodayRoute());
  showFbSnackBar(host, host.l10n.setupAlreadySetUp);
}

/// Setup opened when it had already run: says so and goes to Today.
class _AlreadySetUp extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_AlreadySetUp> createState() => _AlreadySetUpState();
}

class _AlreadySetUpState extends ConsumerState<_AlreadySetUp> {
  Animation<double>? _entrance;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _leaveWhenShown());
  }

  /// After the route has come in: leaving mid-transition would rebuild the
  /// tabs while the old ones are still going out.
  void _leaveWhenShown() {
    if (!mounted || _left) return;
    final entrance = ModalRoute.of(context)?.animation;
    if (entrance != null && !entrance.isCompleted) {
      _entrance = entrance..addStatusListener(_onStatus);
      return;
    }
    _left = true;
    _alreadySetUp(Navigator.of(context, rootNavigator: true).context, ref);
  }

  void _onStatus(AnimationStatus status) {
    if (status.isCompleted) _leaveWhenShown();
  }

  @override
  void dispose() {
    _entrance?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const _Shell();
}

class _Flow extends ConsumerStatefulWidget {
  const new({required this.draft});

  final SetupDraft draft;

  static void _close(BuildContext context, WidgetRef ref) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      ref.read(appNavigatorProvider).go(const TodayRoute());
    }
  }

  @override
  ConsumerState<_Flow> createState() => _FlowState();
}

class _FlowState extends ConsumerState<_Flow> {
  /// The required inputs, so a refused Continue scrolls to the first
  /// problem.
  final Map<SetupField, GlobalKey> _fieldKeys = {
    for (final field in SetupField.values) field: GlobalKey(),
  };

  SetupDraft get draft => widget.draft;

  SetupFlow get _flow => ref.read(setupFlowProvider(draft.mode).notifier);

  /// Continue: the next page, the end of the flow, or this page's messages
  /// and a scroll to the first problem (UX-052).
  void _continue() {
    switch (_flow.next()) {
      case SetupMove.finished:
        _finish();
      case SetupMove.moved:
        break;
      case SetupMove.refused:
        _showProblem();
    }
  }

  void _skip() {
    if (_flow.skip() == SetupMove.finished) _finish();
  }

  void _showProblem() {
    final now = ref.read(setupFlowProvider(draft.mode)).value;
    final problem = now?.firstProblem;
    if (problem == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _fieldKeys[problem]?.currentContext;
      if (!mounted || target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: .1,
        duration: FbMotion.of(context),
        curve: FbMotion.curve,
      );
    });
  }

  /// Back one page; on the first page the flow closes (asking first when
  /// something was answered); after the save it ends.
  void _back() {
    if (_flow.back()) return;
    if (draft.saved) {
      _finish();
    } else {
      unawaited(_leave());
    }
  }

  Future<void> _leave() async {
    if (draft.touched) {
      final leave = await showFbSheet<bool>(
        context,
        title: context.l10n.setupLeaveTitle,
        builder: (_) => const _LeaveSheet(),
      );
      if (leave != true || !mounted) return;
    }
    _Flow._close(context, ref);
  }

  /// The flow is over: the starter plans for "I want a plan" (A52 owns
  /// them), else Today.
  void _finish() {
    // The flow's state now (a Skip just before may have changed it).
    final now = ref.read(setupFlowProvider(draft.mode)).value ?? draft;
    ref
        .read(appNavigatorProvider)
        .go(
          now.wantsPlan ? const WorkoutStarterPlansRoute() : const TodayRoute(),
        );
  }

  Future<void> _save() async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await _flow.save();
    if (outcome == null || !host.mounted) return;
    final l10n = host.l10n;
    switch (outcome) {
      case TargetsDone(:final undoEntryId):
        // The first run goes on to the account step; setup ends here.
        if (draft.mode == SetupMode.setup) _finish();
        showUndoFeedback(
          host,
          message: l10n.setupSaved,
          undoEntryId: undoEntryId,
        );
      case TargetsFailed(reason: TargetsFailure.alreadySetUp):
        _alreadySetUp(host, ref);
      case TargetsFailed(:final reason):
        showFbSnackBar(
          host,
          goalFailureText(l10n, reason) ?? l10n.setupSaveFailed,
        );
      case TargetsPending() ||
          TargetsUnchanged() ||
          TargetsNeedsAcknowledgement():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flow = _flow;
    final pages = draft.pages;
    final question = switch (draft.page) {
      SetupPage.goal ||
      SetupPage.you ||
      SetupPage.activity ||
      SetupPage.training => true,
      SetupPage.plan || SetupPage.account => false,
    };
    final signedIn =
        ref.watch(accountStatusProvider).value == AccountStatus.signedIn;
    final page = switch (draft.page) {
      SetupPage.goal => GoalPage(
        draft: draft,
        flow: flow,
        fieldKeys: _fieldKeys,
      ),
      SetupPage.you => YouPage(draft: draft, flow: flow, fieldKeys: _fieldKeys),
      SetupPage.activity => ActivityPage(
        draft: draft,
        flow: flow,
        fieldKeys: _fieldKeys,
      ),
      SetupPage.training => TrainingPage(
        draft: draft,
        flow: flow,
        fieldKeys: _fieldKeys,
      ),
      SetupPage.plan => PlanPage(draft: draft),
      SetupPage.account => AccountPage(signedIn: signedIn),
    };
    final first = draft.before == null;
    final leading = draft.saved
        ? null
        : IconButton(
            icon: Icon(
              first && draft.mode == SetupMode.setup
                  ? FbIcons.close
                  : FbIcons.previous,
            ),
            tooltip: first && draft.mode == SetupMode.setup
                ? l10n.setupClose
                : l10n.setupBack,
            onPressed: _back,
          );
    final actions = _Actions(
      children: switch (draft.page) {
        SetupPage.goal ||
        SetupPage.you ||
        SetupPage.activity ||
        SetupPage.training => [
          FbButton.primary(
            label: l10n.setupContinue,
            expand: true,
            // Always on (UX-052): a refused Continue says what's
            // missing.
            onPressed: _continue,
          ),
        ],
        SetupPage.plan => [
          if (draft.preview?.calculation != null || draft.saving)
            FbButton.primary(
              label: l10n.setupPlanConfirm,
              expand: true,
              onPressed: draft.canSave ? () => unawaited(_save()) : null,
            )
          else
            FbButton.primary(
              label: l10n.setupPlanSkip,
              expand: true,
              onPressed: _skip,
            ),
          FbButton.text(
            label: l10n.setupPlanChange,
            expand: true,
            onPressed: draft.saving
                ? null
                : () => unawaited(showChangeNumbers(context, draft.mode)),
          ),
        ],
        SetupPage.account when signedIn => [
          FbButton.primary(
            label: l10n.setupAccountFinish,
            expand: true,
            onPressed: _finish,
          ),
        ],
        SetupPage.account => [
          if (ref.watch(googleSignInAvailableProvider))
            FbGoogleButton(
              label: l10n.signInGoogle,
              onPressed: () => ref
                  .read(appNavigatorProvider)
                  .push(const SignInRoute(withGoogle: true)),
            ),
          FbButton.secondary(
            label: l10n.signInEmailButton,
            icon: FbIcons.email,
            expand: true,
            onPressed: () =>
                ref.read(appNavigatorProvider).push(const SignInRoute()),
          ),
          FbButton.text(
            label: l10n.setupAccountNotNow,
            expand: true,
            onPressed: _finish,
          ),
        ],
      },
    );
    return PopScope(
      canPop: false,
      // The system back goes one page back; on the first page it closes,
      // asking first when something was answered.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: leading,
          titleSpacing: leading == null ? FbSpace.s4 : 0,
          title: FbStepBar(
            count: pages.length,
            current: draft.step,
            semanticsLabel: l10n.setupStep(draft.step + 1, pages.length),
          ),
          actions: [
            if (question)
              FbButton.text(label: l10n.setupSkip, onPressed: _skip)
            else
              const SizedBox(width: FbSpace.s4),
          ],
        ),
        // The plan's and account step's buttons sit under the body, so the
        // Undo snackbar of the save floats above them instead of over them.
        bottomNavigationBar: question ? null : SafeArea(child: actions),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(draft.page),
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    FbSpace.s4,
                    FbSpace.s3,
                    FbSpace.s4,
                    FbSpace.s5,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: page,
                ),
              ),
              if (question) actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// The page's buttons, pinned under it so they stay on screen at any text
/// size (UX-070).
class _Actions extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      FbSpace.s4,
      FbSpace.s2,
      FbSpace.s4,
      FbSpace.s3,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s2,
      children: children,
    ),
  );
}

/// "Leave setup?": keep going (the dominant choice) or leave.
class _LeaveSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        Text(
          l10n.setupLeaveMessage,
          style: FbType.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        FbButton.primary(
          label: l10n.setupLeaveStay,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FbButton.secondary(
          label: l10n.setupLeaveConfirm,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// A stored profile this version can't read: no setup over it.
class _UpdateNeeded extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FbIcons.close),
          tooltip: l10n.setupClose,
          onPressed: () => _Flow._close(context, ref),
        ),
        title: Text(l10n.setupTitle),
      ),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(FbSpace.s4),
        child: FbEmptyState(
          icon: FbIcons.info,
          title: l10n.setupUpdateTitle,
          message: l10n.setupUpdateMessage,
        ),
      ),
    );
  }
}
