import 'dart:io';

import 'package:fb_catalog/src/load/schema.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:yaml/yaml.dart';

/// `data/catalog_release.yaml`: the current `catalog_version` and the content
/// hash it was made for (A05 D3).
class ReleaseState {
  const new(this.version, this.contentSha256);

  /// Before the first `make catalog`.
  const new none() : version = 0, contentSha256 = '';

  factory read(File file) {
    if (!file.existsSync()) return const ReleaseState.none();
    final doc = loadYaml(file.readAsStringSync());
    if (doc is! YamlMap ||
        doc['catalog_version'] is! int ||
        doc['content_sha256'] is! String) {
      throw FormatException(
        '${file.path}: expected catalog_version (int) and content_sha256',
      );
    }
    return ReleaseState(
      doc['catalog_version'] as int,
      doc['content_sha256'] as String,
    );
  }

  final int version;
  final String contentSha256;

  String format() =>
      '''
# Catalog release state (A05 D3). Written by `make catalog`, never by hand:
# the version goes up when the content hash of the load files changes.
catalog_version: $version
content_sha256: $contentSha256
''';
}

/// Reads `data/attribution.yaml` (schema-checked) into plain JSON data for
/// `meta.attribution`; an absent file gives an empty list.
List<Object?> loadAttribution(
  File file,
  String schemaDir,
  List<CatalogIssue> issues,
) {
  if (!file.existsSync()) return const [];
  final plain = readChecked(
    file,
    loadSchema(schemaDir, attributionSchemaFile),
    issues,
  );
  if (plain == null) return const [];
  return List<Object?>.from((plain as Map<String, dynamic>)['sources'] as List);
}
