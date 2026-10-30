import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Runtime dependencies this package may declare: the generated code's runtime
/// (dio + retrofit for the clients, freezed/json annotations for the models).
const _allowedDependencies = {
  'dio',
  'retrofit',
  'freezed_annotation',
  'json_annotation',
};

/// Packages that move together with the generator (S02 D1): pinned to an exact
/// version, because a bump needs a `make gen` regeneration commit.
const _exactlyPinned = <String>{
  ..._allowedDependencies,
  'swagger_parser',
  'build_runner',
  'freezed',
  'json_serializable',
  'retrofit_generator',
};

void main() {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  YamlMap section(String name) => (pubspec[name] as YamlMap?) ?? YamlMap();

  group('fb_api_client stays pure Dart:', () {
    test('runtime dependencies are within the allowlist', () {
      expect(
        section('dependencies').keys
            .cast<String>()
            .toSet()
            .difference(_allowedDependencies),
        isEmpty,
        reason: 'Add a dependency to the allowlist only on purpose.',
      );
    });

    test('generator packages are pinned to an exact version', () {
      final all = {...section('dependencies'), ...section('dev_dependencies')};
      for (final name in _exactlyPinned) {
        expect(
          all[name],
          matches(RegExp(r'^\d+\.\d+\.\d+$')),
          reason: '$name must be pinned exactly (S02 D1)',
        );
      }
    });
  });
}
