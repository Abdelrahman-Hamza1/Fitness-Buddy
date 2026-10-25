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

/// Pinned status and actions. Disposal cancels preparation before sharing.
class ExportSheetActions extends ConsumerWidget {
  /// Creates the footer.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(dataExportControllerProvider);
    final controller = ref.read(dataExportControllerProvider.notifier);
    void export() => unawaited(controller.export());
    void close() => Navigator.of(context).pop();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: [
        ?switch (state) {
          ExportIdle() => null,
          ExportWorking() => FbInlineBanner(
            kind: FbInlineBannerKind.pending,
            message: l10n.exportWorking,
          ),
          ExportDone(:final outcome) => FbInlineBanner(
            kind: FbInlineBannerKind.info,
            message: switch (outcome) {
              Shared(:final fileCount, :final rowCount) => l10n.exportDone(
                rowCount,
                fileCount,
              ),
              _ => l10n.exportDismissed,
            },
          ),
          ExportFailed() => FbInlineBanner(
            kind: FbInlineBannerKind.error,
            message: l10n.exportFailed,
            actionBelow: true,
            actionLabel: l10n.exportTryAgain,
            onAction: export,
          ),
        },
        if (state is! ExportFailed)
          switch (state) {
            ExportDone(outcome: Shared()) => FbButton.primary(
              label: l10n.exportDoneButton,
              onPressed: close,
              expand: true,
            ),
            ExportDone() => FbButton.primary(
              label: l10n.exportExportAgain,
              onPressed: export,
              expand: true,
            ),
            _ => FbButton.primary(
              label: l10n.exportAction,
              onPressed: state is ExportWorking ? null : export,
              expand: true,
            ),
          },
        if (state is ExportDone)
          FbButton.text(
            label: state.outcome is Shared
                ? l10n.exportExportAgain
                : l10n.exportClose,
            onPressed: state.outcome is Shared ? export : close,
            expand: true,
          ),
      ],
    );
  }
}
