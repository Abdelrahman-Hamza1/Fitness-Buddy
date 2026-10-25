import 'dart:convert';
import 'dart:typed_data';

import 'package:fb_mobile/core/export/csv_codec.dart';
import 'package:fb_mobile/core/export/export_registry.dart';
import 'package:fb_mobile/core/export/export_snapshot.dart';

/// One file ready to persist in app-private temporary storage.
final class ExportFile {
  /// Names the completed file and its OS sharing MIME type.
  const new(this.name, this.mime, this.bytes);

  /// Generated basename, without directory components.
  final String name;

  /// MIME type for the platform share target.
  final String mime;

  /// Fully encoded UTF-8 file bytes.
  final Uint8List bytes;
}

/// Pure v1 encoder, invoked in an isolate by the service.
abstract final class ExportBuilder {
  /// Encodes v1 without I/O, database handles or platform calls.
  static List<ExportFile> build(
    ExportSnapshot snapshot, {
    required DateTime exportedAt,
    required String version,
    required String build,
  }) {
    final date = exportedAt.toIso8601String().substring(0, 10);
    final prefix = 'fitness-buddy-$date';
    final data = <String, List<Map<String, Object?>>>{};
    final files = <ExportFile>[];
    for (final spec in exportRegistryV1) {
      final rows = snapshot.rows[spec.entity]!;
      final csvColumns = spec.columns
          .where((c) => c.name != 'version' && c.name != 'origin')
          .toList();
      Object? value(
        Map<String, Object?> row,
        ExportColumn column, {
        bool json = false,
      }) {
        final raw = row[column.name];
        if (column.name == 'occurred_at') {
          final offset = row['tz_offset_min']! as int;
          final local = DateTime.fromMillisecondsSinceEpoch(
            (row['occurred_at_utc']! as int) + offset * 60000,
            isUtc: true,
          ).toIso8601String().replaceFirst('Z', '');
          final h = (offset.abs() ~/ 60).toString().padLeft(2, '0');
          final m = (offset.abs() % 60).toString().padLeft(2, '0');
          return '$local${offset < 0 ? '-' : '+'}$h:$m';
        }
        if (raw == null) return null;
        if (column.kind == ExportKind.boolean) return raw == true || raw == 1;
        if (column.name == 'created_at') {
          return DateTime.fromMillisecondsSinceEpoch(
            raw as int,
            isUtc: true,
          ).toIso8601String();
        }
        if (json && column.kind == ExportKind.json) {
          // Never propagate FormatException.source (it contains user data).
          try {
            return jsonDecode(raw as String);
          } on FormatException {
            throw const ExportEncodingException();
          }
        }
        return raw;
      }

      files.add(
        ExportFile(
          '$prefix-${spec.fileStem}.csv',
          'text/csv',
          encodeCsv(
            csvColumns.map((c) => c.name).toList(),
            rows.map((row) => csvColumns.map((c) => value(row, c)).toList()),
          ),
        ),
      );
      data[spec.entity] = [
        for (final row in rows)
          {for (final c in spec.columns) c.name: value(row, c, json: true)},
      ];
    }
    files.add(
      ExportFile(
        '$prefix.json',
        'application/json',
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'format': 'fitness-buddy-export',
              'formatVersion': 1,
              'exportedAt': exportedAt.toUtc().toIso8601String(),
              'app': {'version': version, 'build': build},
              'schemaVersion': snapshot.schemaVersion,
              'counts': {for (final e in data.entries) e.key: e.value.length},
              'data': data,
            }),
          ),
        ),
      ),
    );
    return files;
  }
}

/// Content-free failure for malformed stored JSON.
final class ExportEncodingException implements Exception {
  /// Omits the malformed JSON source from the failure.
  const new();
}
