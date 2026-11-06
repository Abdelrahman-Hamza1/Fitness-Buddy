import 'dart:convert';
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../../tool/generate_diary_estimate_vectors.dart';

File _repoFile(String path) {
  final local = File(path);
  return local.existsSync() ? local : File('../../$path');
}

const _path = 'contracts/testdata/sync/diary-estimate-validation-vectors.json';

void main() {
  final corpus =
      jsonDecode(_repoFile(_path).readAsStringSync()) as Map<String, Object?>;
  final payloads = (corpus['payloads']! as List<Object?>)
      .cast<Map<String, Object?>>();

  test('DY-005 generated estimate vectors match committed bytes', () {
    expect(
      _repoFile(_path).readAsBytesSync(),
      utf8.encode(generateDiaryEstimateVectors()),
    );
  });

  test(
    'DY-005 DiaryEstimateWireRules match the shared vectors; every rule has a '
    'rejected case per entity',
    () {
      final rejectedByRule = <String>{};
      for (final p in payloads) {
        final id = p['id'];
        final entity = p['entity']! as String;
        final version = p['schemaVersion']! as int;
        final payload =
            jsonDecode(p['rawPayload']! as String) as Map<String, Object?>;
        final wire = DiaryEstimateWireRules.holds(entity, version, payload);
        expect(p['appWire'], wire, reason: '$id appWire');
        final tag = p['asymmetry'] as String?;
        if (tag == null) {
          expect(p['serverAccepts'], wire, reason: '$id');
        } else {
          expect(diaryEstimateAsymmetries, contains(tag), reason: '$id');
          expect((p['serverAccepts'], wire), (false, true), reason: '$id');
        }
        if (p['rule'] case final String rule) {
          expect(p['serverAccepts'], isFalse, reason: '$id');
          expect(
            DiaryEstimateWireRules.violation(entity, version, payload)?.readme,
            rule,
            reason: '$id',
          );
          rejectedByRule.add('$entity $rule');
        }
      }
      for (final entity in DiaryEstimateWireRules.entities) {
        for (final rule in DiaryEstimateWireRule.values) {
          expect(rejectedByRule, contains('$entity ${rule.readme}'));
        }
        expect(
          payloads.where(
            (p) =>
                p['entity'] == entity &&
                p['schemaVersion'] == 2 &&
                p['serverAccepts'] == true,
          ),
          isNotEmpty,
        );
      }
    },
  );

  test('DY-005 the rules fail closed for an unknown entity or version', () {
    expect(
      () => DiaryEstimateWireRules.violation('diaryEntry', 3, const {}),
      throwsArgumentError,
    );
    expect(
      () => DiaryEstimateWireRules.violation('weighIn', 2, const {}),
      throwsArgumentError,
    );
    expect(DiaryEstimateWireRules.holds('savedMealItem', 1, const {}), isTrue);
  });
}
