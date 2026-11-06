import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/ui/load_states.dart';
import 'package:fb_mobile/core/ui/settings_page.dart';
import 'package:fb_mobile/features/ramadan/application/ramadan_providers.dart';
import 'package:fb_mobile/features/ramadan/presentation/ramadan_text.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Ramadan (LC-030–034, TG-060, A41a): Ramadan mode for the
/// current or next Ramadan, its ±1-day shifts (moon sighting), the Ramadan
/// meal times, the Ramadan targets, and prayer times (the chosen city and
/// the method). Every change is a direct action with Undo.
class RamadanScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(ramadanStatusProvider);
    // The same settings-page layout as the rest of Me (A65 M4).
    return SettingsPage(
      title: l10n.ramadanTitle,
      children: [
        switch (status) {
          AsyncData(value: final s?) => _Season(status: s),
          // Past the calendar table: a designed empty state (A65 N8).
          AsyncData() => FbEmptyState(
            key: const ValueKey('ramadan-outside-table'),
            icon: FbIcons.ramadan,
            title: l10n.ramadanTitle,
            message: l10n.ramadanOutsideTable,
          ),
          AsyncError() => LoadFailedView(
            key: const ValueKey('ramadan-load-failed'),
            message: l10n.ramadanLoadFailed,
            onRetry: () => ref.invalidate(ramadanSettingsProvider),
          ),
          // Shaped like the rows that replace it (A57 A14).
          _ => const LoadingRows(key: ValueKey('ramadan-loading'), count: 3),
        },
        settingsGroupGap,
        const _PrayerTimes(),
      ],
    );
  }
}

class _Season extends ConsumerWidget {
  const new({required this.status});

  final RamadanStatus status;

  /// Writes one field of the season ([change] of the stored season, A63
  /// D17), so quick edits of different fields all land.
  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    int hijriYear,
    RamadanSeason Function(RamadanSeason current) change,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(settingsActionsProvider)
        .updateRamadanSeason(hijriYear, change);
    if (!host.mounted) return;
    reportSettingsOutcome(host, outcome, () => host.l10n.ramadanSaved);
  }

  Future<void> _pickShift(
    BuildContext context,
    WidgetRef ref,
    RamadanSeason season, {
    required bool start,
  }) async {
    final l10n = context.l10n;
    final current = start ? season.startShift : season.endShift;
    final base = start
        ? status.period.start.plusDays(-season.startShift)
        : status.period.end.plusDays(-season.endShift);
    final picked = await showFbOptionSheet<int>(
      context,
      title: start ? l10n.ramadanFirstDay : l10n.ramadanLastDay,
      options: [
        for (final (shift, label) in [
          (-1, l10n.ramadanShiftEarlier),
          (0, l10n.ramadanShiftExpected),
          (1, l10n.ramadanShiftLater),
        ])
          FbOption(
            value: shift,
            label: ramadanDateText(context, base.plusDays(shift)),
            subtitle: label,
          ),
      ],
      selected: current,
    );
    if (picked == null || picked == current || !context.mounted) return;
    await _save(
      context,
      ref,
      season.hijriYear,
      start
          ? (s) => s.copyWith(startShift: picked)
          : (s) => s.copyWith(endShift: picked),
    );
  }

  Future<void> _pickTargets(
    BuildContext context,
    WidgetRef ref,
    RamadanSeason season,
  ) async {
    final l10n = context.l10n;
    final picked = await showFbOptionSheet<bool>(
      context,
      title: l10n.ramadanTargets,
      options: [
        FbOption(value: false, label: l10n.ramadanTargetsKeep),
        FbOption(
          value: true,
          label: l10n.ramadanTargetsMaintain,
          subtitle: l10n.ramadanTargetsMaintainHint,
        ),
      ],
      selected: season.maintain,
    );
    if (picked == null || !context.mounted) return;
    await _save(
      context,
      ref,
      season.hijriYear,
      (s) => s.copyWith(maintain: picked, targetsAnswered: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final period = status.period;
    final season =
        status.season ?? RamadanSeason(hijriYear: period.hijriYear, on: false);
    final on = season.on;
    return FbRowGroup(
      title: l10n.ramadanSeasonHeader(period.hijriYear),
      note: l10n.ramadanCalendarNote,
      children: [
        FbSwitchRow(
          key: const ValueKey('ramadan-mode'),
          title: l10n.ramadanMode,
          subtitle: l10n.ramadanExpected(
            ramadanDateText(context, period.start),
            ramadanDateText(context, period.end),
          ),
          value: on,
          onChanged: (value) => unawaited(
            _save(context, ref, season.hijriYear, (s) => s.copyWith(on: value)),
          ),
        ),
        // The season's rows grow in and out under the switch (A57 A14).
        FbReveal(
          visible: on,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FbListRow(
                key: const ValueKey('ramadan-first-day'),
                title: l10n.ramadanFirstDay,
                subtitle: ramadanDateText(context, period.start),
                trailing: const Icon(FbIcons.next),
                onTap: () =>
                    unawaited(_pickShift(context, ref, season, start: true)),
              ),
              FbListRow(
                key: const ValueKey('ramadan-last-day'),
                title: l10n.ramadanLastDay,
                subtitle: ramadanDateText(context, period.end),
                trailing: const Icon(FbIcons.next),
                onTap: () =>
                    unawaited(_pickShift(context, ref, season, start: false)),
              ),
              FbListRow(
                key: const ValueKey('ramadan-targets'),
                title: l10n.ramadanTargets,
                subtitle: season.maintain
                    ? l10n.ramadanTargetsMaintain
                    : l10n.ramadanTargetsKeep,
                trailing: const Icon(FbIcons.next),
                onTap: () => unawaited(_pickTargets(context, ref, season)),
              ),
            ],
          ),
        ),
        FbListRow(
          key: const ValueKey('ramadan-meal-times'),
          title: l10n.ramadanMealTimes,
          trailing: const Icon(FbIcons.next),
          onTap: () => ref
              .read(appNavigatorProvider)
              .push(const RamadanMealSlotsRoute()),
        ),
      ],
    );
  }
}

