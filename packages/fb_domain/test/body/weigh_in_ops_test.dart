import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

void main() {
  test('weigh-in ops: value equality, uuid and version checks; '
      'ChooseTrendWeighIn rejects a chosen id outside dayWeighIns', () {
    final draft = draftOn(day0, 80);
    final a1 = VersionedId(weighInA, 1);
    final b2 = VersionedId(weighInB, 2);

    // Family.
    for (final op in <WeighInOp>[
      CreateWeighIn(weighInA, draft),
      UpdateWeighIn(weighInA, 1, draft),
      DeleteWeighIn(a1),
      ChooseTrendWeighIn(day0, chosen: null, dayWeighIns: [a1]),
    ]) {
      expect(op.family, 'weighIn');
      expect(op.family, WeighInOp.familyName);
    }

    // Create.
    final create = CreateWeighIn(weighInA, draft);
    expect(create, CreateWeighIn(weighInA, draftOn(day0, 80)));
    expect(
      create.hashCode,
      CreateWeighIn(weighInA, draftOn(day0, 80)).hashCode,
    );
    expect(create == CreateWeighIn(weighInB, draft), isFalse);
    expect(create == CreateWeighIn(weighInA, draftOn(day0, 81)), isFalse);
    expect(create.id, weighInA);
    expect(create.draft, draft);
    expect(() => CreateWeighIn('A', draft), throwsArgumentError);

    // Update.
    final update = UpdateWeighIn(weighInA, 2, draft);
    expect(update, UpdateWeighIn(weighInA, 2, draftOn(day0, 80)));
    expect(update.hashCode, UpdateWeighIn(weighInA, 2, draft).hashCode);
    expect(update == UpdateWeighIn(weighInB, 2, draft), isFalse);
    expect(update == UpdateWeighIn(weighInA, 3, draft), isFalse);
    expect(update == UpdateWeighIn(weighInA, 2, draftOn(day0, 81)), isFalse);
    expect(update.expectedVersion, 2);
    expect(() => UpdateWeighIn('A', 1, draft), throwsArgumentError);
    expect(() => UpdateWeighIn(weighInA, 0, draft), throwsArgumentError);

    // Delete.
    final delete = DeleteWeighIn(a1);
    expect(delete, DeleteWeighIn(VersionedId(weighInA, 1)));
    expect(delete.hashCode, DeleteWeighIn(VersionedId(weighInA, 1)).hashCode);
    expect(delete == DeleteWeighIn(b2), isFalse);
    expect(delete.weighIn, a1);
    expect(delete.toString(), 'DeleteWeighIn($weighInA@v1)');

    // Choose: membership in any order, versions included.
    final choose = ChooseTrendWeighIn(day0, chosen: b2, dayWeighIns: [a1, b2]);
    final reordered = ChooseTrendWeighIn(
      day0,
      chosen: b2,
      dayWeighIns: [b2, a1],
    );
    expect(choose, reordered);
    expect(choose.hashCode, reordered.hashCode);
    expect(choose.chosen, b2);
    expect(choose.day, day0);
    expect(() => choose.dayWeighIns.add(a1), throwsUnsupportedError);
    for (final other in [
      ChooseTrendWeighIn(dayN(1), chosen: b2, dayWeighIns: [a1, b2]),
      ChooseTrendWeighIn(day0, chosen: a1, dayWeighIns: [a1, b2]),
      ChooseTrendWeighIn(day0, chosen: null, dayWeighIns: [a1, b2]),
      ChooseTrendWeighIn(day0, chosen: b2, dayWeighIns: [b2]),
      ChooseTrendWeighIn(
        day0,
        chosen: b2,
        dayWeighIns: [VersionedId(weighInA, 2), b2],
      ),
    ]) {
      expect(choose == other, isFalse, reason: '$other');
    }
    expect(
      choose.toString(),
      'ChooseTrendWeighIn(2026-01-01, $b2, 2 weigh-ins)',
    );
    expect(
      ChooseTrendWeighIn(day0, chosen: null, dayWeighIns: [a1]).toString(),
      'ChooseTrendWeighIn(2026-01-01, earliest, 1 weigh-ins)',
    );

    // Rejected shapes.
    expect(
      () => ChooseTrendWeighIn(day0, chosen: null, dayWeighIns: const []),
      throwsArgumentError,
    );
    expect(
      () => ChooseTrendWeighIn(
        day0,
        chosen: null,
        dayWeighIns: [a1, VersionedId(weighInA, 2)],
      ),
      throwsArgumentError,
    );
    expect(
      () => ChooseTrendWeighIn(day0, chosen: b2, dayWeighIns: [a1]),
      throwsArgumentError,
      reason: 'a chosen id outside dayWeighIns',
    );
    expect(
      () => ChooseTrendWeighIn(
        day0,
        chosen: VersionedId(weighInB, 1),
        dayWeighIns: [a1, b2],
      ),
      throwsArgumentError,
      reason: 'the chosen version differs from the listed one',
    );
  });
}
