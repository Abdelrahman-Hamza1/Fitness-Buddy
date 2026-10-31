import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Runtime dependencies this package may declare (pubspec comment).
const _allowedDependencies = {'dio', 'fb_api_client', 'fb_domain'};

/// Imports that would tie a pure Dart package to Flutter or to I/O.
final _forbiddenImports = RegExp(
  r'''^\s*(?:import|export)\s+['"](dart:(?:io|ui|ffi|isolate|html)|package:flutter/)''',
);

void main() {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;

  group('fb_sync stays pure Dart:', () {
    test('no dependency on the Flutter SDK', () {
      for (final section in ['dependencies', 'dev_dependencies']) {
        final deps = (pubspec[section] as YamlMap?) ?? YamlMap();
        for (final MapEntry(:key, :value) in deps.entries) {
          final onFlutterSdk = value is YamlMap && value['sdk'] == 'flutter';
          expect(
            onFlutterSdk,
            isFalse,
            reason: '$key depends on the Flutter SDK in $section',
          );
        }
      }
    });

    test('runtime dependencies are within the allowlist', () {
      final deps = (pubspec['dependencies'] as YamlMap?) ?? YamlMap();
      expect(
        deps.keys.cast<String>().toSet().difference(_allowedDependencies),
        isEmpty,
        reason: 'Add a dependency to the allowlist only on purpose.',
      );
    });

    test('lib/ imports no Flutter or I/O library', () {
      final violations = <String>[
        for (final file in Directory('lib').listSync(recursive: true))
          if (file is File && file.path.endsWith('.dart'))
            for (final (index, line) in file.readAsLinesSync().indexed)
              if (_forbiddenImports.hasMatch(line))
                '${file.path}:${index + 1}: ${line.trim()}',
      ];
      expect(violations, isEmpty);
    });
  });
}
