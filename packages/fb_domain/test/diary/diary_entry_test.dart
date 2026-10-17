import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

void main() {
  group('FoodNames:', () {
    test('names are not blank, Arabic is optional, text is hidden', () {
      expect(() => FoodNames(' '), throwsArgumentError);
      expect(() => FoodNames('Rice', ar: ''), throwsArgumentError);
      final names = FoodNames('Maqluba', ar: 'مقلوبة');
      expect(names.en, 'Maqluba');
      expect(names.ar, 'مقلوبة');
      expect(FoodNames('Rice').ar, isNull);
      expect(names, FoodNames('Maqluba', ar: 'مقلوبة'));
      expect(names.hashCode, FoodNames('Maqluba', ar: 'مقلوبة').hashCode);
      expect(names, isNot(FoodNames('Maqluba')));
      expect('$names', 'FoodNames(en, ar)');
      expect('${FoodNames('Rice')}', 'FoodNames(en)');
    });

    test('a blank-name error does not include the text', () {
      expect(
        () => FoodNames('Rice', ar: '   '),
        throwsA(
          isA<ArgumentError>().having(
            (e) => '$e',
            'text',
            isNot(contains('   ')),
          ),
        ),
      );
    });
  });

  group('EntryFood and EntryAmount:', () {
    test('NewDiaryEntry rejects a negative or non-finite amount', () {
      for (final bad in [-0.01, double.nan, double.infinity]) {
        expect(
          () => EntryAmount(
            input: Quantity(1, 'piece'),
            amount: bad,
            basis: NutrientBasis.per100g,
          ),
          throwsArgumentError,
          reason: '$bad',
        );
      }
      expect(grams(0).amount, 0);
    });

    test('value equality; text shows no names or values', () {
      expect(riceFood(), riceFood());
      expect(riceFood().hashCode, riceFood().hashCode);
      expect(riceFood(), isNot(riceFood(id: 'usda:1')));
      final other = EntryFood(
        ref: riceFood().ref,
        names: FoodNames('Rice'),
        per100: rice100,
        provenance: Provenance(source: FoodSource.database),
      );
      expect(riceFood(), isNot(other));
      final text = '${riceFood()}';
      expect(
        text,
        'EntryFood(FoodRef(catalog, usda:169704, 2026.10.1), '
        'database)',
      );
      expect(text, isNot(contains('Rice')));

      expect(grams(150), grams(150));
      expect(grams(150).hashCode, grams(150).hashCode);
      expect(grams(150), isNot(grams(151)));
      final ml = EntryAmount(
        input: Quantity(1, 'cup'),
        amount: 240,
        basis: NutrientBasis.per100ml,
      );
      expect(
        ml,
        isNot(
          EntryAmount(
            input: Quantity(240, 'ml'),
            amount: 240,
            basis: NutrientBasis.per100ml,
          ),
        ),
      );
      expect('$ml', 'EntryAmount(ml)');
    });
  });

  group('DiaryEntry:', () {
    test('IDs must be UUIDs and the version ≥ 1', () {
      expect(() => entry(id: 'x'), throwsArgumentError);
      expect(() => entry(slotId: 'lunch'), throwsArgumentError);
      expect(() => entry(dishGroupId: 'g'), throwsArgumentError);
      expect(() => entry(version: 0), throwsArgumentError);
      expect(entry(dishGroupId: groupG).dishGroupId, groupG);
      expect(entry().editedByUser, isFalse);
    });

    test('DY-002 the stored time and local date are kept as stored', () {
      final e = entry();
      expect(e.localDate, LocalDate(2026, 10, 13));
      expect(e.time.localDateTime.time, LocalTime(13));
    });

    test('equality covers every field; text has IDs only', () {
      expect(entry(), entry());
      expect(entry().hashCode, entry().hashCode);
      expect(entry(), isNot(entry(version: 2)));
      expect(entry(), isNot(entry(id: entryB)));
      expect(entry(), isNot(entry(slotId: DefaultSlots.dinnerId)));
      expect(entry(), isNot(entry(dishGroupId: groupG)));
      expect(entry(), isNot(entry(snapshot: snapshotOf(1))));
      final base = entry();
      DiaryEntry copy({
        EntryTime? time,
        LocalDate? localDate,
        EntryFood? food,
        EntryAmount? amount,
        bool editedByUser = false,
      }) => DiaryEntry(
        id: base.id,
        version: base.version,
        time: time ?? base.time,
        localDate: localDate ?? base.localDate,
        slotId: base.slotId,
        food: food ?? base.food,
        amount: amount ?? base.amount,
        snapshot: base.snapshot,
        editedByUser: editedByUser,
      );
      expect(copy(), base);
      expect(copy(time: EntryTime(DateTime.utc(2026), 0)), isNot(base));
      expect(copy(localDate: LocalDate(2026, 10, 14)), isNot(base));
      expect(copy(food: riceFood(id: 'other')), isNot(base));
      expect(copy(amount: grams(1)), isNot(base));
      expect(copy(editedByUser: true), isNot(base));
      expect(
        '${entry(dishGroupId: groupG)}',
        'DiaryEntry($entryA, v1, 2026-10-13, slot ${DefaultSlots.lunchId}, '
            'group $groupG)',
      );
      expect('$base', isNot(contains('Rice')));
      expect('$base', isNot(contains('195')));
    });
  });

  group('DishGroup and DayMark:', () {
    DishGroup group({String name = 'Maqluba', int version = 1}) => DishGroup(
      id: groupG,
      version: version,
      name: name,
      localDate: LocalDate(2026, 10, 13),
      slotId: DefaultSlots.lunchId,
    );

    test('a group has a UUID, a version ≥ 1 and a name', () {
      expect(() => group(name: ' '), throwsArgumentError);
      expect(() => group(version: 0), throwsArgumentError);
      expect(
        () => DishGroup(
          id: 'g',
          version: 1,
          name: 'x',
          localDate: LocalDate(2026, 1, 1),
          slotId: DefaultSlots.lunchId,
        ),
        throwsArgumentError,
      );
      expect(group(), group());
      expect(group().hashCode, group().hashCode);
      expect(group(), isNot(group(name: 'Mansaf')));
      expect(group(), isNot(group(version: 2)));
      expect(
        '${group()}',
        'DishGroup($groupG, v1, 2026-10-13, slot ${DefaultSlots.lunchId})',
      );
    });

    test('DY-004 a day mark has the date and the marks', () {
      final mark = DayMark(
        localDate: LocalDate(2026, 10, 13),
        incomplete: true,
      );
      expect(mark.notFasting, isFalse);
      expect(
        mark,
        DayMark(localDate: LocalDate(2026, 10, 13), incomplete: true),
      );
      expect(
        mark.hashCode,
        DayMark(localDate: LocalDate(2026, 10, 13), incomplete: true).hashCode,
      );
      expect(
        mark,
        isNot(
          DayMark(
            localDate: LocalDate(2026, 10, 13),
            incomplete: true,
            notFasting: true,
          ),
        ),
      );
      expect(
        mark,
        isNot(DayMark(localDate: LocalDate(2026, 10, 13), incomplete: false)),
      );
      expect(
        '$mark',
        'DayMark(2026-10-13, incomplete: true, notFasting: false)',
      );
    });
  });

  group('checks:', () {
    test('checkUuid, checkRowVersion, checkNotBlank', () {
      expect(checkUuid(entryA, 'id'), entryA);
      expect(() => checkUuid(entryA.toUpperCase(), 'id'), throwsArgumentError);
      expect(checkRowVersion(3), 3);
      expect(() => checkRowVersion(0, 'expectedVersion'), throwsArgumentError);
      expect(checkNotBlank('a', 'name'), 'a');
      expect(
        () => checkNotBlank('\n', 'name'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'name must not be blank',
          ),
        ),
      );
    });
  });
}
