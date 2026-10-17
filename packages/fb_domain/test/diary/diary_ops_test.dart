import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

final _day = LocalDate(2026, 10, 13);
final _yesterday = LocalDate(2026, 10, 12);

NewDiaryEntry _new({
  String id = entryA,
  EntryWhen? when,
  String? slotId,
  String? dishGroupId,
  EntryAmount? amount,
}) => NewDiaryEntry(
  id: id,
  when: when ?? EntryWhen.onDay(_yesterday),
  food: riceFood(),
  amount: amount ?? grams(150),
  slotId: slotId,
  dishGroupId: dishGroupId,
);

/// Checks [a] == [b] with equal hash codes, and [a] != each of [others].
void _expectValue(Object a, Object b, List<Object> others) {
  expect(a, b);
  expect(a.hashCode, b.hashCode);
  for (final other in others) {
    expect(a, isNot(other));
  }
}

void main() {
  group('value types:', () {
    test('VersionedId needs a UUID and a version ≥ 1', () {
      expect(() => VersionedId('x', 1), throwsArgumentError);
      expect(() => VersionedId(entryA, 0), throwsArgumentError);
      _expectValue(VersionedId(entryA, 2), VersionedId(entryA, 2), [
        VersionedId(entryA, 3),
        VersionedId(entryB, 2),
      ]);
      expect('${VersionedId(entryA, 2)}', '$entryA@v2');
    });

    test('EntryWhen: at an instant or on a day', () {
      final time = EntryTime(DateTime.utc(2026, 10, 13, 10), 180);
      _expectValue(EntryWhen.at(time), EntryWhen.at(time), [
        EntryWhen.at(EntryTime(DateTime.utc(2026, 10, 13, 10), 120)),
        EntryWhen.onDay(_day),
      ]);
      _expectValue(EntryWhen.onDay(_day), EntryWhen.onDay(_day), [
        EntryWhen.onDay(_yesterday),
        EntryWhen.onDay(_day, time: LocalTime(8)),
      ]);
      expect('${EntryWhen.at(time)}', 'at 2026-10-13T13:00:00+03:00');
      expect('${EntryWhen.onDay(_day)}', 'on 2026-10-13');
      expect(
        '${EntryWhen.onDay(_day, time: LocalTime(8, 30))}',
        'on 2026-10-13 at 08:30:00',
      );
    });

    test('NewDiaryEntry: IDs are UUIDs; equality; no names in the text', () {
      expect(() => _new(id: 'x'), throwsArgumentError);
      expect(() => _new(slotId: 'lunch'), throwsArgumentError);
      expect(() => _new(dishGroupId: 'g'), throwsArgumentError);
      _expectValue(_new(), _new(), [
        _new(id: entryB),
        _new(when: EntryWhen.onDay(_day)),
        _new(slotId: DefaultSlots.lunchId),
        _new(dishGroupId: groupG),
        _new(amount: grams(1)),
        NewDiaryEntry(
          id: entryA,
          when: EntryWhen.onDay(_yesterday),
          food: riceFood(id: 'other'),
          amount: grams(150),
        ),
      ]);
      expect('${_new()}', 'NewDiaryEntry($entryA, on 2026-10-12, slot auto)');
      expect(
        '${_new(slotId: DefaultSlots.lunchId)}',
        'NewDiaryEntry($entryA, on 2026-10-12, slot ${DefaultSlots.lunchId})',
      );
    });

    test('EntryPatch changes at least one field', () {
      expect(EntryPatch.new, throwsArgumentError);
      expect(() => EntryPatch(slotId: 'x'), throwsArgumentError);
      final full = EntryPatch(
        amount: grams(200),
        food: riceFood(),
        slotId: DefaultSlots.dinnerId,
        localTime: LocalTime(19, 30),
        localDate: _yesterday,
      );
      _expectValue(
        full,
        EntryPatch(
          amount: grams(200),
          food: riceFood(),
          slotId: DefaultSlots.dinnerId,
          localTime: LocalTime(19, 30),
          localDate: _yesterday,
        ),
        [
          EntryPatch(amount: grams(200)),
          EntryPatch(food: riceFood()),
          EntryPatch(slotId: DefaultSlots.dinnerId),
          EntryPatch(localTime: LocalTime(19, 30)),
          EntryPatch(localDate: _yesterday),
        ],
      );
      expect(
        '$full',
        'EntryPatch(amount, food, slot ${DefaultSlots.dinnerId}, '
            'time 19:30:00, date 2026-10-12)',
      );
    });

    test('MealSource: slot, day or entries', () {
      expect(() => MealSource.slot(_day, 'x'), throwsArgumentError);
      expect(() => MealSource.entries(const []), throwsArgumentError);
      expect(() => MealSource.entries(['x']), throwsArgumentError);
      expect(() => MealSource.entries([entryA, entryA]), throwsArgumentError);
      _expectValue(
        MealSource.slot(_day, DefaultSlots.lunchId),
        MealSource.slot(_day, DefaultSlots.lunchId),
        [
          MealSource.slot(_day, DefaultSlots.dinnerId),
          MealSource.slot(_yesterday, DefaultSlots.lunchId),
          MealSource.day(_day),
        ],
      );
      _expectValue(MealSource.day(_day), MealSource.day(_day), [
        MealSource.day(_yesterday),
      ]);
      _expectValue(
        MealSource.entries([entryA, entryB]),
        MealSource.entries([entryA, entryB]),
        [
          MealSource.entries([entryB, entryA]),
          MealSource.entries([entryA]),
        ],
      );
      final ids = (MealSource.entries([entryA]) as MealSourceEntries).ids;
      expect(() => ids.add(entryB), throwsUnsupportedError);
      expect(
        '${MealSource.slot(_day, DefaultSlots.lunchId)}',
        'slot ${DefaultSlots.lunchId} on 2026-10-13',
      );
      expect('${MealSource.day(_day)}', 'day 2026-10-13');
      expect('${MealSource.entries([entryA, entryB])}', '2 entries');
    });
  });

  group('DiaryOp:', () {
    test("DiaryOp value equality; family is 'diary'", () {
      final ops = <DiaryOp>[
        LogEntries([_new()]),
        UpdateDiaryEntry(entryA, 1, EntryPatch(amount: grams(10))),
        MoveEntries([VersionedId(entryA, 1)], toSlotId: DefaultSlots.lunchId),
        DeleteEntries([VersionedId(entryA, 1)]),
        CreateDishGroup(
          id: groupG,
          name: 'Maqluba',
          date: _day,
          slotId: DefaultSlots.lunchId,
        ),
        RenameDishGroup(groupG, 1, 'Mansaf'),
        MoveDishGroup(groupG, 1, toDate: _yesterday),
        DeleteDishGroup(groupG, 1),
        CopyMeal(
          MealSource.day(_yesterday),
          toDate: _day,
          copyIds: {entryA: copyA},
        ),
        SaveMeal(
          savedMealId: savedMeal,
          name: 'Usual breakfast',
          source: MealSource.entries([entryA]),
        ),
        MarkDay(_day, incomplete: true),
      ];
      for (final op in ops) {
        expect(op, isA<ChangeOp>());
        expect(op.family, 'diary');
        expect(op, isNot(ops.firstWhere((o) => o != op)));
      }
      expect(DiaryOp.familyName, 'diary');
      expect(SettingsOp.reset('a'), isNot(ops.first));
    });

    test('LogEntries: at least one entry, no duplicate IDs', () {
      expect(() => LogEntries(const []), throwsArgumentError);
      expect(() => LogEntries([_new(), _new()]), throwsArgumentError);
      final op = LogEntries([_new(), _new(id: entryB)]);
      expect(op.entries.map((e) => e.id), [entryA, entryB]);
      expect(() => op.entries.add(_new(id: entryC)), throwsUnsupportedError);
      _expectValue(op, LogEntries([_new(), _new(id: entryB)]), [
        LogEntries([_new(id: entryB), _new()]),
        LogEntries([_new()]),
      ]);
      expect('$op', 'LogEntries($entryA, $entryB)');
    });

    test('UpdateDiaryEntry: id, version and patch', () {
      final patch = EntryPatch(localTime: LocalTime(9));
      expect(() => UpdateDiaryEntry('x', 1, patch), throwsArgumentError);
      expect(() => UpdateDiaryEntry(entryA, 0, patch), throwsArgumentError);
      _expectValue(
        UpdateDiaryEntry(entryA, 1, patch),
        UpdateDiaryEntry(entryA, 1, EntryPatch(localTime: LocalTime(9))),
        [
          UpdateDiaryEntry(entryB, 1, patch),
          UpdateDiaryEntry(entryA, 2, patch),
          UpdateDiaryEntry(entryA, 1, EntryPatch(localTime: LocalTime(10))),
        ],
      );
      expect(
        '${UpdateDiaryEntry(entryA, 1, patch)}',
        'UpdateDiaryEntry($entryA@v1, EntryPatch(time 09:00:00))',
      );
    });

    test('MoveEntries: entries and a target day or slot', () {
      final a = VersionedId(entryA, 1);
      expect(() => MoveEntries([a]), throwsArgumentError);
      expect(() => MoveEntries(const [], toDate: _day), throwsArgumentError);
      expect(() => MoveEntries([a, a], toDate: _day), throwsArgumentError);
      expect(() => MoveEntries([a], toSlotId: 'x'), throwsArgumentError);
      final op = MoveEntries(
        [a, VersionedId(entryB, 3)],
        toDate: _yesterday,
        toSlotId: DefaultSlots.dinnerId,
      );
      _expectValue(
        op,
        MoveEntries(
          [a, VersionedId(entryB, 3)],
          toDate: _yesterday,
          toSlotId: DefaultSlots.dinnerId,
        ),
        [
          MoveEntries([a], toDate: _yesterday, toSlotId: DefaultSlots.dinnerId),
          MoveEntries([a, VersionedId(entryB, 3)], toDate: _yesterday),
          MoveEntries([
            a,
            VersionedId(entryB, 3),
          ], toSlotId: DefaultSlots.dinnerId),
        ],
      );
      expect(
        '$op',
        'MoveEntries($entryA@v1, $entryB@v3 → 2026-10-12, '
            'slot ${DefaultSlots.dinnerId})',
      );
    });

    test('DeleteEntries: at least one, no duplicates', () {
      final a = VersionedId(entryA, 1);
      expect(() => DeleteEntries(const []), throwsArgumentError);
      expect(
        () => DeleteEntries([a, VersionedId(entryA, 2)]),
        throwsArgumentError,
      );
      _expectValue(
        DeleteEntries([a]),
        DeleteEntries([VersionedId(entryA, 1)]),
        [
          DeleteEntries([VersionedId(entryA, 2)]),
        ],
      );
      expect('${DeleteEntries([a])}', 'DeleteEntries($entryA@v1)');
    });

    test('dish group ops: IDs, names, targets; no names in the text', () {
      CreateDishGroup create({
        String id = groupG,
        String name = 'Maqluba',
        LocalDate? date,
        String slotId = DefaultSlots.lunchId,
      }) => CreateDishGroup(
        id: id,
        name: name,
        date: date ?? _day,
        slotId: slotId,
      );
      expect(() => create(id: 'g'), throwsArgumentError);
      expect(() => create(name: ''), throwsArgumentError);
      expect(() => create(slotId: 'x'), throwsArgumentError);
      _expectValue(create(), create(), [
        create(id: copyG),
        create(name: 'Mansaf'),
        create(date: _yesterday),
        create(slotId: DefaultSlots.dinnerId),
      ]);
      expect(
        '${create()}',
        'CreateDishGroup($groupG, 2026-10-13, slot ${DefaultSlots.lunchId})',
      );

      expect(() => RenameDishGroup('g', 1, 'x'), throwsArgumentError);
      expect(() => RenameDishGroup(groupG, 0, 'x'), throwsArgumentError);
      expect(() => RenameDishGroup(groupG, 1, ' '), throwsArgumentError);
      _expectValue(
        RenameDishGroup(groupG, 1, 'Mansaf'),
        RenameDishGroup(groupG, 1, 'Mansaf'),
        [
          RenameDishGroup(groupG, 2, 'Mansaf'),
          RenameDishGroup(groupG, 1, 'Maqluba'),
          RenameDishGroup(copyG, 1, 'Mansaf'),
        ],
      );
      expect(
        '${RenameDishGroup(groupG, 1, 'Mansaf')}',
        'RenameDishGroup($groupG@v1)',
      );

      expect(() => MoveDishGroup(groupG, 1), throwsArgumentError);
      expect(() => MoveDishGroup('g', 1, toDate: _day), throwsArgumentError);
      expect(() => MoveDishGroup(groupG, 0, toDate: _day), throwsArgumentError);
      _expectValue(
        MoveDishGroup(groupG, 1, toDate: _day),
        MoveDishGroup(groupG, 1, toDate: _day),
        [
          MoveDishGroup(groupG, 2, toDate: _day),
          MoveDishGroup(copyG, 1, toDate: _day),
          MoveDishGroup(groupG, 1, toDate: _yesterday),
          MoveDishGroup(
            groupG,
            1,
            toDate: _day,
            toSlotId: DefaultSlots.lunchId,
          ),
        ],
      );
      expect(
        '${MoveDishGroup(groupG, 1, toSlotId: DefaultSlots.lunchId)}',
        'MoveDishGroup($groupG@v1 → slot ${DefaultSlots.lunchId})',
      );

      expect(() => DeleteDishGroup('g', 1), throwsArgumentError);
      expect(() => DeleteDishGroup(groupG, 0), throwsArgumentError);
      expect(DeleteDishGroup(groupG, 1).deleteEntries, isFalse);
      _expectValue(DeleteDishGroup(groupG, 1), DeleteDishGroup(groupG, 1), [
        DeleteDishGroup(groupG, 1, deleteEntries: true),
        DeleteDishGroup(groupG, 2),
        DeleteDishGroup(copyG, 1),
      ]);
      expect('${DeleteDishGroup(groupG, 1)}', 'DeleteDishGroup($groupG@v1)');
      expect(
        '${DeleteDishGroup(groupG, 1, deleteEntries: true)}',
        'DeleteDishGroup($groupG@v1, with entries)',
      );
    });

    test('DY-023 / DY-032 CopyMeal carries the copy IDs; a day copy keeps '
        'the slots', () {
      final ids = {entryA: copyA, entryB: copyB, groupG: copyG};
      final op = CopyMeal(
        MealSource.slot(_yesterday, DefaultSlots.lunchId),
        toDate: _day,
        copyIds: ids,
      );
      expect(op.toSlotId, isNull);
      expect(op.copyIds, ids);
      expect(() => op.copyIds[entryC] = copyA, throwsUnsupportedError);

      // A day copy takes no target slot.
      expect(
        () => CopyMeal(
          MealSource.day(_yesterday),
          toDate: _day,
          toSlotId: DefaultSlots.lunchId,
          copyIds: ids,
        ),
        throwsArgumentError,
      );
      // Copy IDs: not empty, UUIDs, unique, never a source ID.
      for (final bad in <Map<String, String>>[
        {},
        {entryA: 'x'},
        {'x': copyA},
        {entryA: copyA, entryB: copyA},
        {entryA: entryB, entryB: copyB},
      ]) {
        expect(
          () =>
              CopyMeal(MealSource.day(_yesterday), toDate: _day, copyIds: bad),
          throwsArgumentError,
          reason: '$bad',
        );
      }
      // An entries source needs a copy ID for every listed entry.
      expect(
        () => CopyMeal(
          MealSource.entries([entryA, entryB]),
          toDate: _day,
          copyIds: {entryA: copyA},
        ),
        throwsArgumentError,
      );
      expect(
        () => CopyMeal(
          MealSource.entries([entryA]),
          toDate: _day,
          toSlotId: 'x',
          copyIds: {entryA: copyA},
        ),
        throwsArgumentError,
      );

      final toDinner = CopyMeal(
        MealSource.entries([entryA]),
        toDate: _day,
        toSlotId: DefaultSlots.dinnerId,
        copyIds: {entryA: copyA},
      );
      _expectValue(
        toDinner,
        CopyMeal(
          MealSource.entries([entryA]),
          toDate: _day,
          toSlotId: DefaultSlots.dinnerId,
          copyIds: {entryA: copyA},
        ),
        [
          CopyMeal(
            MealSource.entries([entryA]),
            toDate: _day,
            copyIds: {entryA: copyA},
          ),
          CopyMeal(
            MealSource.entries([entryA]),
            toDate: _yesterday,
            toSlotId: DefaultSlots.dinnerId,
            copyIds: {entryA: copyA},
          ),
          CopyMeal(
            MealSource.entries([entryA]),
            toDate: _day,
            toSlotId: DefaultSlots.dinnerId,
            copyIds: {entryA: copyB},
          ),
          CopyMeal(
            MealSource.entries([entryA]),
            toDate: _day,
            toSlotId: DefaultSlots.dinnerId,
            copyIds: {entryA: copyA, groupG: copyG},
          ),
          CopyMeal(
            MealSource.day(_yesterday),
            toDate: _day,
            copyIds: {entryA: copyA},
          ),
        ],
      );
      expect(
        '$toDinner',
        'CopyMeal(1 entries → 2026-10-13, slot ${DefaultSlots.dinnerId}, '
            '1 copies)',
      );
    });

    test('DY-023 SaveMeal: a new saved meal ID, a name, a source', () {
      SaveMeal save({
        String id = savedMeal,
        String name = 'Usual breakfast',
        MealSource? source,
      }) => SaveMeal(
        savedMealId: id,
        name: name,
        source: source ?? MealSource.day(_day),
      );
      expect(() => save(id: 'x'), throwsArgumentError);
      expect(() => save(name: '  '), throwsArgumentError);
      _expectValue(save(), save(), [
        save(id: copyA),
        save(name: 'Other'),
        save(source: MealSource.day(_yesterday)),
      ]);
      expect('${save()}', 'SaveMeal($savedMeal, day 2026-10-13)');
      expect('${save()}', isNot(contains('breakfast')));
    });

    test('DY-004 MarkDay: a date and the mark', () {
      _expectValue(
        MarkDay(_day, incomplete: true),
        MarkDay(_day, incomplete: true),
        [
          MarkDay(_day, incomplete: false),
          MarkDay(_yesterday, incomplete: true),
        ],
      );
      expect(
        '${MarkDay(_day, incomplete: false)}',
        'MarkDay(2026-10-13, incomplete: false)',
      );
    });
  });
}
