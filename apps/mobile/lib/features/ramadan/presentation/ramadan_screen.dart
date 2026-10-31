import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ramadanTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s5),
        children: [
          switch (status) {
            AsyncData(value: final s?) => _Season(status: s),
            AsyncData() => Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: Text(l10n.ramadanOutsideTable, style: FbType.body),
            ),
            AsyncError() => Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: FbInlineBanner(
                kind: FbInlineBannerKind.error,
                message: l10n.ramadanLoadFailed,
                actionLabel: l10n.mealTimesTryAgain,
                onAction: () => ref.invalidate(ramadanSettingsProvider),
              ),
            ),
            _ => const FbSkeleton.card(),
          },
          const _PrayerTimes(),
        ],
      ),
    );
  }
}

class _Season extends ConsumerWidget {
  const new({required this.status});

  final RamadanStatus status;

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    RamadanSeason season,
  ) async {
    final host = Navigator.of(context, rootNavigator: true).context;
    final outcome = await ref
        .read(settingsActionsProvider)
        .setRamadanSeason(season);
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
      start
          ? season.copyWith(startShift: picked)
          : season.copyWith(endShift: picked),
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
      season.copyWith(maintain: picked, targetsAnswered: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final period = status.period;
    final season =
        status.season ?? RamadanSeason(hijriYear: period.hijriYear, on: false);
    final on = season.on;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FbSectionHeader(title: l10n.ramadanSeasonHeader(period.hijriYear)),
        FbSwitchRow(
          key: const ValueKey('ramadan-mode'),
          title: l10n.ramadanMode,
          subtitle: l10n.ramadanExpected(
            ramadanDateText(context, period.start),
            ramadanDateText(context, period.end),
          ),
          value: on,
          onChanged: (value) =>
              unawaited(_save(context, ref, season.copyWith(on: value))),
        ),
        if (on) ...[
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
        FbListRow(
          key: const ValueKey('ramadan-meal-times'),
          title: l10n.ramadanMealTimes,
          trailing: const Icon(FbIcons.next),
          onTap: () => ref
              .read(appNavigatorProvider)
              .push(const RamadanMealSlotsRoute()),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            FbSpace.s4,
            FbSpace.s2,
            FbSpace.s4,
            FbSpace.s2,
          ),
          child: Text(
            l10n.ramadanCalendarNote,
            style: FbType.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
    final city = ref.watch(selectedCityProvider).value;
    final method =
        ref.watch(prayerMethodProvider).value ??
        AppSettings.prayerMethod.defaultValue;
    final today = ref.watch(todayProvider).value;
    final times = today == null
        ? null
        : ref.watch(prayerTimesProvider(today)).value;
    final navigator = ref.read(appNavigatorProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FbSectionHeader(title: l10n.ramadanPrayerTimes),
        FbListRow(
          key: const ValueKey('ramadan-city'),
          title: l10n.settingsCity,
          subtitle: city == null ? l10n.ramadanNoCity : cityLabel(l10n, city),
          trailing: const Icon(FbIcons.next),
          onTap: () => navigator.push(const CityPickerRoute()),
        ),
        if (times != null)
          FbListRow(
            key: const ValueKey('ramadan-today-times'),
            title: l10n.ramadanTodayTimes,
            subtitle: l10n.ramadanFajrMaghrib(
              ramadanTimeText(context, times.cityFajrMinute),
              ramadanTimeText(context, times.cityMaghribMinute),
            ),
          ),
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
