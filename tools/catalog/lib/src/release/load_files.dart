import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fb_catalog/src/release/release.dart';
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

/// The text of one load file: one JSON object per line, keys in a fixed
/// order, so equal data gives equal bytes.
String encodeLoadFile(List<Row> rows) =>
    rows.isEmpty ? '' : '${rows.map(jsonEncode).join('\n')}\n';

/// sha256 hex of [bytes].
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// The content hash of a release (A05 D3): sha256 over the load files in
/// their fixed order, each preceded by its name.
String contentHash(Release release) {
  final all = BytesBuilder(copy: false);
  for (final name in loadFileNames) {
    all
      ..add(utf8.encode('$name\u0000'))
      ..add(utf8.encode(encodeLoadFile(release.table(name))));
  }
  return sha256Hex(all.takeBytes());
}

/// What `writeLoadFiles` wrote for one file.
class LoadFileInfo {
  const new(this.name, this.sha256, this.count, this.bytes);

  final String name;
  final String sha256;
  final int count;
  final int bytes;
}

/// Writes `<dir>/<name>.jsonl` for every load file and returns the facts the
/// manifest needs.
List<LoadFileInfo> writeLoadFiles(Release release, Directory dir) {
  dir.createSync(recursive: true);
  final infos = <LoadFileInfo>[];
  for (final name in loadFileNames) {
    final text = encodeLoadFile(release.table(name));
    final bytes = utf8.encode(text);
    File(p.join(dir.path, '$name.jsonl')).writeAsBytesSync(bytes);
    infos.add(
      LoadFileInfo(name, sha256Hex(bytes), release.count(name), bytes.length),
    );
  }
  return infos;
}

/// Checks every line of every load file against the schemas in
/// [contractDir] (`<name>.schema.json`). Returns the problems.
List<String> validateLoadFiles(Release release, String contractDir) {
  final problems = <String>[];
  for (final name in loadFileNames) {
    final file = File(p.join(contractDir, '$name.schema.json'));
    if (!file.existsSync()) {
      problems.add('missing contract schema ${file.path}');
      continue;
    }
    final schema = JsonSchema.create(
      jsonDecode(file.readAsStringSync()) as Object,
    );
    var line = 0;
    for (final row in release.table(name)) {
      line++;
      // Round trip through JSON so the schema sees exactly what is written.
      final result = schema.validate(jsonDecode(jsonEncode(row)));
      if (!result.isValid) {
        problems.add(
          '$name.jsonl:$line: ${result.errors.first.instancePath} '
          '${result.errors.first.message}',
        );
        break;
      }
    }
  }
  return problems;
}

/// Validates the manifest against `manifest.schema.json`.
List<String> validateManifest(Map<String, Object?> manifest, String dir) {
  final schema = JsonSchema.create(
    jsonDecode(File(p.join(dir, 'manifest.schema.json')).readAsStringSync())
        as Object,
  );
  final result = schema.validate(jsonDecode(jsonEncode(manifest)));
  return [
    for (final e in result.errors)
      'manifest.json: ${e.instancePath} ${e.message}',
  ];
}
