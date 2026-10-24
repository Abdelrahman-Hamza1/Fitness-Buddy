import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/generate_personal_food_vectors.dart';

void main() {
  test('A09.3.0 B17 generated vectors match committed bytes', () {
    final file = File(
      'contracts/testdata/sync/personal-food-validation-vectors.json',
    );
    final source = file.existsSync()
        ? file
        : File(
            '../../contracts/testdata/sync/personal-food-validation-vectors.json',
          );
    expect(
      source.readAsBytesSync(),
      utf8.encode(generatePersonalFoodVectors()),
    );
  });
}
