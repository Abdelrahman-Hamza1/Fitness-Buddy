import 'package:fb_mobile/app/bootstrap/app_bootstrap.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A40 D6 the notifications start after the first frame, never before '
      'it (UX-001)', () async {
    final phone = TestPhone(notifications: true);
    final container = ProviderContainer.test(
      overrides: [
        ...phone.overrides(),
        ...todayOverrides(),
        // A38's weekly check-in reads the database; not this test's subject.
        weeklyCheckInProvider.overrideWith((ref) async => CheckInRun.none),
      ],
    );
    final bootstrap = container.read(appBootstrapProvider);
    expect(phone.notificationPlatform.onTap, isNull);
    await bootstrap.afterFirstFrame();
    await pumpEventQueue();
    expect(phone.notificationPlatform.onTap, isNotNull);
  });
}
