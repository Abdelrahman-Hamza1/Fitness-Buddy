import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FoodRef:', () {
    test('kinds round trip their codes; an unknown kind is null', () {
      for (final kind in FoodRefKind.values) {
        expect(FoodRefKind.fromCode(kind.code), kind);
      }
      expect(FoodRefKind.values.map((k) => k.code), [
        'catalog',
        'personal',
        'estimate',
      ]);
      // A27 adds `batch`; this version reads it as unknown.
      expect(FoodRefKind.fromCode('batch'), isNull);
    });

    test('catalog, personal and estimate refs', () {
      final catalog = FoodRef.catalog('usda:169704', version: '2026.10.1');
      expect(catalog.kind, FoodRefKind.catalog);
      expect(catalog.id, 'usda:169704');
      expect(catalog.version, '2026.10.1');
      final personal = FoodRef.personal('0199e3c2-5b1a-7000-8000-000000000001');
      expect(personal.kind, FoodRefKind.personal);
      expect(personal.version, isNull);
      final estimate = FoodRef.estimate();
      expect(estimate.id, isNull);
      expect(estimate.version, isNull);
      expect('$catalog', 'FoodRef(catalog, usda:169704, 2026.10.1)');
    });

    test('only an estimate may have no id; ids and versions are not empty', () {
      expect(() => FoodRef(FoodRefKind.catalog), throwsArgumentError);
      expect(() => FoodRef(FoodRefKind.personal), throwsArgumentError);
      expect(() => FoodRef.personal(''), throwsArgumentError);
      expect(() => FoodRef.catalog('x', version: ''), throwsArgumentError);
      expect(FoodRef(FoodRefKind.estimate, id: 'e1').id, 'e1');
    });

    test('equality by kind, id and version', () {
      final a = FoodRef.catalog('x', version: '1');
      expect(a, FoodRef.catalog('x', version: '1'));
      expect(a.hashCode, FoodRef.catalog('x', version: '1').hashCode);
      expect(a, isNot(FoodRef.catalog('x', version: '2')));
      expect(a, isNot(FoodRef.catalog('y', version: '1')));
      expect(FoodRef.personal('x'), isNot(FoodRef(.estimate, id: 'x')));
    });
  });

  group('FD-010 / SC-4 provenance:', () {
    test('FD-010 the four source badges of spec/11 §2', () {
      expect(FoodSource.values.map((s) => s.code), [
        'yours',
        'database',
        'reference',
        'estimate',
      ]);
      for (final source in FoodSource.values) {
        expect(FoodSource.fromCode(source.code), source);
      }
      expect(FoodSource.fromCode('usda'), isNull);
    });

    test(
      'SC-4 an estimate source is always an estimate; a range needs one',
      () {
        expect(Provenance(source: FoodSource.estimate).isEstimate, isTrue);
        expect(Provenance(source: FoodSource.database).isEstimate, isFalse);
        expect(
          () => Provenance(source: FoodSource.estimate, isEstimate: false),
          throwsArgumentError,
        );
        expect(
          () => Provenance(
            source: FoodSource.database,
            range: EstimateRange(100, 200),
          ),
          throwsArgumentError,
        );
        // A reference dish with an estimated portion.
        final estimated = Provenance(
          source: FoodSource.reference,
          isEstimate: true,
          range: EstimateRange(400, 650),
          assumptions: ['all oil eaten'],
        );
        expect(estimated.isEstimate, isTrue);
        expect(estimated.range, EstimateRange(400, 650));
        expect(estimated.assumptions, ['all oil eaten']);
        expect(() => estimated.assumptions.add('x'), throwsUnsupportedError);
      },
    );

    test('estimate ranges are finite, not negative, low ≤ high', () {
      expect(() => EstimateRange(-1, 10), throwsArgumentError);
      expect(() => EstimateRange(0, double.nan), throwsArgumentError);
      expect(() => EstimateRange(0, double.infinity), throwsArgumentError);
      expect(() => EstimateRange(20, 10), throwsArgumentError);
      expect(EstimateRange(10, 10).highKcal, 10);
      expect(EstimateRange(1, 2), EstimateRange(1, 2));
      expect(EstimateRange(1, 2).hashCode, EstimateRange(1, 2).hashCode);
      expect(EstimateRange(1, 2), isNot(EstimateRange(1, 3)));
      expect(EstimateRange(1, 2), isNot(EstimateRange(0, 2)));
      expect('${EstimateRange(400, 650)}', 'EstimateRange(range)');
    });

    test('provenance equality and text without the assumptions', () {
      Provenance p({List<String> assumptions = const ['a', 'b']}) => Provenance(
        source: FoodSource.estimate,
        range: EstimateRange(1, 2),
        assumptions: assumptions,
      );
      expect(p(), p());
      expect(p().hashCode, p().hashCode);
      expect(p(), isNot(p(assumptions: ['b', 'a'])));
      expect(p(), isNot(p(assumptions: ['a'])));
      expect(p(), isNot(Provenance(source: FoodSource.estimate)));
      expect(
        Provenance(source: FoodSource.reference),
        isNot(Provenance(source: FoodSource.reference, isEstimate: true)),
      );
      expect(
        Provenance(source: FoodSource.yours),
        isNot(Provenance(source: FoodSource.database)),
      );
      final text = '${p(assumptions: ['secret oil note'])}';
      expect(
        text,
        'Provenance(estimate, estimate, EstimateRange(range), '
        '1 assumptions)',
      );
      expect(text, isNot(contains('secret')));
      expect(
        '${Provenance(source: FoodSource.database)}',
        'Provenance(database, 0 assumptions)',
      );
    });
  });
}
