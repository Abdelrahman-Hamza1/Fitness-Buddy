import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_snack_bar.dart';
import 'package:fb_mobile/features/sync/application/sync_view.dart';
import 'package:fb_mobile/features/sync/presentation/sync_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Describes a version's payload for the list (the item's own words, e.g.
/// a diary entry's name and energy); `null` shows only the time.
typedef VersionSummary = String? Function(
  BuildContext context,
  Map<String, Object?> payload,
);

/// The earlier versions of one item (G7, A34 D14), newest first, each with
/// "Restore" (a direct action with Undo). Online only: offline and
/// signed-out states say so calmly.
class EarlierVersionsBody extends ConsumerWidget {
  /// Creates the list for row [id] of [entity].
  const new({required this.entity, required this.id, this.summary, super.key});

  /// The entity wire name.
  final String entity;

  /// The row id.
  final String id;

  /// The item's words for a version.
  final VersionSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final versions = ref.watch(earlierVersionsProvider(entity, id));
    final nowMs = ref.watch(syncViewProvider.select((v) => v.nowMs));
    return versions.when(
      // Rows shaped like versions, and every failure with its way out
      // (A57 A49): Sign in when signed out, Try again otherwise.
      loading: () => Column(
        key: const ValueKey('versions-loading'),
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < 3; i++) FbSkeleton.row()],
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2),
        child: error == EarlierVersionsFailure.signedOut
            ? FbInlineBanner(
                key: const ValueKey('versions-signed-out'),
                kind: FbInlineBannerKind.info,
                message: l10n.syncEarlierVersionsSignedOut,
                actionLabel: l10n.meSignIn,
                onAction: () {
                  Navigator.of(context).pop();
                  ref.read(appNavigatorProvider).push(const SignInRoute());
                },
              )
            : FbInlineBanner(
                key: const ValueKey('versions-failed'),
                kind: error == EarlierVersionsFailure.offline
                    ? FbInlineBannerKind.info
                    : FbInlineBannerKind.error,
                message: error == EarlierVersionsFailure.offline
                    ? l10n.syncEarlierVersionsOffline
                    : l10n.syncEarlierVersionsFailed,
                actionLabel: l10n.commonTryAgain,
                onAction: () =>
                    ref.invalidate(earlierVersionsProvider(entity, id)),
              ),
      ),
      data: (list) => list.isEmpty
          ? FbListRow(title: l10n.syncEarlierVersionsEmpty)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final version in list)
                  FbListRow(
                    title:
                        summary?.call(context, version.payload) ??
                        _when(context, version, nowMs),
                    subtitle: summary == null
                        ? null
                        : _when(context, version, nowMs),
                    trailing: FbButton.text(
                      key: ValueKey('version-restore-${version.hlc}'),
                      label: l10n.syncRestore,
                      onPressed: () =>
                          unawaited(_restore(context, ref, version)),
                    ),
                  ),
              ],
            ),
    );
  }

  String _when(BuildContext context, EarlierVersion version, int nowMs) {
    final time = instantText(context, version.wallMs, nowMs: nowMs);
    return version.deleted
        ? context.l10n.syncVersionDeleted(time)
        : context.l10n.syncVersionSaved(time);
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    EarlierVersion version,
  ) async {
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    final outcome = await ref
        .read(syncActionsProvider.notifier)
        .restore(entity, id, version);
    if (!context.mounted) return;
    switch (outcome) {
      case RestoreDone(:final undoEntryId):
        showUndoFeedback(
          context,
          message: l10n.syncRestored,
          undoEntryId: undoEntryId,
        );
        navigator.pop();
      case RestoreRefused():
        showFbSnackBar(context, l10n.syncRestoreRefused);
    }
  }
}

/// Opens the earlier versions of row [id] of [entity].
Future<void> showEarlierVersionsSheet(
  BuildContext context, {
  required String entity,
  required String id,
  VersionSummary? summary,
}) => showFbSheet<void>(
  context,
  title: context.l10n.syncEarlierVersions,
  builder: (_) => EarlierVersionsBody(entity: entity, id: id, summary: summary),
);

/// "Earlier versions" for one item in its editor's actions (G7, #236):
/// shown only while sync is on (an account), else nothing. [enabled] false
/// keeps it visible but off (a write in flight).
class EarlierVersionsButton extends ConsumerWidget {
  /// Creates the button for row [id] of [entity].
  const new({
    required this.entity,
    required this.id,
    this.summary,
    this.enabled = true,
    super.key,
  });

  /// The entity wire name.
  final String entity;

  /// The row id.
  final String id;

  /// The item's words for a version.
  final VersionSummary? summary;

  /// Whether it can be tapped now.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(syncViewProvider.select((v) => v.enabled))) {
      return const SizedBox.shrink();
    }
    return FbButton.text(
      label: context.l10n.syncEarlierVersions,
      icon: FbIcons.pending,
      expand: true,
      onPressed: enabled
          ? () => unawaited(
              showEarlierVersionsSheet(
                context,
                entity: entity,
                id: id,
                summary: summary,
              ),
            )
          : null,
    );
  }
}
