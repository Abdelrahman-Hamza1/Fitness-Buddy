import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'weight_tip_store.g.dart';

/// Where the weight card's suggestion state lives (A14 D10): a display
/// preference, outside the database, the write path and sync.
abstract interface class WeightTipStore {
  /// The stored state; [CadenceTipState.initial] when there is none or it
  /// can't be read.
  Future<CadenceTipState> read();

  /// Stores [state].
  Future<void> write(CadenceTipState state);
}

/// [WeightTipStore] in shared preferences under
/// `PreferenceKeys.weightCadenceTip`, as JSON
/// `{"shownOn": "2026-10-17", "dismissed": false}`.
final class PreferencesWeightTipStore implements WeightTipStore {
  /// Over the app's preferences.
  const new(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<CadenceTipState> read() async {
    final text = await _preferences.getString(PreferenceKeys.weightCadenceTip);
    if (text == null) return CadenceTipState.initial;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, Object?>) return CadenceTipState.initial;
      final shownOn = json['shownOn'];
      return CadenceTipState(
        shownOn: shownOn is String ? LocalDate.tryParse(shownOn) : null,
        dismissed: json['dismissed'] == true,
      );
    } on FormatException {
      return CadenceTipState.initial;
    }
  }

  @override
  Future<void> write(CadenceTipState state) => _preferences.setString(
    PreferenceKeys.weightCadenceTip,
    jsonEncode({
      'shownOn': state.shownOn?.toString(),
      'dismissed': state.dismissed,
    }),
  );
}

/// The app's [WeightTipStore].
@Riverpod(keepAlive: true)
WeightTipStore weightTipStore(Ref ref) =>
    PreferencesWeightTipStore(ref.watch(sharedPreferencesProvider));
