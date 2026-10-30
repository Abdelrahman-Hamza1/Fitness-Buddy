import 'dart:async';

import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FD-023 a failed check is retried exactly once when the session '
      'becomes ready', () async {
    var attempts = 0;
    final retry = OneRetry(() async {
      attempts++;
      throw StateError('no session');
    });
    expect(await retry.run(), isFalse);
    expect(retry.finished, isFalse);
    expect(attempts, 1);
    retry.ready();
    await pumpEventQueue();
    expect(attempts, 2);
    expect(retry.finished, isTrue);
    // The retry's failure is swallowed and never retried again.
    retry.ready();
    await pumpEventQueue();
    expect(attempts, 2);
  });

  test('FD-023 ready while the first attempt is in flight: the retry runs '
      'as soon as it fails', () async {
    var attempts = 0;
    final first = Completer<void>();
    final retry = OneRetry(() {
      attempts++;
      return attempts == 1 ? first.future : Future<void>.value();
    });
    final run = retry.run();
    retry.ready();
    expect(attempts, 1);
    first.completeError(StateError('no session yet'));
    expect(await run, isFalse);
    await pumpEventQueue();
    expect(attempts, 2);
    expect(retry.finished, isTrue);
  });

  test(
    'FD-023 ready during a first attempt that succeeds runs nothing more',
    () async {
      var attempts = 0;
      final first = Completer<void>();
      final retry = OneRetry(() {
        attempts++;
        return first.future;
      });
      final run = retry.run();
      retry.ready();
      first.complete();
      expect(await run, isTrue);
      await pumpEventQueue();
      expect(attempts, 1);
    },
  );
}
