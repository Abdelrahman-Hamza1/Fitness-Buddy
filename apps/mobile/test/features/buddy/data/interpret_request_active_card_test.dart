import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    show food, intent, item, message, session;

const _requestId = '019a1b2c-0000-7000-8000-000000000001';
final EntryTime _now = EntryTime(DateTime.utc(2026, 10, 17, 8, 5), 0);

void main() {
  // rule: A22 follow-up-active-card
  test('A22 follow-up sends a bounded active card summary without ids or '
      'nutrients', () {
    final long = {...food(key: 'usda:long'), 'nameEn': '${'x' * 199}😀'};
    final card = session(
      message([
        intent([
          item(amount: 2),
          item(match: long, amount: 150, unit: 'g'),
          for (var i = 0; i < 31; i++)
            item(
              match: food(key: 'usda:f$i', kcal: 50 + i.toDouble()),
            ),
        ]),
      ]),
    ).cards.single;
    final request = InterpretRequestBuilder.build(
      requestId: _requestId,
      text: 'make it 3 eggs',
      now: _now,
      slots: DefaultSlots.all,
      personalFoods: const [],
      activeCard: card,
    ).toJson();
    expect(request['activeProposal'], card.id);
    final context = request['context']! as Map<String, Object?>;
    final active = context['activeCard']! as Map<String, Object?>;
    expect(active.keys.toSet(), {'slot', 'time', 'lines'});
    expect(active['slot'], 'breakfast');
    expect(active['time'], '08:00');
    final lines = (active['lines']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(lines, hasLength(InterpretBounds.activeCardLines));
    for (final line in lines) {
      expect(line.keys.toSet(), {'name', 'amount', 'unitCode', 'state'});
      expect((line['name']! as String).length, lessThanOrEqualTo(200));
    }
    expect(lines.first, {
      'name': 'Synthetic food',
      'amount': 2.0,
      'unitCode': 'piece',
      'state': 'cooked',
    });
    // Cut at 200 UTF-16 units without splitting the emoji's surrogate pair.
    expect(lines[1]['name'], 'x' * 199);
    expect(lines[1]['amount'], 150.0);
    expect(lines[1]['unitCode'], 'g');
    // No row IDs or nutrients anywhere in the summary.
    final text = active.toString();
    for (final line in card.lines) {
      expect(text, isNot(contains(line.entry.id)));
    }
    expect(text, isNot(contains('kcal')));
  });

  test('A22 a new message sends no active card', () {
    final request = InterpretRequestBuilder.build(
      requestId: _requestId,
      text: '2 eggs',
      now: _now,
      slots: DefaultSlots.all,
      personalFoods: const [],
    ).toJson();
    expect(request['activeProposal'], isNull);
    expect((request['context']! as Map<String, Object?>)['activeCard'], isNull);
  });
}
