import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'today_date.g.dart';

/// Local today, refreshed one second after midnight; invalidate on resume.
@Riverpod(keepAlive: true)
Stream<LocalDate> today(Ref ref) {
  final clock = ref.watch(clockProvider);
  return Stream.multi((listener) {
    Timer? timer;
    void emit() {
      final date = EntryTime.now(clock).localDate;
      listener.add(date);
      timer = Timer(
        nextDayStartUtc(
          date,
          clock,
        ).add(const Duration(seconds: 1)).difference(clock.nowUtc()),
        emit,
      );
    }

    emit();
    listener.onCancel = () => timer?.cancel();
  });
}
