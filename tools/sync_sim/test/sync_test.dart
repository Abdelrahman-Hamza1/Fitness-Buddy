import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

// The engine, its convergence runs and faults are tested in packages/fb_sync
// (fake server) and run against the real API by bin/sync_sim.dart.
void main() {
  test('shared TD-049 vectors parse and compare as bytes', () {
    final yaml = loadYaml(
      File('../../contracts/testdata/sync/hlc_cases.yaml').readAsStringSync(),
    ) as YamlMap;
    final valid = (yaml['valid'] as YamlList).cast<String>();
    for (final text in valid) {
      expect(Hlc.parse(text).toString(), text);
    }
    for (final text in (yaml['invalid'] as YamlList).cast<String>()) {
      expect(Hlc.tryParse(text.replaceAll(r'\n', '\n')), isNull);
    }
    for (var i = 1; i < valid.length; i++) {
      expect(
        Hlc.parse(valid[i - 1]).compareTo(Hlc.parse(valid[i])),
        lessThan(0),
      );
      expect(valid[i - 1].compareTo(valid[i]), lessThan(0));
    }
  });
}
