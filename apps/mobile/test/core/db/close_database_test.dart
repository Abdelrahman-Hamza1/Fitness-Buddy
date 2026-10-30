import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/db_support.dart';

void main() {
  test('AC-004 every caller shares one close future per database', () async {
    final db = memoryDatabase();
    await db.customSelect('SELECT 1').get();
    final first = closeDatabase(db);
    final second = closeDatabase(db);
    expect(identical(first, second), isTrue);
    await second;
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
  });
}
