import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';

/// Where a notification opens (NT-024, A40 D9): exactly the relevant
/// place. The weekly summary opens the week that just ended ([calendar]'s
/// week before the notification's day).
AppRoute notificationRoute(
  NotificationCandidate n, {
  required WeekCalendar calendar,
}) => switch (n.type) {
  NotificationType.logReminder ||
  NotificationType.proteinCheck => const TodayRoute(),
  NotificationType.pendingProposal => const TodayRoute(open: TodayOpen.buddy),
  NotificationType.weighIn => const TodayRoute(open: TodayOpen.weighIn),
  NotificationType.weeklySummary => WeeklySummaryRoute(
    start: calendar.weekStartOf(n.date).plusDays(-7),
  ),
  NotificationType.workout => switch (n.templateId) {
    final template? => TodayWorkoutLogRoute(template: template, date: n.date),
    null => const WorkoutsRoute(),
  },
  NotificationType.measurement => const MeasurementsRoute(),
  NotificationType.suhoor || NotificationType.iftar => const TodayRoute(),
};

/// A notification's neutral words (NT-025): no numbers, names or food on
/// the lock screen, never "you forgot".
({String title, String body}) notificationText(
  AppLocalizations l10n,
  NotificationType type,
) => switch (type) {
  NotificationType.logReminder => (
    title: l10n.notifLogTitle,
    body: l10n.notifLogBody,
  ),
  NotificationType.pendingProposal => (
    title: l10n.notifPendingTitle,
    body: l10n.notifPendingBody,
  ),
  NotificationType.weighIn => (
    title: l10n.notifWeighInTitle,
    body: l10n.notifWeighInBody,
  ),
  NotificationType.weeklySummary => (
    title: l10n.notifSummaryTitle,
    body: l10n.notifSummaryBody,
  ),
  NotificationType.workout => (
    title: l10n.notifWorkoutTitle,
    body: l10n.notifWorkoutBody,
  ),
  NotificationType.proteinCheck => (
    title: l10n.notifProteinTitle,
    body: l10n.notifProteinBody,
  ),
  NotificationType.measurement => (
    title: l10n.notifMeasurementTitle,
    body: l10n.notifMeasurementBody,
  ),
  NotificationType.suhoor => (
    title: l10n.notifSuhoorTitle,
    body: l10n.notifSuhoorBody,
  ),
  NotificationType.iftar => (
    title: l10n.notifIftarTitle,
    body: l10n.notifIftarBody,
  ),
};
