import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/l10n/time_format.dart';
import 'package:fb_mobile/core/ui/load_states.dart';
import 'package:fb_mobile/core/ui/settings_page.dart';
import 'package:fb_mobile/features/notifications/application/notification_coordinator.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Me › Notifications (NT-020, NT-021, A40 D10): the master switch, quiet
/// hours, and each reminder's switch and time (the weigh-in also its day),
/// with `spec/17`'s defaults. A banner says when Android blocks the app's
/// notifications, with Allow (A40 D8). Each change is a direct action with
/// Undo (UX-030).
class NotificationSettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stored = ref.watch(notificationPrefsProvider);
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final weekStart =
        ref.watch(weekStartProvider).value ??
        AppSettings.weekStart.defaultValue;
    // Wait for the stored choices (A57 A13): defaults shown first and then
    // replaced would flip switches under the finger.
    if (!stored.hasValue && !stored.hasError) {
      return SettingsPage(
        title: l10n.notifSettingsTitle,
        children: const [LoadingRows(key: ValueKey('notif-loading'), count: 6)],
      );
    }
    // A failed read is not "the defaults" (audit major 4): say so with Try
    // again, and offer controls only for choices that were read.
    if (!stored.hasValue) {
      return SettingsPage(
        title: l10n.notifSettingsTitle,
        children: [
          LoadFailedView(
            key: const ValueKey('notif-load-failed'),
            message: l10n.notifLoadFailed,
            onRetry: () => ref.invalidate(notificationPrefsProvider),
          ),
        ],
      );
    }
    final prefs = stored.requireValue;
    List<Widget> groups(Iterable<NotificationType> types) => [
      for (final type in types) ...[
        settingsGroupGap,
        FbRowGroup(children: _typeRows(context, ref, prefs, type, weekStart)),
      ],
    ];
    // The same settings-page layout as the rest of Me (A65 M4): the master
    // switch and quiet hours in one card, then one card per reminder with
    // its time and day inside it (m4), the Ramadan pair apart with a note.
    return SettingsPage(
      title: l10n.notifSettingsTitle,
      children: [
        if (!allowed)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s3),
            child: FbInlineBanner(
              key: const ValueKey('notif-permission'),
              kind: FbInlineBannerKind.info,
              message: l10n.notifPermissionOff,
              actionLabel: l10n.notifPermissionAllow,
              onAction: () =>
                  unawaited(ref.read(notificationPermissionProvider).request()),
            ),
          ),
        FbRowGroup(
          children: [
            FbSwitchRow(
              key: const ValueKey('notif-master'),
              title: l10n.notifMaster,
              subtitle: l10n.notifMasterHint,
              value: prefs.enabled,
              onChanged: (on) => unawaited(
                _save(context, ref, (p) => p.copyWith(enabled: on)),
              ),
            ),
            // Everything under the master switch grows in and out with it
            // (A57 A13); the switch itself stays put.
            FbReveal(
              visible: prefs.enabled,
              child: FbListRow(
                key: const ValueKey('notif-quiet'),
                title: l10n.notifQuietHours,
                subtitle: l10n.notifQuietRange(
                  _time(context, prefs.quietStart),
                  _time(context, prefs.quietEnd),
                ),
                trailing: const Icon(FbIcons.next),
                onTap: () => unawaited(_pickQuiet(context, ref, prefs)),
              ),
            ),
          ],
        ),
        FbReveal(
          visible: prefs.enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FbSectionHeader(title: l10n.notifSectionTypes),
              ...groups(_everyDay),
              FbSectionHeader(title: l10n.notifSectionRamadan),
              ...groups(_ramadan),
              Padding(
                key: const ValueKey('notif-ramadan-note'),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  FbSpace.s4,
                  FbSpace.s2,
                  FbSpace.s4,
                  0,
                ),
                child: Text(
                  l10n.notifRamadanNote,
                  style: FbType.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The Ramadan reminders, shown apart (A65 m4): they only fire on Ramadan
  /// days with Ramadan mode on and a city.
  static const List<NotificationType> _ramadan = [
    NotificationType.suhoor,
    NotificationType.iftar,
  ];

  static Iterable<NotificationType> get _everyDay =>
      NotificationType.values.where((t) => !_ramadan.contains(t));

  List<Widget> _typeRows(
    BuildContext context,
    WidgetRef ref,
    NotificationPrefs prefs,
    NotificationType type,
    DayOfWeek weekStart,
  ) {
    final l10n = context.l10n;
    final setting = prefs.of(type);
    final (name, hint) = _names(l10n, type);
    return [
      FbSwitchRow(
        key: ValueKey('notif-${type.name}'),
        title: name,
        subtitle: hint,
        value: setting.enabled,
        onChanged: (on) => unawaited(
          _save(
            context,
            ref,
            (p) => p.withType(type, p.of(type).copyWith(enabled: on)),
          ),
        ),
      ),
      if (type.hasTime || type == NotificationType.weighIn)
        FbReveal(
          visible: setting.enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [..._detailRows(context, ref, prefs, type, weekStart)],
          ),
        ),
    ];
  }

  /// A reminder's time (and the weigh-in's day), shown while it is on.
  List<Widget> _detailRows(
    BuildContext context,
    WidgetRef ref,
    NotificationPrefs prefs,
    NotificationType type,
    DayOfWeek weekStart,
  ) {
    final l10n = context.l10n;
    final setting = prefs.of(type);
    return [
      if (type.hasTime)
        FbListRow(
          key: ValueKey('notif-${type.name}-time'),
          title: l10n.notifTime,
          // NT-021 skips a reminder inside quiet hours: say so (#243). The
          // line is always reserved (A57 A13), so changing quiet hours
          // doesn't move the rows below.
          subtitle: prefs.isQuiet(setting.minute) ? l10n.notifTimeInQuiet : '',
          trailing: Text(_time(context, setting.minute)),
          onTap: () => unawaited(() async {
            final minute = await _pickMinute(context, setting.minute);
            if (minute == null || !context.mounted) return;
            await _save(
              context,
              ref,
              (p) => p.withType(type, p.of(type).copyWith(minute: minute)),
            );
          }()),
        ),
      if (type == NotificationType.weighIn)
        FbListRow(
          key: const ValueKey('notif-weighIn-day'),
          title: l10n.notifDay,
          trailing: Text(weekdayName(context, prefs.weighInDay ?? weekStart)),
          onTap: () => unawaited(
            _pickWeighInDay(context, ref, prefs, prefs.weighInDay ?? weekStart),
          ),
        ),
    ];
  }
}

