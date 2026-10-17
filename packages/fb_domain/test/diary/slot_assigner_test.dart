import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

const _assigner = SlotAssigner();

String? _assign(int minute, [List<MealSlot>? slots, SlotMode? mode]) =>
    _assigner.assign(minute, slots ?? DefaultSlots.all, mode ?? .normal);

int _at(int hour, [int minute = 0]) => hour * 60 + minute;

/// Slot IDs that sort in this order.
const _ids = [
  '00000000-0000-7000-8000-000000000001',
  '00000000-0000-7000-8000-000000000002',
  '00000000-0000-7000-8000-000000000003',
  '00000000-0000-7000-8000-000000000004',
  '00000000-0000-7000-8000-000000000005',
  '00000000-0000-7000-8000-000000000006',
];

MealSlot _slot(
  int index, {
  TimeWindow? window,
  int? sortOrder,
  SlotMode mode = SlotMode.normal,
  bool active = true,
}) => MealSlot(
  id: _ids[index],
  name: 'Slot $index',
  sortOrder: sortOrder ?? index,
  window: window,
  mode: mode,
  active: active,
);

void main() {
  group('DY-011 slot assignment:', () {
    test('DY-011 slot by time at window edges: 10:59 → breakfast, '
        '11:00 → lunch, 15:59 → lunch, 16:00 → dinner, 22:00 → snacks, '
        '03:59 → snacks', () {
      expect(_assign(_at(4)), DefaultSlots.breakfastId);
      expect(_assign(_at(10, 59)), DefaultSlots.breakfastId);
      expect(_assign(_at(11)), DefaultSlots.lunchId);
      expect(_assign(_at(15, 59)), DefaultSlots.lunchId);
      expect(_assign(_at(16)), DefaultSlots.dinnerId);
      expect(_assign(_at(21, 59)), DefaultSlots.dinnerId);
      expect(_assign(_at(22)), DefaultSlots.snacksId);
      expect(_assign(_at(3, 59)), DefaultSlots.snacksId);
      expect(_assign(0), DefaultSlots.snacksId);
      expect(_assign(1439), DefaultSlots.snacksId);
    });

    test('DY-011 a wrapping window takes times on both sides of midnight', () {
      final slots = [_slot(0, window: TimeWindow(_at(22), _at(2))), _slot(1)];
      expect(_assign(_at(23, 30), slots), _ids[0]);
      expect(_assign(_at(1), slots), _ids[0]);
      expect(_assign(_at(2), slots), _ids[1]);
    });

    test('DY-011 overlapping windows → the lower sort_order, then the lower '
        'ID', () {
      final slots = [
        _slot(0, window: TimeWindow(_at(10), _at(14)), sortOrder: 5),
        _slot(1, window: TimeWindow(_at(12), _at(16)), sortOrder: 2),
        _slot(2, window: TimeWindow(_at(12), _at(13)), sortOrder: 2),
      ];
      expect(_assign(_at(11), slots), _ids[0]);
      expect(_assign(_at(12, 30), slots), _ids[1]);
      expect(_assign(_at(12, 30), slots.reversed.toList()), _ids[1]);
      expect(_assign(_at(13, 30), slots), _ids[1]);
    });

    test('DY-011 inactive and other-mode slots are ignored', () {
      final slots = [
        _slot(0, window: TimeWindow(_at(4), _at(11)), active: false),
        _slot(1, window: TimeWindow(_at(4), _at(11)), mode: .ramadan),
        _slot(2),
        _slot(3, mode: .ramadan, sortOrder: 0),
      ];
      expect(_assign(_at(8), slots), _ids[2]);
      expect(_assign(_at(8), slots, .ramadan), _ids[1]);
      expect(_assign(_at(12), slots, .ramadan), _ids[3]);
    });

    test('DY-011 no window match and no windowless slot → the most recently '
        'started window', () {
      final slots = [
        _slot(0, window: TimeWindow(_at(7), _at(9))),
        _slot(1, window: TimeWindow(_at(13), _at(14))),
        _slot(2, window: TimeWindow(_at(19), _at(20))),
      ];
      expect(_assign(_at(10), slots), _ids[0]);
      expect(_assign(_at(16), slots), _ids[1]);
      expect(_assign(_at(23), slots), _ids[2]);
      // Back across midnight: 03:00 follows the 19:00 window.
      expect(_assign(_at(3), slots), _ids[2]);
      // Same start → sort order.
      final tied = [
        _slot(0, window: TimeWindow(_at(7), _at(8)), sortOrder: 9),
        _slot(1, window: TimeWindow(_at(7), _at(9)), sortOrder: 1),
      ];
      expect(_assign(_at(10), tied), _ids[1]);
    });

    test('DY-011 no active slot → null', () {
      expect(_assign(_at(12), const []), isNull);
      expect(_assign(_at(12), [_slot(0, active: false)]), isNull);
      expect(_assign(_at(12), DefaultSlots.all, .ramadan), isNull);
    });

    test('DY-011 the minute of day must be 0–1439', () {
      expect(() => _assign(-1), throwsRangeError);
      expect(() => _assign(1440), throwsRangeError);
    });
  });

  group('DY-011 properties:', () {
    final window = any.combine2(
      any.intInRange(0, 1440),
      any.intInRange(1, 1440),
      (start, length) => TimeWindow(start, (start + length) % 1440),
    );
    final slot = any.combine5(
      any.intInRange(0, _ids.length),
      window.nullable,
      any.intInRange(0, 3),
      any.choose(SlotMode.values),
      any.bool,
      (index, window, order, mode, active) => _slot(
        index,
        window: window,
        sortOrder: order,
        mode: mode,
        active: active,
      ),
    );

    Glados3(
      any.listWithLengthInRange(0, 7, slot),
      any.intInRange(0, 1440),
      any.choose(SlotMode.values),
      propertyRuns,
    ).test('property: SlotAssigner always returns an active slot of the mode '
        'when one exists, and is the same for the same input', (
      slots,
      minute,
      mode,
    ) {
      final candidates = [
        for (final s in slots)
          if (s.active && s.mode == mode) s,
      ];
      final id = _assigner.assign(minute, slots, mode);
      if (candidates.isEmpty) {
        expect(id, isNull);
        return;
      }
      expect(candidates.map((s) => s.id), contains(id));
      // Deterministic, and independent of the input order.
      expect(_assigner.assign(minute, slots, mode), id);
      expect(_assigner.assign(minute, slots.reversed, mode), id);
      // A containing window wins whenever there is one.
      final containing = candidates.where(
        (s) => s.window?.contains(minute) ?? false,
      );
      if (containing.isNotEmpty) {
        expect(containing.map((s) => s.id), contains(id));
      }
    });

    Glados2(window, any.intInRange(0, 1440), propertyRuns).test(
      'property: DY-011 window edges: the start and the last minute are in, '
      'the end goes to the windowless slot',
      (window, other) {
        final slots = [_slot(0, window: window), _slot(1, sortOrder: 9)];
        expect(_assign(window.startMin, slots), _ids[0]);
        expect(_assign((window.endMin + 1439) % 1440, slots), _ids[0]);
        expect(_assign(window.endMin, slots), _ids[1]);
        expect(
          _assign(other, slots),
          window.contains(other) ? _ids[0] : _ids[1],
        );
      },
    );
  });
}
