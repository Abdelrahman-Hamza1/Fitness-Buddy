import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/onboarding/application/setup_flow.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/activity_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/goal_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/preferences_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/targets_page.dart';
import 'package:fb_mobile/features/onboarding/presentation/pages/you_page.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// R1 setup (UX-060, A13 D9/D10): five pages on one screen outside the
/// tabs, "Step 2 of 5", Back and Next pinned at the bottom (UX-070), all
/// input kept in memory until Save. Fully offline. Save writes one change
/// set (profile, first weigh-in, goal, targets, changed preferences), goes
/// to Today and offers Undo. Closing with something typed asks first
/// (UX-052). A profile this app version can't read shows "Update the app"
/// instead (A13a security review #3).
class SetupScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(setupStatusProvider).value;
    if (status == SetupStatus.profileUnreadable) {
      return const _UpdateNeeded();
    }
    final draft = ref.watch(setupFlowProvider).value;
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
  /// The required inputs, so a refused Next scrolls to the first problem.
  final Map<SetupField, GlobalKey> _fieldKeys = {
    for (final field in SetupField.values) field: GlobalKey(),
  };

  SetupDraft get draft => widget.draft;

  /// Next: the following page, or this page's messages and a scroll to the
  /// first problem (UX-052).
  void _next() {
    ref.read(setupFlowProvider.notifier).next();
    final now = ref.read(setupFlowProvider).value;
    final problem = now?.page == draft.page ? now?.firstProblem : null;
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

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    if (draft.touched) {
      final leave = await showFbSheet<bool>(
        context,
        title: context.l10n.setupLeaveTitle,
        builder: (_) => const _LeaveSheet(),
      );
      if (leave != true || !context.mounted) return;
    }
    _Flow._close(context, ref);
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref.read(setupFlowProvider.notifier).save();
    if (outcome == null || !host.mounted) return;
    final l10n = host.l10n;
    switch (outcome) {
      case TargetsDone(:final undoEntryId):
        ref.read(appNavigatorProvider).go(const TodayRoute());
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
    final scheme = Theme.of(context).colorScheme;
    final flow = ref.read(setupFlowProvider.notifier);
    final first = draft.page == SetupPage.you;
    final last = draft.page == SetupPage.targets;
    final title = switch (draft.page) {
      SetupPage.you => l10n.setupPageYou,
      SetupPage.activity => l10n.setupPageActivity,
      SetupPage.goal => l10n.setupPageGoal,
      SetupPage.preferences => l10n.setupPagePreferences,
      SetupPage.targets => l10n.setupPageTargets,
    };
    final page = switch (draft.page) {
      SetupPage.you => YouPage(draft: draft, flow: flow, fieldKeys: _fieldKeys),
      SetupPage.activity => ActivityPage(
        draft: draft,
        flow: flow,
        fieldKeys: _fieldKeys,
      ),
      SetupPage.goal => GoalPage(
        draft: draft,
        flow: flow,
        fieldKeys: _fieldKeys,
      ),
      SetupPage.preferences => PreferencesPage(draft: draft, flow: flow),
      SetupPage.targets => TargetsPage(draft: draft),
    } as Widget;
    return PopScope(
      canPop: false,
      // The system back goes one page back; on the first page it closes,
      // asking first when something was typed.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (first) {
          unawaited(_leave(context, ref));
        } else {
          flow.back();
        }
      },
      child: Scaffold(
        appBar: _bar(context, onClose: () => unawaited(_leave(context, ref))),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(draft.page),
                  padding: const EdgeInsetsDirectional.all(FbSpace.s4),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FbSpace.s4,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: FbSpace.s1,
                        children: [
                          Text(
                            l10n.setupStep(draft.step, SetupDraft.steps),
                            style: FbType.caption.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: FbType.title.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      page,
                    ],
                  ),
                ),
              ),
              _Buttons(
                back: first ? null : flow.back,
                label: last ? l10n.setupSave : l10n.setupNext,
                // Always on (UX-052): a refused Next says what's missing.
                onNext: draft.saving
                    ? null
                    : last
                    ? () => unawaited(_save(context, ref))
                    : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Back and Next (or Save), pinned under the page so they stay on screen at
/// any text size (UX-070); stacked when the text is large.
class _Buttons extends StatelessWidget {
  const new({required this.back, required this.label, required this.onNext});

  final VoidCallback? back;
  final String label;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final next = FbButton.primary(
      label: label,
      expand: true,
      onPressed: onNext,
    );
    final previous = back == null
        ? null
        : FbButton.secondary(
            label: l10n.setupBack,
            expand: true,
            onPressed: back,
          );
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: BorderDirectional(
          top: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          FbSpace.s4,
          FbSpace.s3,
          FbSpace.s4,
          FbSpace.s3,
        ),
        child: large
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FbSpace.s2,
                children: [next, ?previous],
              )
            : Row(
                spacing: FbSpace.s3,
                children: [
                  if (previous != null) Expanded(child: previous),
                  Expanded(child: next),
                ],
              ),
      ),
    );
  }
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
