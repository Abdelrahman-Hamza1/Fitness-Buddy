import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'today_slide.g.dart';

/// Session-only slide shared by every day page (D-092).
@Riverpod(keepAlive: true)
class TodaySlide extends _$TodaySlide {
  @override
  int build() => 0;

  /// Selects a summary page without persisting or syncing it.
  void select(int index) {
    if (index >= 0 && index < 3) state = index;
  }
}
