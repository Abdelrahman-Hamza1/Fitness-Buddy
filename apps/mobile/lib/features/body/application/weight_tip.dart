import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/data/weight_tip_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weight_tip.g.dart';

/// The weight card's suggestion state (WB-012, A14 D10). A preference that
/// can't be read or written never blocks the card: it reads as never shown,
/// and a failed write is dropped (the suggestion may show once more).
@Riverpod(keepAlive: true)
class WeightTipController extends _$WeightTipController {
  @override
  Future<CadenceTipState> build() async {
    try {
      return await ref.read(weightTipStoreProvider).read();
    } on Object {
      return CadenceTipState.initial;
    }
  }

  /// The suggestion showed on [today] (called after the frame that shows
  /// it, never during a build).
  Future<void> markShown(LocalDate today) =>
      _save((state) => state.shownToday(today));

  /// "Got it".
  Future<void> dismiss() => _save((state) => state.dismiss());

  Future<void> _save(
    CadenceTipState Function(CadenceTipState state) change,
  ) async {
    final current = await future;
    final next = change(current);
    if (next == current) return;
    state = AsyncData(next);
    try {
      await ref.read(weightTipStoreProvider).write(next);
    } on Object {
      // A display preference: keep the in-memory state.
    }
  }
}
