import 'dart:convert';

import 'package:test/test.dart';

import 'generated/export.dart';
import 'helpers/fake_adapter.dart';

/// Encodes to a JSON string and back, like the wire does.
Map<String, Object?> _overTheWire(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  final logFoodJson = <String, Object?>{
    'kind': 'logFood',
    'items': [
      {'query': 'hummus', 'quantity': 150.0, 'unit': 'g'},
      {'query': 'pita', 'quantity': 1.0, 'unit': 'piece'},
    ],
    'eatenAt': '2026-10-12T08:30:00.000Z',
    'date': '2026-10-12',
  };
  final askJson = <String, Object?>{
    'kind': 'askQuestion',
    'question': 'How much protein is left today?',
    'topic': null,
  };
  final unknownJson = <String, Object?>{
    'kind': 'unknown',
    'reason': 'not about food',
  };

  group('union fixture:', () {
    test('each kind decodes to its own sealed subtype', () {
      final logFood = Intent.fromJson(logFoodJson);
      final ask = Intent.fromJson(askJson);
      final unknown = Intent.fromJson(unknownJson);

      expect(logFood, isA<IntentLogFood>());
      expect((logFood as IntentLogFood).items.first.query, 'hummus');
      expect(logFood.eatenAt, DateTime.utc(2026, 10, 12, 8, 30));
      expect(ask, isA<IntentAskQuestion>());
      expect((ask as IntentAskQuestion).question, startsWith('How much'));
      // `unknown` is a real variant, distinct from the `unrecognized` fallback.
      expect(unknown, isA<IntentUnknown>());
      expect((unknown as IntentUnknown).reason, 'not about food');
    });

    test('toJson round-trips with nested objects as maps', () {
      for (final json in [logFoodJson, askJson, unknownJson]) {
        final intent = Intent.fromJson(json);

        final encoded = intent.toJson();

        expect(encoded, json);
        expect(Intent.fromJson(_overTheWire(encoded)), intent);
      }
      // explicit_to_json: nested models are maps, not model instances.
      final items = Intent.fromJson(logFoodJson).toJson()['items']! as List;
      expect(items, everyElement(isA<Map<String, Object?>>()));
    });

    test('an unknown future kind decodes to the unrecognized variant', () {
      final future = Intent.fromJson({'kind': 'logWeight', 'kilograms': 80});
      final noKind = Intent.fromJson({'question': 'no discriminator'});

      expect(future, isA<IntentUnrecognized>());
      expect(noKind, isA<IntentUnrecognized>());
    });

    test('switch over the sealed type is exhaustive', () {
      // No default branch: this only compiles because Intent is sealed.
      String describe(Intent intent) => switch (intent) {
        IntentLogFood(:final items) => 'log ${items.length}',
        IntentAskQuestion(:final question) => 'ask $question',
        IntentUnknown() => 'unknown',
        IntentUnrecognized() => 'update the app',
      };

      expect(describe(Intent.fromJson(logFoodJson)), 'log 2');
      expect(describe(Intent.fromJson({'kind': 'next'})), 'update the app');
    });

    test(
      'a list of intents decodes through a dio call (fake adapter)',
      () async {
        final adapter = FakeAdapter(
          body: {
            'id': '0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b',
            'intents': [
              logFoodJson,
              askJson,
              unknownJson,
              {'kind': 'logWeight'},
            ],
          },
        );

        final result = await FixtureApi(fakeDio(adapter)).buddy.interpret(
          idempotencyKey: '0192a5d4-7c3e-7b1a-9f2e-000000000001',
          body: InterpretRequest(
            messageId: '0192a5d4-7c3e-7b1a-9f2e-000000000001',
            text: 'had hummus and pita',
            sentAt: DateTime.utc(2026, 10, 12, 8, 31),
            localDate: '2026-10-12',
          ),
        );

        expect(result.intents.map((intent) => intent.runtimeType), [
          IntentLogFood,
          IntentAskQuestion,
          IntentUnknown,
          IntentUnrecognized,
        ]);
        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.uri.path, '/v1/buddy/interpret');
        expect(
          request.headers['Idempotency-Key'],
          '0192a5d4-7c3e-7b1a-9f2e-000000000001',
        );
        for (final header in clientHeaders) {
          expect(request.headers.keys, isNot(contains(header)));
        }
      },
    );

    test('type-array nullable and oneOf null-wrap both become T?', () {
      // Both compile with a literal null only because the fields are nullable;
      // both are still required (D4: absent values are sent as null).
      const ask = Intent.askQuestion(
        kind: 'askQuestion',
        question: 'q',
        topic: null, // type: [string, 'null']
      );
      final logFood = Intent.logFood(
        kind: 'logFood',
        items: const [],
        eatenAt: DateTime.utc(2026, 10, 12),
        date: null, // oneOf: [$ref LocalDate, type: 'null']
      );

      expect(ask.toJson(), containsPair('topic', null));
      expect(logFood.toJson(), containsPair('date', null));
      final decoded = Intent.fromJson({...logFoodJson, 'date': null});
      expect((decoded as IntentLogFood).date, isNull);
    });

    test('LocalDate stays a YYYY-MM-DD string on the wire', () async {
      // LocalDate is a String typedef: a plain string literal is accepted.
      const day = '2026-10-12';
      final adapter = FakeAdapter(body: {'id': 'x', 'intents': <Object?>[]});

      await FixtureApi(fakeDio(adapter)).buddy.interpret(
        idempotencyKey: 'k',
        body: InterpretRequest(
          messageId: 'm',
          text: 't',
          sentAt: DateTime.utc(2026, 10, 12, 8, 31),
          localDate: day,
        ),
      );
      final sent = _overTheWire(
        adapter.requests.single.data as Map<String, Object?>,
      );
      final logFood = Intent.fromJson(logFoodJson) as IntentLogFood;

      expect(sent['localDate'], '2026-10-12');
      // Instant (date-time) is untouched by the strip: still a DateTime.
      expect(sent['sentAt'], '2026-10-12T08:31:00.000Z');
      expect(logFood.date, isA<String>());
      expect(logFood.toJson()['date'], '2026-10-12');
    });
  });
}