class _PrayerTimes extends ConsumerWidget {
  const new();

  Future<void> _pickMethod(
    BuildContext context,
    WidgetRef ref,
    PrayerMethod current,
  ) async {
    final l10n = context.l10n;
    final host = Navigator.of(context, rootNavigator: true).context;
    final picked = await showFbOptionSheet<PrayerMethod>(
      context,
      title: l10n.ramadanPrayerMethod,
      options: [
        for (final m in PrayerMethod.values)
          FbOption(value: m, label: prayerMethodName(l10n, m)),
      ],
      selected: current,
    );
    if (picked == null || !context.mounted) return;
    final outcome = await ref
        .read(settingsActionsProvider)
        .setPrayerMethod(picked);
    if (!host.mounted) return;
    reportSettingsOutcome(host, outcome, () => host.l10n.ramadanSaved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cityAsync = ref.watch(selectedCityProvider);
    final city = cityAsync.value;
    // A failed read is not "no city" (audit minor): say so, with Try again.
    final cityFailed = cityAsync.hasError && !cityAsync.hasValue;
    final method =
        ref.watch(prayerMethodProvider).value ??
        AppSettings.prayerMethod.defaultValue;
    final today = ref.watch(todayProvider).value;
    final times = today == null ? null : ref.watch(prayerTimesProvider(today));
    final navigator = ref.read(appNavigatorProvider);
    return FbRowGroup(
      title: l10n.ramadanPrayerTimes,
      children: [
        FbListRow(
          key: const ValueKey('ramadan-city'),
          title: l10n.settingsCity,
          subtitle: city != null
              ? cityLabel(l10n, city)
              : cityFailed
              ? l10n.ramadanCityLoadFailed
              : cityAsync.isLoading
              ? null
              : l10n.ramadanNoCity,
          trailing: cityFailed ? null : const Icon(FbIcons.next),
          // Under the text at large sizes (A65 m18).
          trailingAction: cityFailed
              ? FbButton.text(
                  key: const ValueKey('ramadan-city-retry'),
                  label: l10n.commonTryAgain,
                  onPressed: () => ref.invalidate(selectedCityProvider),
                )
              : null,
          onTap: () => navigator.push(const CityPickerRoute()),
        ),
        // Today's times with a chosen city (A57 A14): a row-shaped
        // placeholder while they load, a retry when they fail, and a plain
        // word when the city has none today (a polar day).
        if (city != null)
          switch (times) {
            AsyncValue(hasValue: true, :final value) => switch (value) {
              final t? => FbListRow(
                key: const ValueKey('ramadan-today-times'),
                title: l10n.ramadanTodayTimes,
                subtitle: l10n.ramadanFajrMaghrib(
                  ramadanTimeText(context, t.cityFajrMinute),
                  ramadanTimeText(context, t.cityMaghribMinute),
                ),
              ),
              null => FbListRow(
                key: const ValueKey('ramadan-today-times-none'),
                title: l10n.ramadanTodayTimes,
                subtitle: l10n.ramadanTimesNone,
              ),
            },
            AsyncError() => FbListRow(
              key: const ValueKey('ramadan-today-times-failed'),
              title: l10n.ramadanTodayTimes,
              subtitle: l10n.ramadanTimesFailed,
              onTap: () => ref.invalidate(prayerTimesProvider(today!)),
            ),
            _ => FbSkeleton.row(
              key: const ValueKey('ramadan-today-times-loading'),
            ),
          },
        FbListRow(
          key: const ValueKey('ramadan-method'),
          title: l10n.ramadanPrayerMethod,
          subtitle: prayerMethodName(l10n, method),
          trailing: const Icon(FbIcons.next),
          onTap: () => unawaited(_pickMethod(context, ref, method)),
        ),
        FbListRow(
          key: const ValueKey('ramadan-reminders'),
          title: l10n.ramadanReminders,
          subtitle: l10n.ramadanRemindersHint,
          trailing: const Icon(FbIcons.next),
          onTap: () => navigator.push(const NotificationSettingsRoute()),
        ),
      ],
    );
  }
}
