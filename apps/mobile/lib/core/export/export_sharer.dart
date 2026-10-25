import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Result of handing files to the platform share sheet.
enum ExportShareResult {
  /// OS accepted the share handoff.
  shared,

  /// User cancelled the share sheet.
  dismissed,
}

/// Platform boundary, replaceable without platform channels in tests.
abstract interface class ExportSharer {
  /// Opens the OS sheet for all completed files.
  Future<ExportShareResult> share(List<File> files);
}

/// The only share_plus importer; no network or permissions are needed.
final class SharePlusExportSharer implements ExportSharer {
  @override
  /// Opens the OS sheet for all completed files.
  Future<ExportShareResult> share(List<File> files) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          for (final file in files)
            XFile(
              file.path,
              mimeType: file.path.endsWith('.csv')
                  ? 'text/csv'
                  : 'application/json',
            ),
        ],
      ),
    );
    // Android may report unavailable after launching a target; that still
    // means the OS accepted the handoff, not an export failure.
    return result.status == ShareResultStatus.dismissed
        ? ExportShareResult.dismissed
        : ExportShareResult.shared;
  }
}