(String, String) _names(AppLocalizations l10n, NotificationType type) =>
    switch (type) {
      NotificationType.logReminder => (
        l10n.notifTypeLogReminder,
        l10n.notifTypeLogReminderHint,
      ),
      NotificationType.pendingProposal => (
        l10n.notifTypePendingProposal,
        l10n.notifTypePendingProposalHint,
      ),
      NotificationType.weighIn => (
        l10n.notifTypeWeighIn,
        l10n.notifTypeWeighInHint,
      ),
      NotificationType.weeklySummary => (
        l10n.notifTypeWeeklySummary,
        l10n.notifTypeWeeklySummaryHint,
      ),
      NotificationType.workout => (
        l10n.notifTypeWorkout,
        l10n.notifTypeWorkoutHint,
      ),
      NotificationType.proteinCheck => (
        l10n.notifTypeProteinCheck,
        l10n.notifTypeProteinCheckHint,
      ),
      NotificationType.measurement => (
        l10n.notifTypeMeasurement,
        l10n.notifTypeMeasurementHint,
      ),
      NotificationType.suhoor => (
        l10n.notifTypeSuhoor,
        l10n.notifTypeSuhoorHint,
      ),
      NotificationType.iftar => (l10n.notifTypeIftar, l10n.notifTypeIftarHint),
    };

String _time(BuildContext context, int minute) => deviceTimeFormat(
  context,
  TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
);

Future<int?> _pickMinute(
  BuildContext context,
  int minute, {
  String? title,
}) async {
  final picked = await showFbTimePicker(
    context,
    initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    title: title,
  );
  return picked == null ? null : picked.hour * 60 + picked.minute;
}

Future<void> _pickQuiet(
  BuildContext context,
  WidgetRef ref,
  NotificationPrefs prefs,
) async {
  // Two pickers in a row: each says which end of the window it sets
  // (A57 A73).
  final start = await _pickMinute(
    context,
    prefs.quietStart,
    title: context.l10n.notifQuietFrom,
  );
  if (start == null || !context.mounted) return;
  final end = await _pickMinute(
    context,
    prefs.quietEnd,
    title: context.l10n.notifQuietUntil,
  );
  if (end == null || !context.mounted) return;
  await _save(
    context,
    ref,
    (p) => p.copyWith(quietStart: start, quietEnd: end),
  );
}

Future<void> _pickWeighInDay(
  BuildContext context,
  WidgetRef ref,
  NotificationPrefs prefs,
  DayOfWeek current,
) async {
  final picked = await showFbOptionSheet<DayOfWeek>(
    context,
    title: context.l10n.notifTypeWeighIn,
    selected: current,
    options: [
      for (final day in DayOfWeek.values)
        FbOption(value: day, label: weekdayName(context, day)),
    ],
  );
  if (picked == null || !context.mounted) return;
  await _save(context, ref, (p) => p.copyWith(weighInDay: picked));
}

/// Saves [change] of the stored settings with Undo feedback (UX-030). A
/// change, not a whole value, so quick edits of different reminders all
/// land (A57 A71).
Future<void> _save(
  BuildContext context,
  WidgetRef ref,
  NotificationPrefs Function(NotificationPrefs current) change,
) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await ref
      .read(settingsActionsProvider)
      .updateNotificationPrefs(change);
  if (!host.mounted) return;
  reportSettingsOutcome(host, outcome, () => host.l10n.notifSaved);
}
