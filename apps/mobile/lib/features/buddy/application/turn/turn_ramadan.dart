import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/data/buddy_turn_context_reader.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Today's Ramadan state for a Buddy turn (A68 D7): whether [today] is a
/// fasting day, its fajr and maghrib on the device clock (the chosen city's
/// prayer times; none without a city) and the slots in use. Local only.
Future<TurnRamadan> turnRamadan(Ref ref, LocalDate today) async {
  final calendar = await _read(ref, ramadanCalendarProvider.future);
  final fasting = calendar.isFastingDay(today);
  final times = fasting
      ? await _read(ref, prayerTimesProvider(today).future)
      : null;
  return (
    fasting: fasting,
    fajr: times == null ? null : _hhmm(times.fajrMinute),
    maghrib: times == null ? null : _hhmm(times.maghribMinute),
    slots: calendar.slotModeOn(today),
  );
}

String _hhmm(int minute) =>
    '${(minute ~/ 60 % 24).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

/// [provider]'s value, kept alive until it has one.
Future<T> _read<T>(Ref ref, ProviderListenable<Future<T>> provider) async {
  final sub = ref.listen(provider, (_, _) {});
  try {
    return await sub.read();
  } finally {
    sub.close();
  }
}
