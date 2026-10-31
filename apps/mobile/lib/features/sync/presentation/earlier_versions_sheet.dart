import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
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
      loading: () => const Padding(
        padding: EdgeInsetsDirectional.all(FbSpace.s4),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => FbListRow(
        title: switch (error) {
          EarlierVersionsFailure.offline => l10n.syncEarlierVersionsOffline,
          EarlierVersionsFailure.signedOut => l10n.syncEarlierVersionsSignedOut,
          _ => l10n.syncEarlierVersionsFailed,
        },
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
