import 'package:yaml/yaml.dart';

/// A YAML node as plain Dart (maps with string keys, lists, scalars), so it
/// can be checked by a JSON Schema and cast safely afterwards.
Object? yamlToPlain(Object? node) => switch (node) {
  YamlMap() => {
    for (final e in node.nodes.entries)
      '${(e.key as YamlNode).value}': yamlToPlain(e.value),
  },
  YamlList() => [for (final e in node.nodes) yamlToPlain(e)],
  YamlScalar() => node.value,
  _ => node,
};
