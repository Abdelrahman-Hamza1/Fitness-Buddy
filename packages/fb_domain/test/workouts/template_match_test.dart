import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

const List<TemplateTarget> _push = [
  (exerciseId: 'bench', sets: 3, reps: 8),
  (exerciseId: 'ohp', sets: 3, reps: 10),
];

void main() {
  test('WO-022 same exercises, set counts and reps: no difference', () {
    expect(
      TemplateMatch.differs(_push, [
        (exerciseId: 'bench', reps: [8, 8, 8]),
        (exerciseId: 'ohp', reps: [10, 10, 10]),
      ]),
      isFalse,
    );
  });

  test('WO-022 uneven reps are fatigue, not a change', () {
    expect(
      TemplateMatch.differs(_push, [
        (exerciseId: 'bench', reps: [8, 8, 7]),
        (exerciseId: 'ohp', reps: [10, 9, 8]),
      ]),
      isFalse,
    );
  });

  test(
    'WO-022 any rep difference counts except a small trailing shortfall',
    () {
      bool differs(List<int?> bench) => TemplateMatch.differs(_push, [
        (exerciseId: 'bench', reps: bench),
        (exerciseId: 'ohp', reps: [10, 10, 10]),
      ]);
      expect(differs([10, 10, 9]), isTrue);
      expect(differs([8, 8, 9]), isTrue);
      expect(differs([8, 7, 8]), isTrue);
      expect(differs([8, 8, 5]), isTrue);
      expect(differs([9, 8, 8]), isTrue);
      expect(differs([8, 8, 7]), isFalse);
      expect(differs([8, 7, 6]), isFalse);
      expect(differs([8, 6, 6]), isFalse);
      expect(differs([8, 8, null]), isFalse);
    },
  );

  test(
    'WO-022 a different exercise, order, set count or rep target differs',
    () {
      expect(
        TemplateMatch.differs(_push, [
          (exerciseId: 'ohp', reps: [10, 10, 10]),
          (exerciseId: 'bench', reps: [8, 8, 8]),
        ]),
        isTrue,
      );
      expect(
        TemplateMatch.differs(_push, [
          (exerciseId: 'bench', reps: [8, 8, 8, 8]),
          (exerciseId: 'ohp', reps: [10, 10, 10]),
        ]),
        isTrue,
      );
      expect(
        TemplateMatch.differs(_push, [
          (exerciseId: 'bench', reps: [8, 8, 8]),
        ]),
        isTrue,
      );
      expect(
        TemplateMatch.differs(_push, [
          (exerciseId: 'bench', reps: [10, 10, 10]),
          (exerciseId: 'ohp', reps: [10, 10, 10]),
        ]),
        isTrue,
      );
    },
  );

  test('WO-020 save as template: set count and the most common reps', () {
    expect(
      TemplateMatch.targetsFrom([
        (exerciseId: 'bench', reps: [8, 8, 7]),
        (exerciseId: 'ohp', reps: [10, 8]),
        (exerciseId: 'plank', reps: [null, null]),
        (exerciseId: 'empty', reps: []),
      ]),
      [
        (exerciseId: 'bench', sets: 3, reps: 8),
        (exerciseId: 'ohp', sets: 2, reps: 10),
        (exerciseId: 'plank', sets: 2, reps: 1),
      ],
    );
  });
}
