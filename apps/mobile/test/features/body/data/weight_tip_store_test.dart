import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/features/body/application/weight_tip.dart';
import 'package:fb_mobile/features/body/data/weight_tip_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// A store that fails every read and write.
final class _BrokenStore implements WeightTipStore {
  @override
  Future<CadenceTipState> read() async => throw StateError('read');

  @override
  Future<void> write(CadenceTipState state) async => throw StateError('write');
}

void main() {
  late SharedPreferencesAsync preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
  });

  test('WB-012 the suggestion state round-trips under '
      'fb.weight_cadence_tip.v1 (PA10)', () async {
    expect(PreferenceKeys.weightCadenceTip, 'fb.weight_cadence_tip.v1');
    final store = PreferencesWeightTipStore(preferences);
    expect(await store.read(), CadenceTipState.initial);
    final state = CadenceTipState(
      shownOn: LocalDate(2026, 10, 17),
      dismissed: true,
    );
    await store.write(state);
    expect(await store.read(), state);
    expect(
      await preferences.getString('fb.weight_cadence_tip.v1'),
      '{"shownOn":"2026-10-17","dismissed":true}',
    );
  });

  test('an unreadable stored value reads as never shown', () async {
    final store = PreferencesWeightTipStore(preferences);
    for (final text in ['not json', '[1]', '{"shownOn":"17/10"}']) {
      await preferences.setString(PreferenceKeys.weightCadenceTip, text);
      expect(await store.read(), CadenceTipState.initial, reason: text);
    }
  });

  test('WeightTipController records the day once and Got it; a broken '
      'store never blocks it', () async {
    final store = PreferencesWeightTipStore(preferences);
    final container = ProviderContainer.test(
      overrides: [weightTipStoreProvider.overrideWithValue(store)],
    );
    final today = LocalDate(2026, 10, 17);
    final controller = container.read(weightTipControllerProvider.notifier);
    expect(
      await container.read(weightTipControllerProvider.future),
      CadenceTipState.initial,
    );
    await controller.markShown(today);
    await controller.markShown(today);
    expect(await store.read(), CadenceTipState(shownOn: today));
    await controller.dismiss();
    expect(
      await store.read(),
      CadenceTipState(shownOn: today, dismissed: true),
    );

    final broken = ProviderContainer.test(
      overrides: [weightTipStoreProvider.overrideWithValue(_BrokenStore())],
    );
    expect(
      await broken.read(weightTipControllerProvider.future),
      CadenceTipState.initial,
    );
    await broken.read(weightTipControllerProvider.notifier).markShown(today);
    expect(
      broken.read(weightTipControllerProvider).value,
      CadenceTipState(shownOn: today),
    );
  });
}
