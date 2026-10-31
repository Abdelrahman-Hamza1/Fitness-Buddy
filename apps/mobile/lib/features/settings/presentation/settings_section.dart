import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/settings/application/app_settings.dart';
import 'package:fb_mobile/features/settings/application/settings_providers.dart';
import 'package:fb_mobile/features/settings/presentation/settings_feedback.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The setting rows of Me (UX-010, A10 D8, A51 D8): Preferences has units,
// theme, week start, language and energy; Food & meals has halal. Every
// setting is three taps from Today at most. Choices open an option sheet on
// the root navigator; Halal is a switch in the row. Each change is a direct
// action with Undo (UX-030).

/// Units, with the current system as its subtitle.
class UnitsSettingRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final system = ref.watch(unitSystemProvider).value ?? UnitSystem.metric;
    return FbListRow(
      title: context.l10n.settingsUnits,
      subtitle: unitsName(context, system),
      trailing: const Icon(FbIcons.next),
      onTap: () => unawaited(_pickUnits(context, ref, system)),
    );
  }
}

/// Week starts on, with the current day as its subtitle.
class WeekStartSettingRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(weekStartProvider).value ?? DayOfWeek.saturday;
    return FbListRow(
      title: context.l10n.settingsWeekStart,
      subtitle: weekdayName(context, weekStart),
      trailing: const Icon(FbIcons.next),
      onTap: () => unawaited(_pickWeekStart(context, ref, weekStart)),
    );
  }
}

/// Halal food, a switch.
class HalalSettingRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final halal = ref.watch(halalProvider).value ?? true;
    return FbSwitchRow(
      title: l10n.settingsHalal,
      subtitle: l10n.settingsHalalHint,
      value: halal,
      onChanged: (value) => unawaited(_setHalal(context, ref, value)),
    );
  }
}

/// Theme, with the current choice as its subtitle.
class ThemeSettingRow extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme =
        ref.watch(themePreferenceProvider).value ??
        AppSettings.theme.defaultValue;
    return FbListRow(
      title: context.l10n.settingsTheme,
      subtitle: themeName(context, theme),
      trailing: const Icon(FbIcons.next),
      onTap: () => unawaited(_pickTheme(context, ref, theme)),
    );
  }
}

/// "Energy: kcal", information only (LC-012: kJ is a later option).
class EnergySettingRow extends StatelessWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context) => FbListRow(
    title: context.l10n.settingsEnergy,
    trailing: Text(context.l10n.diaryUnitKcal),
  );
}

/// "Language: English", information only (D-080: English UI in R1).
class LanguageSettingRow extends StatelessWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context) => FbListRow(
    title: context.l10n.settingsLanguage,
    trailing: Text(context.l10n.settingsLanguageEnglish),
  );
}

/// The name of [system] ("Metric").
String unitsName(BuildContext context, UnitSystem system) => switch (system) {
  UnitSystem.metric => context.l10n.settingsUnitsMetric,
  UnitSystem.imperial => context.l10n.settingsUnitsImperial,
};

/// The name of [theme] ("System").
String themeName(BuildContext context, ThemePreference theme) =>
    switch (theme) {
      ThemePreference.system => context.l10n.settingsThemeSystem,
      ThemePreference.light => context.l10n.settingsThemeLight,
      ThemePreference.dark => context.l10n.settingsThemeDark,
    };

Future<void> _pickUnits(
  BuildContext context,
  WidgetRef ref,
  UnitSystem current,
) async {
  final l10n = context.l10n;
  final host = Navigator.of(context, rootNavigator: true).context;
  final picked = await showFbOptionSheet<UnitSystem>(
    context,
    title: l10n.settingsUnits,
    selected: current,
    options: [
      FbOption(
        value: UnitSystem.metric,
        label: l10n.settingsUnitsMetric,
        subtitle: l10n.settingsUnitsMetricHint,
      ),
      FbOption(
        value: UnitSystem.imperial,
        label: l10n.settingsUnitsImperial,
        subtitle: l10n.settingsUnitsImperialHint,
      ),
    ],
  );
  if (picked == null || !host.mounted) return;
  final outcome = await ref.read(settingsActionsProvider).setUnitSystem(picked);
  if (!host.mounted) return;
  reportSettingsOutcome(
    host,
    outcome,
    () => picked == UnitSystem.imperial
        ? host.l10n.settingsUnitsSetImperial
        : host.l10n.settingsUnitsSetMetric,
  );
}

Future<void> _pickWeekStart(
  BuildContext context,
  WidgetRef ref,
  DayOfWeek current,
) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final picked = await showFbOptionSheet<DayOfWeek>(
    context,
    title: context.l10n.settingsWeekStart,
    selected: current,
    options: [
      for (final day in DayOfWeek.values)
        FbOption(value: day, label: weekdayName(context, day)),
    ],
  );
  if (picked == null || !host.mounted) return;
  final outcome = await ref.read(settingsActionsProvider).setWeekStart(picked);
  if (!host.mounted) return;
  reportSettingsOutcome(
    host,
    outcome,
    () => host.l10n.settingsWeekStartSet(weekdayName(host, picked)),
  );
}

Future<void> _setHalal(BuildContext context, WidgetRef ref, bool value) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await ref.read(settingsActionsProvider).setHalal(value);
  if (!host.mounted) return;
  reportSettingsOutcome(
    host,
    outcome,
    () => value ? host.l10n.settingsHalalSetOn : host.l10n.settingsHalalSetOff,
  );
}

Future<void> _pickTheme(
  BuildContext context,
  WidgetRef ref,
  ThemePreference current,
) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final picked = await showFbOptionSheet<ThemePreference>(
    context,
    title: context.l10n.settingsTheme,
    selected: current,
    options: [
      for (final theme in ThemePreference.values)
        FbOption(value: theme, label: themeName(context, theme)),
    ],
  );
  if (picked == null || !host.mounted) return;
  await applyTheme(host, ref, picked);
}

/// Sets the theme with Undo feedback (UX-040, UX-030): the one path for the
/// Theme row and the design preview's switch. [context] must be mounted now.
Future<void> applyTheme(
  BuildContext context,
  WidgetRef ref,
  ThemePreference theme,
) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await ref.read(settingsActionsProvider).setTheme(theme);
  if (!host.mounted) return;
  reportSettingsOutcome(
    host,
    outcome,
    () => host.l10n.settingsThemeSet(themeName(host, theme)),
  );
}
