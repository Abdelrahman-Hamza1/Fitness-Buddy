import 'package:fb_domain/fb_domain.dart' show isUuid;
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('natural ids (A01 D6)', () {
    test('uuidV5 matches the RFC 9562 test vector', () {
      // RFC 9562 A.4: the DNS namespace and "www.example.com".
      expect(
        uuidV5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'www.example.com'),
        '2ed6657d-e927-568b-95e1-2665a8aea6a2',
      );
    });

    test('naturalId is deterministic, lowercase canonical, version 5', () {
      final id = naturalId('setting', 'units.system');
      expect(id, naturalId('setting', 'units.system'));
      expect(isUuid(id), isTrue);
      expect(id[14], '5');
      expect('89ab', contains(id[19]));
      expect(id, isNot(naturalId('setting', 'units.energy')));
      expect(id, isNot(naturalId('mealSlot', 'units.system')));
    });

    test('the namespace never changes: known ids stay the same', () {
      // Changing fbNamespace would fork every natural row across devices.
      expect(fbNamespace, '02ebdada-9a63-4b03-a1b0-da5747aabf36');
      expect(
        naturalId('setting', 'units.system'),
        uuidV5(fbNamespace, 'setting:units.system'),
      );
      expect(naturalId('setting', 'units.system'), _pinnedUnitsSystemId);
    });

    test('entity wire names are camelCase and at most 64 characters', () {
      expect(checkEntityWireName('mealSlot'), 'mealSlot');
      for (final bad in ['MealSlot', 'meal_slot', 'meal-slot', '', 'a' * 65]) {
        expect(() => naturalId(bad, 'k'), throwsArgumentError, reason: bad);
      }
      expect(checkEntityWireName('a' * 64), hasLength(64));
      expect(() => naturalId('setting', ''), throwsArgumentError);
    });
  });
}

// Computed independently (Python's uuid.uuid5); a change means the namespace
// or the algorithm changed.
const _pinnedUnitsSystemId = '02f4e5ec-656b-5dc5-9f2c-7a26eab56774';
