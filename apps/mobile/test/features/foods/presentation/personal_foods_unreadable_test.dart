import 'package:drift/drift.dart' show Value;
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/personal_food_support.dart';

void main() {
  testWidgets('#100 Your foods counts a row it cannot read instead of hiding '
      'it', (tester) async {
    final container = await pumpPersonal(
      tester,
      foods: [
        aFood(1),
        aFood(2, name: 'Zaatar mix'),
      ],
      at: const PersonalFoodsRoute(),
    );
    expect(find.text('Labneh'), findsOneWidget);
    expect(find.textContaining("can't be shown"), findsNothing);

    final db = dbOf(container);
    // A damaged row (or one from a newer app version) can't come from the
    // applier, so the test writes it directly.
    await tester.runAsync(
      () => runAuthorizedWrite(
        () =>
            (db.update(
              db.personalFoods,
            )..where((t) => t.id.equals(aFood(1).id))).write(
              const PersonalFoodsCompanion(aliasesJson: Value('{corrupt')),
            ),
      ),
    );
    await settle(tester);

    expect(find.text('Labneh'), findsNothing);
    expect(find.text('Zaatar mix'), findsOneWidget);
    expect(
      find.text(
        "1 food can't be shown. It may be damaged or come from a newer app "
        'version.',
      ),
      findsOneWidget,
    );
    await finish(tester, container);
  });
}
