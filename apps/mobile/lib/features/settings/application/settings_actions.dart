import 'dart:async';

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

  /// Local storage failed (a read or write threw, A63 D20); nothing was
  /// changed by this command.
  storage,
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

/// A57 A71 (D22): a later change to the same key arrived while this one
/// waited behind a write in flight; the later one carries this intent on
/// (it is folded into that write), so nothing is dropped.
final class SettingsQueued extends SettingsOutcome {
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

  /// A57 A71 (D22): the latest intent per key that arrived while a write for
  /// it was in flight. Intents are changes of the current value, so plain
  /// sets end in the latest value and edits of one part of a value (a
  /// notification type, a Ramadan year) compose instead of overwriting each
  /// other.
  final Map<String, _Queued<Object?>> _queued = {};

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

  /// Change part of the notification settings, applied to the stored value
  /// when the write runs (A57 A71): rapid edits of different reminders all
  /// land.
  Future<SettingsOutcome> updateNotificationPrefs(
    NotificationPrefs Function(NotificationPrefs current) change,
  ) => _change(AppSettings.notificationPrefs, change);

  /// Store [season]'s decision (LC-030/031, TG-060), replacing that Hijri
  /// year's; the other years stay as they are.
  Future<SettingsOutcome> setRamadanSeason(RamadanSeason season) => _change(
    AppSettings.ramadanSeasons,
    (current) => current.withSeason(season),
  );

  /// Change one Ramadan season field by field (A63 D17): [change] runs on
  /// the **stored** season of [hijriYear] (a new one when none) when the
  /// write runs, so two quick edits (first day, then last day) both land
  /// instead of the second restoring the first from an older copy.
  Future<SettingsOutcome> updateRamadanSeason(
    int hijriYear,
    RamadanSeason Function(RamadanSeason current) change,
  ) => _change(
    AppSettings.ramadanSeasons,
    (current) => current.withSeason(
      change(
        current[hijriYear] ?? RamadanSeason(hijriYear: hijriYear, on: false),
      ),
    ),
  );

  /// Marks [date] "not fasting", or fasting again (LC-034, A41a fix rounds
  /// 1–2): a per-date setting, for a day of a Ramadan with the mode on
  /// (refused outside one), never on the diary's day marks.
  Future<SettingsOutcome> setNotFasting(
    LocalDate date, {
    required bool notFasting,
  }) => _guarded(() async {
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
  });

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

  /// Runs a command's own reads (A63 PA6): a refusal keeps its own
  /// mapping, any other storage exception becomes [SettingsFailure.storage],
  /// never an escaped error. No user value goes into the outcome.
  Future<SettingsOutcome> _guarded(
    Future<SettingsOutcome> Function() command,
  ) async {
    try {
      return await command();
    } on ChangeRejected catch (rejection) {
      return _failure(rejection.failure);
    } on Exception {
      return const SettingsFailed(SettingsFailure.storage);
    }
  }

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
  }) => _change(key, (_) => value, reset: reset);

  /// Runs [change] on [key] now, or, with a write for [key] in flight, queues
  /// it behind that write (D22). A newer queued change folds in the older
  /// one, whose caller gets [SettingsQueued]; the newest caller gets the
  /// outcome of the write that carries them.
  Future<SettingsOutcome> _change<T>(
    SettingKey<T> key,
    T Function(T current) change, {
    bool reset = false,
  }) {
    if (!_pending.contains(key.name)) return _run(key, change, reset: reset);
    final earlier = _queued[key.name] as _Queued<T>?;
    final T Function(T) combined;
    if (earlier == null) {
      combined = change;
    } else {
      earlier.done.complete(const SettingsQueued());
      final before = earlier.change;
      combined = (current) => change(before(current));
    }
    final queued = _Queued<T>(combined, reset: reset);
    _queued[key.name] = queued;
    return queued.done.future;
  }

  Future<SettingsOutcome> _run<T>(
    SettingKey<T> key,
    T Function(T current) change, {
    required bool reset,
  }) async {
    _pending.add(key.name);
    try {
      return await _write(key, change, reset: reset);
    } finally {
      _pending.remove(key.name);
      // The latest intent goes through the same writer path, with its own
      // change set and undo entry, whatever happened to this write.
      if (_queued.remove(key.name) case final _Queued<T> next) {
        unawaited(
          _run(
            key,
            next.change,
            reset: next.reset,
          ).then(next.done.complete, onError: next.done.completeError),
        );
      }
    }
  }

  Future<SettingsOutcome> _write<T>(
    SettingKey<T> key,
    T Function(T current) change, {
    required bool reset,
  }) async {
    final ApplyResult result;
    try {
      final current = await store.read(key);
      final value = change(current);
      if (current == value) return const SettingsUnchanged();
      result = reset
          ? await store.reset(key, origin: Origin.direct)
          : await store.put(key, value, origin: Origin.direct);
    } on ChangeRejected catch (rejection) {
      return _failure(rejection.failure);
    } on Exception {
      // A read, put or reset threw (A63 D20): reported, never escaped.
      return const SettingsFailed(SettingsFailure.storage);
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
  }
}

/// A change waiting behind a write in flight for the same key.
final class _Queued<T> {
  new(this.change, {required this.reset});

  final T Function(T current) change;
  final bool reset;
  final Completer<SettingsOutcome> done = Completer();
}
