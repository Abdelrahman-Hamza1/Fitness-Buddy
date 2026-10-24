import 'package:fb_mobile/core/export/export_providers.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/features/settings/application/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_export.g.dart';

/// Presentation consumes typed states and supplies its own localized copy.
sealed class DataExportState {
  /// Base controller state.
  const new();
}

/// No export has started.
final class ExportIdle extends DataExportState {
  /// Initial state.
  const new();
}

/// Snapshot, encoding or share sheet is active.
final class ExportWorking extends DataExportState {
  /// Disables repeated export intents.
  const new();
}

/// Export reached a typed share outcome.
final class ExportDone extends DataExportState {
  /// Carries completion, including OS dismissal.
  const new(this.outcome);

  /// Safe result for presentation.
  final ExportOutcome outcome;
}

/// Export failed and can be retried.
final class ExportFailed extends DataExportState {
  /// Carries only the failing stage.
  const new(this.kind);

  /// Category for localized failure presentation.
  final ExportFailureKind kind;
}

/// One export at a time, with the settings feature's complete key vocabulary.
@riverpod
class DataExportController extends _$DataExportController {
  @override
  DataExportState build() => const ExportIdle();

  /// Ignores repeated taps until the active attempt completes.
  Future<void> export() async {
    if (state is ExportWorking) return;
    state = const ExportWorking();
    final outcome = await ref
        .read(dataExportServiceProvider)
        .export(settingNames: AppSettings.all.map((key) => key.name));
    if (!ref.mounted) return;
    state = switch (outcome) {
      Failed(:final kind) => ExportFailed(kind),
      _ => ExportDone(outcome),
    };
  }
}
