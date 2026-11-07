import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/photo_estimates.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// A tiny stand-in for a base64 photo (built at runtime: no key-shaped
/// literal).
final String _photo = base64Encode(
  List<int>.generate(48, (i) => (i * 7) % 256),
);

void main() {
  List<Object?> explicitOf(Map<String, Object?> out) => [
    for (final i in out['items']! as List<Object?>)
      ((i! as Map)['amount'] as Map)['explicit'],
  ];

  Map<String, Object?> rice(double grams, {String mention = 'rice'}) => {
    ...item(amount: grams, unit: 'g'),
    'mention': mention,
    'match': {...food(), 'nameEn': 'White rice, cooked', 'nameAr': 'أرز'},
  };

  Map<String, Object?> chicken(double grams) => {
    ...item(amount: grams, unit: 'g'),
    'mention': 'chicken',
    'match': {...food(), 'nameEn': 'Chicken breast, grilled', 'nameAr': null},
  };

  test("AI-011 D-045 a photo turn keeps a stated amount only when the user's "
      'own words state that weight or volume for that item', () {
    // One item: the message's only weight or volume backs it.
    expect(
      explicitOf(
        photoEstimates(intent([rice(150)]), 'this is about 150g of rice'),
      ),
      [true],
    );
    expect(
      explicitOf(
        photoEstimates(
          intent([item(amount: 0.5, unit: 'l')]),
          'نص لتر لبن، 500 مل',
        ),
      ),
      [true],
    );
    // The model's mention is never trusted (fix-check): "lunch" + a
    // mention "150g rice" is an estimate.
    expect(
      explicitOf(
        photoEstimates(intent([rice(150, mention: '150g rice')]), 'lunch'),
      ),
      [false],
    );
    // A bare number, another family, another number, two weights for one
    // item, a number glued to a word: estimates.
    for (final (amount, unit, text) in [
      (2.0, 'g', '2 sandwiches'),
      (150.0, 'ml', 'about 150 g'),
      (200.0, 'g', 'about 150 g'),
      (150.0, 'g', '150 g of rice and 40 g of sauce'),
      (150.0, 'g', 'x150g'),
      (2.0, 'piece', '2 pieces'),
    ]) {
      expect(
        explicitOf(
          photoEstimates(intent([item(amount: amount, unit: unit)]), text),
        ),
        [false],
        reason: '$amount $unit / $text',
      );
    }
    // Several items: a quantity counts for the item whose food it names.
    final out = photoEstimates(
      intent([
        rice(150),
        chicken(100),
        chicken(120),
        item(unit: 'plate', explicit: false),
      ]),
      'rice 150g and grilled chicken 100 g',
    );
    expect(explicitOf(out), [true, true, false, false]);
    // A quantity as near to both foods is nobody's.
    expect(
      explicitOf(
        photoEstimates(intent([rice(150), chicken(150)]), 'rice 150 g chicken'),
      ),
      [false, false],
    );
    // Other kinds pass through.
    final weighIn = {'kind': 'weighIn', 'value': 97};
    expect(identical(photoEstimates(weighIn, ''), weighIn), isTrue);
  });

  test('AI-011 the photo goes with round 0 only, never into the database, '
      'and its cards are estimates', () async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([item(amount: 2)]),
        ]),
      );
    await h.thread.send('lunch', texts, image: _photo);
    final sent = h.adapter.requests.single.data as Map<String, Object?>;
    expect((sent['message']! as Map)['image'], _photo);
    final turn = h.state.turns.single;
    expect(turn.photo, isTrue);
    final line = turn.cards.single.card.lines.single;
    expect(line.entry.food.provenance.isEstimate, isTrue);
    // Not in any change set (checkpoints, holder answers, messages).
    for (final set in h.applied) {
      for (final op in set.ops) {
        if (op case SaveTurnCheckpoint(:final json?)) {
          expect(json.contains(_photo), isFalse);
          expect(jsonDecode(json), containsPair('photo', true));
        }
      }
    }
    for (final row in await h.chat()) {
      expect(
        '${row.messageText}${row.answerJson}${row.requestJson}',
        isNot(contains(_photo)),
      );
    }
  });
}
