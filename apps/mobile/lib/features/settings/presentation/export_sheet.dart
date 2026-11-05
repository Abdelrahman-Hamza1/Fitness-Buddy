import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/application/data_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the export sheet (AC-030, A11 D9) on the root navigator.
Future<void> showExportSheet(BuildContext context) => showFbSheet<void>(
  context,
  title: context.l10n.meExportData,
  builder: (context) => const ExportSheetBody(),
  actionsBuilder: (context) => const ExportSheetActions(),
);

/// Muted explanation scrolls independently of the export actions.
class ExportSheetBody extends ConsumerWidget {
  /// Creates the explanatory content.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(dataExportControllerProvider.notifier).abandon();
      },
      child: Text(
        '${l10n.exportWhat} ${l10n.exportLiveOnly} ${l10n.exportPrivacy}',
        style: FbType.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Pinned status and actions (A57 A12, UX-045): one status region that
/// changes with a smooth resize, then always the same two action slots, a
/// primary and a secondary button, so no button jumps when the state
/// changes. Disposal cancels preparation before sharing.
class ExportSheetActions extends ConsumerWidget {
  /// Creates the footer.
  const new({super.key});

  /// The primary action's key.
  static const Key primaryKey = ValueKey('export-primary');

  /// The secondary action's key.
  static const Key secondaryKey = ValueKey('export-secondary');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(dataExportControllerProvider);
    final controller = ref.read(dataExportControllerProvider.notifier);
    void export() => unawaited(controller.export());
    void close() => Navigator.of(context).pop();
    final status = switch (state) {
      ExportIdle() => null,
      ExportWorking() => FbInlineBanner(
        key: const ValueKey('export-working'),
        kind: FbInlineBannerKind.pending,
        message: l10n.exportWorking,
      ),
      ExportDone(:final outcome) => FbInlineBanner(
        key: ValueKey('export-done-${outcome.runtimeType}'),
        kind: FbInlineBannerKind.info,
        message: switch (outcome) {
          Shared(:final fileCount, :final rowCount) => l10n.exportDone(
            rowCount,
            fileCount,
          ),
          _ => l10n.exportDismissed,
        },
      ),
      ExportFailed(:final kind) => FbInlineBanner(
        key: ValueKey('export-failed-${kind.name}'),
        kind: FbInlineBannerKind.error,
        // The stage that failed, in plain words (#129).
        message: switch (kind) {
          ExportFailureKind.storage => l10n.exportFailedStorage,
          ExportFailureKind.sharing => l10n.exportFailedSharing,
          ExportFailureKind.snapshot ||
          ExportFailureKind.encoding => l10n.exportFailed,
        },
      ),
    };
    final shared = state is ExportDone && state.outcome is Shared;
    final (primaryLabel, primaryAction) = switch (state) {
      ExportDone(outcome: Shared()) => (l10n.exportDoneButton, close),
      ExportDone() => (l10n.exportExportAgain, export),
      ExportFailed() => (l10n.exportTryAgain, export),
      ExportWorking() => (l10n.exportAction, null),
      ExportIdle() => (l10n.exportAction, export),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        FbSizeFade(
          child:
              status ??
              const SizedBox(
                key: ValueKey('export-idle'),
                width: double.infinity,
              ),
        ),
        FbButton.primary(
          key: primaryKey,
          label: primaryLabel,
          onPressed: primaryAction,
          expand: true,
        ),
        FbButton.text(
          key: secondaryKey,
          label: shared ? l10n.exportExportAgain : l10n.exportClose,
          onPressed: shared ? export : close,
          expand: true,
        ),
      ],
    );
  }
}
