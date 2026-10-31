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

  /// Set the food-name language (D-091).
  Future<SettingsOutcome> setFoodNames(FoodNameLanguage value) =>
      _set(AppSettings.foodNames, value);

  /// Set the persisted theme.
  Future<SettingsOutcome> setTheme(ThemePreference value) =>
      _set(AppSettings.theme, value);

  /// Ask, or apply the weekly check-in automatically (TG-034).
  Future<SettingsOutcome> setCheckInMode(CheckInMode value) =>
      _set(AppSettings.checkInMode, value);

  /// Replace the notification settings (NT-020, A40 D3).
  Future<SettingsOutcome> setNotificationPrefs(NotificationPrefs value) =>
      _set(AppSettings.notificationPrefs, value);

  /// Store [season]'s decision (LC-030/031, TG-060), replacing that Hijri
  /// year's; the other years stay as they are.
  Future<SettingsOutcome> setRamadanSeason(RamadanSeason season) async {
    final current = await store.read(AppSettings.ramadanSeasons);
    return await _set(AppSettings.ramadanSeasons, current.withSeason(season));
  }

  /// Marks [date] "not fasting", or fasting again (LC-034, A41a fix rounds
  /// 1–2): a per-date setting, for a day of a Ramadan with the mode on
  /// (refused outside one), never on the diary's day marks.
  Future<SettingsOutcome> setNotFasting(
    LocalDate date, {
    required bool notFasting,
  }) async {
    final seasons = await store.read(AppSettings.ramadanSeasons);
    if (RamadanCalendar(seasons).onPeriodContaining(date) == null) {
      return const SettingsFailed(SettingsFailure.invalid);
    }
    // Its own key (fix round 2): "fasting" is written explicitly when a
    // not-fasting day is switched back, so the newer decision wins a sync.
    return await _set(
      AppSettings.fastingMark(date),
      notFasting ? FastingMark.notFasting : FastingMark.fasting,
    );
  }

  /// How prayer times are computed (LC-033).
  Future<SettingsOutcome> setPrayerMethod(PrayerMethod value) =>
      _set(AppSettings.prayerMethod, value);

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
