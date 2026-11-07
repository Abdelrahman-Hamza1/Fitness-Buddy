/// Home-screen widgets (A71, UX-082–085): the snapshot the app writes for
/// the Android widgets (they never open the database), its coordinator and
/// the tap routing. Other features and `app/` import only this barrel
/// (`03-architecture.md` §3.2).
library;

export 'application/home_widget_actions.dart';
export 'application/home_widget_coordinator.dart'
    show
        HomeWidgetCoordinator,
        homeWidgetCoordinatorProvider,
        homeWidgetLinkOpenerProvider,
        homeWidgetsEnabledProvider;
export 'application/widget_snapshot.dart';
