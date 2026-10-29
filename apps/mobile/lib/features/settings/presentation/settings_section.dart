import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/settings/application/app_settings.dart';
import 'package:fb_mobile/features/settings/application/settings_providers.dart';
import 'package:fb_mobile/features/settings/presentation/settings_feedback.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Settings section of the Me tab (UX-010, A10 D8): Units, Week starts
/// on, Halal food, Theme, City and the "Energy: kcal" info row (LC-012).
/// Every setting is two taps from Today. Choices open an option sheet on the
/// root navigator; Halal is a switch in the row. Each change is a direct
/// action with Undo (UX-030).
class SettingsSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final system = ref.watch(unitSystemProvider).value ?? UnitSystem.metric;
    final weekStart = ref.watch(weekStartProvider).value ?? DayOfWeek.saturday;
    final halal = ref.watch(halalProvider).value ?? true;
    final theme =
        ref.watch(themePreferenceProvider).value ??
        AppSettings.theme.defaultValue;
    final city = ref.watch(selectedCityProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FbSectionHeader(title: l10n.meSectionSettings),
        FbListRow(
          title: l10n.settingsMealTimes,
          trailing: const Icon(FbIcons.next),
          onTap: () =>
              ref.read(appNavigatorProvider).push(const MealSlotsRoute()),
        ),
        FbListRow(
          title: l10n.settingsUnits,
          subtitle: _unitsName(context, system),
          trailing: const Icon(FbIcons.next),
          onTap: () => unawaited(_pickUnits(context, ref, system)),
        ),
        FbListRow(
          title: l10n.settingsWeekStart,
          subtitle: weekdayName(context, weekStart),
          trailing: const Icon(FbIcons.next),
          onTap: () => unawaited(_pickWeekStart(context, ref, weekStart)),
        ),
        FbSwitchRow(
          title: l10n.settingsHalal,
          value: halal,
          onChanged: (value) => unawaited(_setHalal(context, ref, value)),
        ),
        FbListRow(
          title: l10n.settingsTheme,
          subtitle: _themeName(context, theme),
          trailing: const Icon(FbIcons.next),
          onTap: () => unawaited(_pickTheme(context, ref, theme)),
        ),
        FbListRow(
          title: l10n.settingsCity,
          subtitle: city == null
              ? l10n.settingsCityNotSet
              : cityLabel(l10n, city),
          trailing: const Icon(FbIcons.next),
          onTap: () =>
              ref.read(appNavigatorProvider).push(const CityPickerRoute()),
        ),
        // Information only (LC-012: kJ is a later option), so not tappable.
        FbListRow(
          title: l10n.settingsEnergy,
          trailing: Text(l10n.diaryUnitKcal),
        ),
      ],
    );
  }
}

String _unitsName(BuildContext context, UnitSystem system) => switch (system) {
  UnitSystem.metric => context.l10n.settingsUnitsMetric,
  UnitSystem.imperial => context.l10n.settingsUnitsImperial,
};

String _themeName(BuildContext context, ThemePreference theme) =>
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
        FbOption(value: theme, label: _themeName(context, theme)),
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
    () => host.l10n.settingsThemeSet(_themeName(host, theme)),
  );
}
