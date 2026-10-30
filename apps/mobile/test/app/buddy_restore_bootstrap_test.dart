import 'dart:async';

import 'package:fb_mobile/app/bootstrap/app_bootstrap.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/features/adaptive/adaptive.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_phone.dart';

/// Records the generations Buddy's restore was started for.
final class _RecordingThread extends BuddyThreadController {
  new(this.calls);

  final List<int> calls;

  @override
  Future<void> ensureRestored(int generation) async => calls.add(generation);
}

void main() {
  // rule: A23 restore-after-bootstrap
  test('A23 restore runs after catalog install and account recovery once per '
      'generation', () async {
    final catalog = Completer<List<int>>();
    final calls = <int>[];
    final container = ProviderContainer.test(
      overrides: [
        ...TestPhone().overrides(),
        catalogPackInstallerProvider.overrideWithValue(
          CatalogPackInstaller(
            root: () async => throw StateError('unused root'),
            loadAsset: (_) => catalog.future,
          ),
        ),
        buddyThreadControllerProvider.overrideWith(
          () => _RecordingThread(calls),
        ),
        // A38's weekly check-in reads the database; not this test's subject.
        weeklyCheckInProvider.overrideWith((ref) async => CheckInRun.none),
      ],
    );
    final bootstrap = container.read(appBootstrapProvider);
    // Nothing is restored before the first frame.
    expect(calls, isEmpty);
    await bootstrap.afterFirstFrame();
    await pumpEventQueue();
    // The catalog is still installing: no restore against a missing pack.
    expect(calls, isEmpty);
    catalog.completeError(StateError('no pack (test)'));
    await pumpEventQueue();
    // Installed (or failed, contained) and recovered: restored once.
    expect(calls, [0]);
    await bootstrap.afterFirstFrame();
    await pumpEventQueue();
    expect(calls, [0]);
  });
}
