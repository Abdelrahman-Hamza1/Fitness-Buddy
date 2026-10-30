import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/application/app_settings.dart';

/// Direct action kind used by undo presentation.
enum SettingsKind {
  /// A single preference changed.
  settingChanged,
}

/// Content-free expected refusal reasons.
enum SettingsFailure {
  /// The value or operation was refused.
  invalid,

  /// An observed row changed.
  changed,

  /// A row no longer exists.
  removed,
}

/// Structured application outcomes, without user values in diagnostics.
sealed class SettingsOutcome {
  const new();
}

/// A direct write recorded in the undo stack.
final class SettingsDone extends SettingsOutcome {
  /// Creates the result.
  const new(this.undoEntryId, this.kind, this.key);

  /// Undo entry identity.
  final String undoEntryId;

  /// Typed label kind.
  final SettingsKind kind;

  /// Permanent setting key, never its value.
  final String key;
}

/// No effective value change; nothing written.
final class SettingsUnchanged extends SettingsOutcome {
  /// Creates the result.
  const new();
}

/// A duplicate action for this key is already in flight.
final class SettingsPending extends SettingsOutcome {
  /// Creates the result.
  const new();
}

/// Expected rejection, mapped for presentation.
final class SettingsFailed extends SettingsOutcome {
  /// Creates the result.
  const new(this.reason);

  /// Content-free refusal reason.
  final SettingsFailure reason;
}

/// A10 D3: use the existing settings writer and undo path unchanged.
final class SettingsActions {
  /// Creates commands over the single writer.
  new({required this.store, required this.undoStack});

  /// Typed store; all writes are change sets.
  final SettingsStore store;

  /// Direct-action undo history, using the injected app clock.
  final UndoStack undoStack;
  final Set<String> _pending = {};

  /// Set display units only.
  Future<SettingsOutcome> setUnitSystem(UnitSystem value) =>
      _set(AppSettings.unitSystem, value);

  /// Set the shared calendar's first day.
  Future<SettingsOutcome> setWeekStart(DayOfWeek value) =>
      _set(AppSettings.weekStart, value);

  /// Set the halal preference.
  // This setter has one value, matching the other typed setting commands.
  // ignore: avoid_positional_boolean_parameters
  Future<SettingsOutcome> setHalal(bool value) =>
      _set(AppSettings.halal, value);

  /// Set the persisted theme.
  Future<SettingsOutcome> setTheme(ThemePreference value) =>
      _set(AppSettings.theme, value);

  /// Ask, or apply the weekly check-in automatically (TG-034).
  Future<SettingsOutcome> setCheckInMode(CheckInMode value) =>
      _set(AppSettings.checkInMode, value);

  /// Set a validated city identity.
  Future<SettingsOutcome> setCity(String value) => AppSettings.isCityId(value)
      ? _set(AppSettings.cityId, value)
      : Future.value(const SettingsFailed(SettingsFailure.invalid));

  /// Unset the city, with undo.
  Future<SettingsOutcome> clearCity() =>
      _set(AppSettings.cityId, null, reset: true);

  SettingsFailed _failure(ChangeFailure failure) =>
      SettingsFailed(switch (failure) {
        VersionConflict() => SettingsFailure.changed,
        RowNotFound() => SettingsFailure.removed,
        _ => SettingsFailure.invalid,
      });

  Future<SettingsOutcome> _set<T>(
    SettingKey<T> key,
    T value, {
    bool reset = false,
  }) async {
    if (!_pending.add(key.name)) return const SettingsPending();
    try {
      final ApplyResult result;
      try {
        if (await store.read(key) == value) return const SettingsUnchanged();
        result = reset
            ? await store.reset(key, origin: Origin.direct)
            : await store.put(key, value, origin: Origin.direct);
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure);
      }
      if (result is Rejected) return _failure(result.failure);
      final applied = result as Applied;
      if (applied.inverse.isEmpty) return const SettingsUnchanged();
      const kind = SettingsKind.settingChanged;
      final undo = undoStack.record(
        applied,
        UndoLabel(kind.name, args: {'key': key.name}),
      );
      return SettingsDone(undo.id, kind, key.name);
    } finally {
      _pending.remove(key.name);
    }
  }
}
