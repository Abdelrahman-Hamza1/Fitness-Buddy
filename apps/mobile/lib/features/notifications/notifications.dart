/// Notifications (A40): local reminders planned by the pure
/// `NotificationPlanner` (fb_domain) and kept on the phone by an idempotent
/// scheduler; the Notifications settings screen. Nothing personal leaves
/// the phone (TD-013). Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/notification_coordinator.dart'
    show
        NotificationCoordinator,
        notificationCoordinatorProvider,
        notificationLinkOpenerProvider,
        notificationSchedulingEnabledProvider;
export 'application/notification_links.dart';
export 'application/notification_scheduler.dart';
export 'data/notification_device_store.dart';
export 'data/notification_platform.dart';
export 'presentation/notification_settings_screen.dart';
