import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/data/weight_tip_store.dart';

/// A [WeightTipStore] in memory, starting at [state]; [writes] counts the
/// stores.
final class MemoryTipStore implements WeightTipStore {
  /// Starts at [state] (never shown by default).
  new([this.state = CadenceTipState.initial]);

  /// What is stored.
  CadenceTipState state;

  /// How often [write] ran.
  int writes = 0;

  @override
  Future<CadenceTipState> read() async => state;

  @override
  Future<void> write(CadenceTipState state) async {
    writes++;
    this.state = state;
  }
}
