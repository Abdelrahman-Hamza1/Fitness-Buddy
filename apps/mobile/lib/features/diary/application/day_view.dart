import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/application/day_slots.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:fb_mobile/features/diary/application/diary_providers.dart';
import 'package:fb_mobile/features/diary/application/diary_view_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_view.g.dart';

/// Raw evidence and the optimistically filtered display model.
final class DayView {
  /// Both are from the same raw emission.
  const new({required this.raw, required this.layout});

  /// Unfiltered storage data, for authoritative decisions.
  final DiaryDay raw;

  /// Visible entries and their totals only.
  final DayLayout layout;
}

/// Auto-disposed by the screen's bounded prefetch subscriptions.
@riverpod
AsyncValue<DayView> dayView(Ref ref, LocalDate date) {
  // Listener callbacks, rather than build, may update other providers.
  ref.listen(dayProvider(date), (_, next) {
    if (next case AsyncData(:final value)) {
      ref.read(diaryActionsControllerProvider.notifier).onRaw(date, value);
      ref.read(diaryViewStateProvider.notifier).onRaw(date, value);
    }
  });
  final raw = ref.watch(dayProvider(date));
  final hidden = ref.watch(diaryActionsControllerProvider).hidden;
  // DY-012: a Ramadan fasting day shows Suhoor / Iftar / Snacks.
  final mode = ref.watch(daySlotsProvider(date)).value?.mode ?? SlotMode.normal;
  return raw.whenData(
    (day) => DayView(
      raw: day,
      layout: DayLayout.build(
        day.slots,
        day.groups,
        day.entries.where(
          (e) => !hidden.any((m) => m.id == e.id && m.version == e.version),
        ),
        mode: mode,
      ),
    ),
  );
}
