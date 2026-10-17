import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const _custom = '0199e3c2-5b1a-7000-8000-0000000000c1';

void main() {
  group('TimeWindow:', () {
    test('DY-011 a window is [start, end): start in, end out', () {
      final lunch = TimeWindow(660, 960);
      expect(lunch.wraps, isFalse);
      expect(lunch.contains(659), isFalse);
      expect(lunch.contains(660), isTrue);
      expect(lunch.contains(959), isTrue);
      expect(lunch.contains(960), isFalse);
    });

    test('DY-011 a wrapping window (22:00–02:00) contains 23:30 and 01:00, '
        'not 02:00', () {
      final late = TimeWindow(22 * 60, 2 * 60);
      expect(late.wraps, isTrue);
      expect(late.contains(23 * 60 + 30), isTrue);
      expect(late.contains(0), isTrue);
      expect(late.contains(60), isTrue);
      expect(late.contains(22 * 60), isTrue);
      expect(late.contains(2 * 60), isFalse);
      expect(late.contains(21 * 60 + 59), isFalse);
      expect(late.contains(12 * 60), isFalse);
    });

    test('DY-011 invalid windows rejected (start == end, out of range, '
        'only one bound)', () {
      expect(() => TimeWindow(600, 600), throwsArgumentError);
      expect(() => TimeWindow(-1, 600), throwsArgumentError);
      expect(() => TimeWindow(0, 1440), throwsArgumentError);
      expect(() => TimeWindow.fromBounds(600, null), throwsArgumentError);
      expect(() => TimeWindow.fromBounds(null, 600), throwsArgumentError);
      expect(TimeWindow.fromBounds(null, null), isNull);
      expect(TimeWindow.fromBounds(0, 1439), TimeWindow(0, 1439));
      expect(() => TimeWindow(0, 10).contains(1440), throwsRangeError);
      expect(() => TimeWindow(0, 10).contains(-1), throwsRangeError);
    });

    test('equality and text', () {
      expect(TimeWindow(240, 660), TimeWindow(240, 660));
      expect(TimeWindow(240, 660).hashCode, TimeWindow(240, 660).hashCode);
      expect(TimeWindow(240, 660), isNot(TimeWindow(240, 661)));
      expect(TimeWindow(240, 660), isNot(TimeWindow(241, 660)));
      expect('${TimeWindow(1320, 125)}', '22:00–02:05');
    });
  });

  group('SlotMode:', () {
    test('codes round trip; unknown codes are null', () {
      for (final mode in SlotMode.values) {
        expect(SlotMode.fromCode(mode.code), mode);
      }
      expect(SlotMode.normal.code, 'normal');
      expect(SlotMode.ramadan.code, 'ramadan');
      expect(SlotMode.fromCode('Normal'), isNull);
    });
  });

  group('MealSlot:', () {
    test('a slot needs a UUID and a default key or a name', () {
      expect(
        () => MealSlot(id: 'lunch', defaultKey: 'lunch', sortOrder: 0),
        throwsArgumentError,
      );
      expect(() => MealSlot(id: _custom, sortOrder: 4), throwsArgumentError);
      final custom = MealSlot(id: _custom, name: 'Pre-workout', sortOrder: 4);
      expect(custom.defaultKey, isNull);
      expect(custom.mode, SlotMode.normal);
      expect(custom.active, isTrue);
      expect(custom.window, isNull);
    });

    test('DY-003 default time: the window start, else 12:00', () {
      expect(DefaultSlots.dinner.defaultTime, LocalTime(16));
      expect(DefaultSlots.snacks.defaultTime, LocalTime(12));
      expect(MealSlot.defaultMinuteWithoutWindow, 720);
    });

    test('equality covers every field; text has no name', () {
      MealSlot slot({
        String? name = 'Meal 4',
        int sortOrder = 4,
        TimeWindow? window,
        SlotMode mode = SlotMode.normal,
        bool active = true,
        String? defaultKey,
      }) => MealSlot(
        id: _custom,
        name: name,
        sortOrder: sortOrder,
        window: window,
        mode: mode,
        active: active,
        defaultKey: defaultKey,
      );
      expect(slot(), slot());
      expect(slot().hashCode, slot().hashCode);
      expect(slot(), isNot(slot(name: 'Meal 5')));
      expect(slot(), isNot(slot(sortOrder: 5)));
      expect(slot(), isNot(slot(window: TimeWindow(0, 1))));
      expect(slot(), isNot(slot(mode: SlotMode.ramadan)));
      expect(slot(), isNot(slot(active: false)));
      expect(slot(), isNot(slot(defaultKey: 'lunch')));
      expect(
        MealSlot(id: DefaultSlots.lunchId, defaultKey: 'lunch', sortOrder: 1),
        isNot(slot()),
      );
      final text = '${slot(window: TimeWindow(0, 60), active: false)}';
      expect(
        text,
        'MealSlot($_custom, custom, #4, 00:00–01:00, normal, inactive)',
      );
      expect(text, isNot(contains('Meal 4')));
      expect(
        '${DefaultSlots.snacks}',
        'MealSlot(${DefaultSlots.snacksId}, snacks, #3, no window, normal)',
      );
    });
  });

  group('DY-010 default slots:', () {
    test('DY-010 the default slots are Breakfast, Lunch, Dinner, Snacks with '
        'the D8 windows and natural IDs', () {
      expect(DefaultSlots.all.map((s) => s.defaultKey), [
        'breakfast',
        'lunch',
        'dinner',
        'snacks',
      ]);
      expect(DefaultSlots.all.map((s) => s.sortOrder), [0, 1, 2, 3]);
      expect(DefaultSlots.all.map((s) => s.window), [
        TimeWindow(240, 660),
        TimeWindow(660, 960),
        TimeWindow(960, 1320),
        null,
      ]);
      expect(DefaultSlots.all.map((s) => s.id), [
        DefaultSlots.breakfastId,
        DefaultSlots.lunchId,
        DefaultSlots.dinnerId,
        DefaultSlots.snacksId,
      ]);
      for (final slot in DefaultSlots.all) {
        expect(slot.name, isNull);
        expect(slot.mode, SlotMode.normal);
        expect(slot.active, isTrue);
        // UUIDv5 (version nibble 5, RFC variant).
        expect(
          slot.id,
          matches(
            RegExp(
              '^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}'
              r'-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
      }
      expect(
        () => DefaultSlots.all.add(DefaultSlots.lunch),
        throwsUnsupportedError,
      );
    });

    test('DY-010 natural keys are <mode>:<defaultKey>', () {
      expect(DefaultSlots.naturalKey('breakfast'), 'normal:breakfast');
      expect(
        DefaultSlots.naturalKey('suhoor', mode: SlotMode.ramadan),
        'ramadan:suhoor',
      );
    });
  });
}
