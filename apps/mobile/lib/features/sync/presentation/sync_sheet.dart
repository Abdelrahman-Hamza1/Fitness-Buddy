import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/sync/application/sync_view.dart';
import 'package:fb_mobile/features/sync/presentation/sync_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The sync detail sheet (AC-013, UX-053): the status, the last sync time,
/// changes that couldn't sync as a banner with "Try again", and "Sync now"
/// (busy while a run is on, A65 m16; no pull-to-refresh in a sheet).
class SyncSheetBody extends ConsumerWidget {
  /// Creates the sheet's content.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(syncViewProvider);
    final actions = ref.read(syncActionsProvider.notifier);
    final last = view.lastSuccessMs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        FbListRow(
          key: const ValueKey('sync-sheet-status'),
          title: syncStatusText(l10n, view),
          subtitle: last == null
              ? l10n.syncNeverSynced
              : l10n.syncLastSync(
                  instantText(context, last, nowMs: view.nowMs),
                ),
        ),
        if (view.parked > 0)
          FbInlineBanner(
            key: const ValueKey('sync-sheet-parked'),
            kind: FbInlineBannerKind.error,
            message: l10n.syncParkedBanner(view.parked),
            actionBelow: true,
            actionLabel: l10n.syncTryAgain,
            onAction: () => unawaited(actions.retryParked()),
          ),
        FbButton.primary(
          key: const ValueKey('sync-now'),
          label: view.running ? l10n.syncStatusSyncing : l10n.syncNow,
          busy: view.running,
          expand: true,
          onPressed: view.running ? null : () => unawaited(actions.syncNow()),
        ),
      ],
    );
  }
}

/// Opens the sync sheet.
Future<void> showSyncSheet(BuildContext context) => showFbSheet<void>(
  context,
  title: context.l10n.syncRowTitle,
  builder: (_) => const SyncSheetBody(),
);

/// Me › Account: the "Sync" row with a one-line status; opens the sheet.
class SyncAccountRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(syncViewProvider);
    return FbListRow(
      key: const ValueKey('account-sync-row'),
      leading: const Icon(FbIcons.sync),
      title: l10n.syncRowTitle,
      subtitle: syncStatusText(l10n, view),
      trailing: const Icon(FbIcons.next),
      onTap: () => unawaited(showSyncSheet(context)),
    );
  }
}

/// Today's sync line (AC-013, UX-053): only when something hasn't synced
/// for a while, a problem, parked changes or a first restore; nothing
/// otherwise. Starts watching after its first frame (UX-001: no database
/// read during the first frame).
class SyncTodayLine extends ConsumerStatefulWidget {
  /// Creates the line.
  const new({super.key});

  @override
  ConsumerState<SyncTodayLine> createState() => _SyncTodayLineState();
}

class _SyncTodayLineState extends ConsumerState<SyncTodayLine> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final view = ref.watch(syncViewProvider);
    if (!view.showOnToday) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      key: const ValueKey('today-sync-line'),
      padding: const EdgeInsetsDirectional.only(top: FbSpace.s3),
      child: FbInlineBanner(
        kind: switch (view.problem) {
          SyncProblem.offline => FbInlineBannerKind.offline,
          SyncProblem.clockAhead ||
          SyncProblem.clockBehind ||
          SyncProblem.updateRequired ||
          SyncProblem.error => FbInlineBannerKind.error,
          _ =>
            view.restoring
                ? FbInlineBannerKind.info
                : FbInlineBannerKind.pending,
        },
        message: syncStatusText(l10n, view),
        actionLabel: l10n.syncDetails,
        onAction: () => unawaited(showSyncSheet(context)),
      ),
    );
  }
}
