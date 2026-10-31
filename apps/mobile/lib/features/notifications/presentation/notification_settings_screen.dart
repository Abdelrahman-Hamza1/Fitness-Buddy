import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
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
    final prefs =
        ref.watch(notificationPrefsProvider).value ??
        NotificationPrefs.defaults;
    final allowed = ref.watch(notificationsAllowedProvider).value ?? true;
    final weekStart = ref.watch(weekStartProvider).value ?? DayOfWeek.saturday;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifSettingsTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: FbSpace.s5),
        children: [
          if (!allowed)
            Padding(
              padding: const EdgeInsetsDirectional.all(FbSpace.s4),
              child: FbInlineBanner(
                key: const ValueKey('notif-permission'),
                kind: FbInlineBannerKind.info,
                message: l10n.notifPermissionOff,
                actionLabel: l10n.notifPermissionAllow,
                onAction: () => unawaited(
                  ref.read(notificationPermissionProvider).request(),
                ),
              ),
            ),
          FbSwitchRow(
            key: const ValueKey('notif-master'),
            title: l10n.notifMaster,
            subtitle: l10n.notifMasterHint,
            value: prefs.enabled,
            onChanged: (on) =>
                unawaited(_save(context, ref, prefs.copyWith(enabled: on))),
          ),
          if (prefs.enabled) ...[
            FbListRow(
              key: const ValueKey('notif-quiet'),
              title: l10n.notifQuietHours,
              subtitle: l10n.notifQuietRange(
                _time(context, prefs.quietStart),
                _time(context, prefs.quietEnd),
              ),
              trailing: const Icon(FbIcons.next),
              onTap: () => unawaited(_pickQuiet(context, ref, prefs)),
            ),
            FbSectionHeader(title: l10n.notifSectionTypes),
            for (final type in NotificationType.values)
              ..._typeRows(context, ref, prefs, type, weekStart),
          ],
        ],
      ),
    );
  }

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
            prefs.withType(type, setting.copyWith(enabled: on)),
          ),
        ),
      ),
      if (setting.enabled && type.hasTime)
        FbListRow(
          key: ValueKey('notif-${type.name}-time'),
          title: l10n.notifTime,
          trailing: Text(_time(context, setting.minute)),
          onTap: () => unawaited(() async {
            final minute = await _pickMinute(context, setting.minute);
            if (minute == null || !context.mounted) return;
            await _save(
              context,
              ref,
              prefs.withType(type, setting.copyWith(minute: minute)),
            );
          }()),
        ),
      if (setting.enabled && type == NotificationType.weighIn)
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

String _time(BuildContext context, int minute) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: minute ~/ 60, minute: minute % 60));

Future<int?> _pickMinute(BuildContext context, int minute) async {
  final picked = await showFbTimePicker(
    context,
    initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
  );
  return picked == null ? null : picked.hour * 60 + picked.minute;
}

Future<void> _pickQuiet(
  BuildContext context,
  WidgetRef ref,
  NotificationPrefs prefs,
) async {
  final start = await _pickMinute(context, prefs.quietStart);
  if (start == null || !context.mounted) return;
  final end = await _pickMinute(context, prefs.quietEnd);
  if (end == null || !context.mounted) return;
  await _save(context, ref, prefs.copyWith(quietStart: start, quietEnd: end));
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
  await _save(context, ref, prefs.copyWith(weighInDay: picked));
}

/// Saves [prefs] with Undo feedback (UX-030).
Future<void> _save(
  BuildContext context,
  WidgetRef ref,
  NotificationPrefs prefs,
) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final outcome = await ref
      .read(settingsActionsProvider)
      .setNotificationPrefs(prefs);
  if (!host.mounted) return;
  reportSettingsOutcome(host, outcome, () => host.l10n.notifSaved);
}
