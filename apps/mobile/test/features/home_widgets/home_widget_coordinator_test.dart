import 'dart:async';

import 'package:fb_domain/fb_domain.dart' show LocalDate;
import 'package:fb_domain/testing.dart' show ManualClock;
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/home_widget/home_widget_store.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/home_widgets/application/home_widget_inputs.dart';
import 'package:fb_mobile/features/home_widgets/home_widgets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeStore implements HomeWidgetStore {
  final List<String> calls = [];
  String? pending;
  Completer<String?>? holdLaunch;
  void Function()? onTap;

  @override
  bool held = false;

  @override
  int epoch = 0;

  @override
  Future<void> clearAndHold() async {
    held = true;
    epoch++;
    calls.add('clearAndHold');
  }

  @override
  void release() {
    held = false;
    epoch++;
  }

  @override
  Future<void> save(Map<String, Object> data, {int? epoch}) async {
    if (held || (epoch != null && epoch != this.epoch)) return;
    calls.add('save ${data['shows']} ${data['profile']}');
  }

  @override
  Future<void> clear() async => calls.add('clear');

  @override
  Future<void> clearFor(String profileTag) async =>
      calls.add('clearFor $profileTag');

  @override
  Future<String?> takeLaunchAction() async {
    if (holdLaunch case final hold?) {
      holdLaunch = null;
      return await hold.future;
    }
    final action = pending;
    pending = null;
    return action;
  }

  @override
  void listen(void Function() onTap) => this.onTap = onTap;
}

void main() {
  late _FakeStore store;
  late List<String> opened;
  late ProviderContainer container;

  setUp(() {
    store = _FakeStore();
    opened = [];
    container = ProviderContainer(
      overrides: [
        homeWidgetStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(
          ManualClock(DateTime.utc(2026, 11, 7, 9)),
        ),
        homeWidgetLinkOpenerProvider.overrideWithValue(
          (location) async => opened.add(location),
        ),
        homeWidgetInputsProvider.overrideWith((ref) async {
          final generation = ref.watch(profileGenerationProvider);
          return HomeWidgetInputs(
            generation: generation,
            profileTag: 'tag$generation',
            hidden: true,
            signedOut: false,
          );
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await container.read(homeWidgetCoordinatorProvider).idle;
  }

  test('UX-084 UX-085 A71 D5 the snapshot is written on start; a profile '
      'switch clears the widgets, then the new profile writes', () async {
    await container.read(homeWidgetCoordinatorProvider).start();
    await settle();
    expect(store.calls, ['save hidden tag0']);

    container.read(profileGenerationProvider.notifier).bump();
    await settle();
    expect(store.calls, ['save hidden tag0', 'clear', 'save hidden tag1']);
  });

  test('A71 review: a profile switch while the launch tap is still read is '
      'not missed: the widgets clear and follow the new profile', () async {
    final launch = Completer<String?>();
    store.holdLaunch = launch;
    final started = container.read(homeWidgetCoordinatorProvider).start();
    await settle();
    container.read(profileGenerationProvider.notifier).bump();
    await settle();
    launch.complete('today');
    await started;
    await settle();
    expect(store.calls, contains('clear'));
    expect(store.calls.last, 'save hidden tag1');
    expect(opened, [TodayRoute.path]);
  });

  test("A71 review: the numbers tap goes back to today's page, also when "
      'Today already shows another day', () async {
    container
        .read(todayControllerProvider.notifier)
        .goTo(LocalDate(2000, 1, 1));
    expect(container.read(todayControllerProvider), isNotNull);
    store.pending = 'today';
    await container.read(homeWidgetCoordinatorProvider).start();
    await settle();
    expect(container.read(todayControllerProvider), isNull);
  });

  test('UX-083 A71 D7 a launch tap opens its place once; an unknown action '
      'opens nothing', () async {
    store.pending = 'weigh';
    await container.read(homeWidgetCoordinatorProvider).start();
    await settle();
    expect(opened, [const TodayRoute(open: TodayOpen.weighIn).location]);

    store.pending = 'delete-everything';
    store.onTap!();
    await settle();
    expect(opened, hasLength(1));

    store.pending = 'ask';
    store.onTap!();
    await settle();
    expect(opened.last, const TodayRoute(open: TodayOpen.buddy).location);
  });

  test('A71 a disabled build never touches the widgets', () async {
    final off = ProviderContainer(
      overrides: [
        homeWidgetsEnabledProvider.overrideWithValue(false),
        homeWidgetStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(off.dispose);
    await off.read(homeWidgetCoordinatorProvider).start();
    expect(store.calls, isEmpty);
    expect(store.onTap, isNull);
  });

  group('A71 fix-check: sign-out keep (same generation)', () {
    late ProviderContainer keep;

    /// The account status read: signed in until [status] says otherwise.
    late Future<bool> Function() readOnly;

    setUp(() {
      readOnly = () async => false;
      keep = ProviderContainer(
        overrides: [
          homeWidgetStoreProvider.overrideWithValue(store),
          homeWidgetInputsProvider.overrideWith((ref) async {
            final generation = ref.watch(profileGenerationProvider);
            final epoch = store.epoch;
            final signedOut = await readOnly();
            return HomeWidgetInputs(
              generation: generation,
              epoch: epoch,
              profileTag: 'tag$generation',
              hidden: false,
              signedOut: signedOut,
            );
          }),
        ],
      );
      addTearDown(keep.dispose);
    });

    Future<void> settleKeep() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      await keep.read(homeWidgetCoordinatorProvider).idle;
    }

    /// Runs a keep sign-out: the clear and hold, inputs re-read with the
    /// old status meanwhile, then the end of the transition with the status
    /// read [after].
    Future<void> signOutKeep(Future<bool> Function() after) async {
      await keep.read(homeWidgetCoordinatorProvider).start();
      await settleKeep();
      expect(store.calls, ['save numbers tag0']);
      keep.read(accountBusyProvider.notifier).publish(busy: true);
      await store.clearAndHold();
      // A read during the transition still sees the old status.
      keep.invalidate(homeWidgetInputsProvider);
      await settleKeep();
      readOnly = after;
      store.release();
      keep.read(accountBusyProvider.notifier).publish(busy: false);
      await settleKeep();
    }

    test('a delayed status read writes nothing until it resolves, then the '
        'signed-out state', () async {
      final status = Completer<bool>();
      await signOutKeep(() => status.future);
      expect(store.calls, ['save numbers tag0', 'clearAndHold']);
      status.complete(true);
      await settleKeep();
      expect(store.calls, [
        'save numbers tag0',
        'clearAndHold',
        'save signedOut tag0',
      ]);
    });

    test('a failing status read writes no numbers', () async {
      await signOutKeep(() async => throw StateError('registry'));
      await settleKeep();
      expect(store.calls, ['save numbers tag0', 'clearAndHold']);
    });
  });
}
