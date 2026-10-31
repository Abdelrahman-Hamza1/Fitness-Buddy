import 'package:fb_domain/fb_domain.dart' show LocalDate;
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/sync/application/sync_view.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialLocalizations, TimeOfDay;

/// The one-line status of [view] (A34 D13): calm words, never an error
/// tone for a normal wait.
String syncStatusText(AppLocalizations l10n, SyncView view) {
  if (view.restoring) return l10n.syncStatusRestoring(view.restoredRows);
  return switch (view.problem) {
    SyncProblem.offline when !view.synced => l10n.syncStatusOffline,
    SyncProblem.needsSignIn => l10n.syncStatusNeedsSignIn,
    SyncProblem.clockAhead when !view.synced => l10n.syncStatusClockAhead,
    SyncProblem.clockBehind => l10n.syncStatusClockBehind,
    SyncProblem.error when !view.synced => l10n.syncStatusError,
    _ when view.running => l10n.syncStatusSyncing,
    _ when view.parked > 0 => l10n.syncStatusParked(view.parked),
    _ when view.pending > 0 => l10n.syncStatusPending(view.pending),
    _ => l10n.syncStatusSynced,
  };
}

/// The day and clock time of the instant [ms] (UTC ms) on this phone:
/// "Today, 10:42" style through the app's day labels.
String instantText(BuildContext context, int ms, {required int nowMs}) {
  final local = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.fromMillisecondsSinceEpoch(nowMs);
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: local.hour, minute: local.minute),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final day = dayLabelInline(
    context,
    LocalDate(local.year, local.month, local.day),
    LocalDate(now.year, now.month, now.day),
  );
  return context.l10n.syncInstant(day, time);
}
