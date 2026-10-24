import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:flutter_riverpod/misc.dart';

/// The quick-add context without its 30-minute timer and resume listener,
/// which a widget test would find pending at its end (the way
/// `todayOverrides` leaves out the midnight timer). It is the same context
/// for the same clock and meals.
Override quickAddContextWithoutTimer() =>
    quickAddContextProvider.overrideWith((ref) {
      final clock = ref.watch(clockProvider);
      final slots = ref.watch(foodSlotsProvider).value ?? const <MealSlot>[];
      final local = EntryTime.now(clock).localDateTime;
      return QuickAddContext(
        now: local,
        weekday: local.date.weekday,
        slotId: const SlotAssigner().assign(
          local.minuteOfDay,
          slots,
          SlotMode.normal,
        ),
        targetDate: local.date,
      );
    });
