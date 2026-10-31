import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';

/// The live weigh-ins, read from the profile.
Future<List<WeighIn>> _stored(ProviderContainer container) =>
    WeighInRepository(container.read(appDatabaseProvider))
        .watchLive()
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TestFailure('Timed out reading weigh-ins'),
        );

/// Stable identity used by TodayScreen's day pager.
Finder dayPage(LocalDate date) => find.byKey(ValueKey<LocalDate>(date));

/// The weight card of [date]'s page, with the text [text].
Finder _cardText(LocalDate date, String text) => find.descendant(
  of: find.descendant(of: dayPage(date), matching: find.byType(WeightSlide)),
  matching: find.text(text),
);

/// The ＋ of [date]'s slim weight row (a day with a weigh-in, D-084).
Finder _slimAdd(LocalDate date) => find.descendant(
  of: find.descendant(of: dayPage(date), matching: find.byType(WeightSlide)),
  matching: find.byKey(const ValueKey('today-weigh-in')),
);

/// Waits for the snackbar that starts with [prefix].
Future<void> _waitForSnackBar(WidgetTester tester, String prefix) => waitUntil(
  tester,
  () => find
      .descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(prefix),
      )
      .evaluate()
      .isNotEmpty,
  'the snackbar "$prefix..."',
);

/// Types [keys] on the weigh-in pad (the digits are not counted as taps).
Future<void> _type(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    final target = find.descendant(
      of: find.byType(FbNumberPad),
      matching: find.text(key),
    );
    await tapExactly(tester, target, 'pad key $key');
    await tester.pump();
  }
}

/// WB-001 UX-005 on the device (A14 D15): offline (no API is reachable, as
/// in `app_test`), a throw-away profile, every write through the app's own
/// sheet and the single writer. Counts the taps that aren't digits.
void main() {
  patrolTest('A14 weigh-in from Today in three taps', ($) async {
    final container = await bootApp($, 'it-weigh', rootName: 'fb_weigh_it');
    final tester = $.tester;
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    var taps = 0;
    Future<void> tap(Finder target, String what) async {
      taps++;
      await tapExactly(tester, target, what);
      await pumpFor(tester, const Duration(milliseconds: 600));
    }

    final save = find.widgetWithText(FbButton, 'Save');

    await tapExactly(
      tester,
      find.byKey(const ValueKey('fb-slide-dot-1')).first,
      'Weight slide',
    );
    await pumpFor(tester, const Duration(milliseconds: 600));
    // No weigh-ins yet: the card invites the first one.
    const invite = 'Log your first weigh-in';
    await waitUntil(
      tester,
      () => _cardText(today, invite).evaluate().length == 1,
      'the weight card on Today',
    );
    expect(await _stored(container), isEmpty);

    // First weigh-in: card, type 97.4, Save.
    await tap(_slimAdd(today), 'Weigh in');
    await waitUntil(
      tester,
      () => find.byType(FbNumberPad).evaluate().isNotEmpty,
      'the weigh-in pad',
    );
    await _type(tester, '97.4');
    await tap(save.last, 'Save');
    expect(taps, 2);
    await _waitForSnackBar(tester, 'Weigh-in saved: 97.4 kg');
    expect((await _stored(container)).single.kg, 97.4);
    await waitUntil(
      tester,
      () => _slimAdd(today).evaluate().isNotEmpty,
      'the slim weight row',
    );

    // The same value again: 2 taps, no typing (the pad is prefilled).
    taps = 0;
    await tap(_slimAdd(today), 'the slim row plus');
    await waitUntil(
      tester,
      () => save.evaluate().isNotEmpty,
      'the weigh-in sheet',
    );
    await tap(save.last, 'Save');
    expect(taps, 2);
    await waitUntilAsync(
      tester,
      () async => (await _stored(container)).length == 2,
      'the second weigh-in',
    );

    // An unusual value: the in-sheet confirm is the third tap.
    taps = 0;
    await tap(_slimAdd(today), 'the slim row plus');
    await waitUntil(
      tester,
      () => find.byType(FbNumberPad).evaluate().isNotEmpty,
      'the weigh-in pad',
    );
    await _type(tester, '101');
    await tap(save.last, 'Save');
    await waitUntil(
      tester,
      () => find.textContaining("That's +3.6 kg").evaluate().isNotEmpty,
      'the in-sheet confirm',
    );
    // The confirm's answers replace the pinned Save ("Save 101.0 kg"); the
    // 600 ms pause after each tap is past its 300 ms double-tap guard.
    await tap(
      find.widgetWithText(FbButton, 'Save 101.0 kg'),
      'the confirm Save',
    );
    expect(taps, 3);
    await waitUntilAsync(
      tester,
      () async => (await _stored(container)).any((w) => w.kg == 101),
      'the confirmed weigh-in',
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}
