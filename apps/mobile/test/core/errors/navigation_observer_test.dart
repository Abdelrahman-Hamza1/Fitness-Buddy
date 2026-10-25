import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/errors/pii_scrubber.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../features/foods/presentation/support/search_screen_support.dart';
import '../../helpers/pump_app.dart';

void main() {
  final breadcrumbs = <Breadcrumb>[];
  setUpAll(() async {
    final options = SentryFlutterOptions();
    await Sentry.init((configured) {
      ErrorReporting.configure(
        options,
        dsn: 'https://k@o1.ingest.de.sentry.io/1',
        environment: 'test',
        release: 'test',
      );
      configured.integrations.forEach(configured.removeIntegration);
      options.beforeBreadcrumb = (breadcrumb, hint) {
        final scrubbed = PiiScrubber.scrubBreadcrumb(breadcrumb, hint);
        if (scrubbed != null) breadcrumbs.add(scrubbed);
        return scrubbed;
      };
      // No native SDK or real HTTP transport is initialized for navigation.
      // ignore: invalid_use_of_internal_member
    }, options: options);
  });
  tearDownAll(Sentry.close);

  testWidgets(
    'PR-11 navigation breadcrumbs keep route names only; to is '
    'the template (:id), never a concrete id; shell-branch pushes are recorded',
    (tester) async {
      const id = '01890abc-def0-7123-8abc-0123456789ab';
      final container = await pumpApp(
        tester,
        overrides: [searchOverride(FakeFoodSearch())],
      );
      final router = container.read(appRouterProvider)
        ..push(const FoodSearchRoute(slotId: id));
      await tester.pumpAndSettle();
      router.go(const MeRoute());
      await tester.pumpAndSettle();
      router.push(const PersonalFoodsRoute());
      await tester.pumpAndSettle();
      router.push(const PersonalFoodRoute(id: id));
      await tester.pumpAndSettle();
      router.go(const SavedMealsRoute());
      await tester.pumpAndSettle();
      router.push(const SavedMealRoute(id: id));
      await tester.pumpAndSettle();

      final pushes = breadcrumbs.where((b) => b.data?['state'] == 'didPush');
      for (final template in [
        '/today/add-food',
        '/me/foods/:id',
        '/me/meals/:id',
      ]) {
        expect(pushes.where((b) => b.data?['to'] == template), hasLength(1));
      }
      for (final crumb in breadcrumbs) {
        expect(crumb.toJson().toString(), isNot(contains(id)));
        expect(
          crumb.data?.keys.toSet().difference(PiiScrubber.keptNavigationData),
          isEmpty,
        );
      }
      await unmountApp(tester, container);
    },
  );
}
