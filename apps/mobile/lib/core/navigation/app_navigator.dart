import 'package:fb_mobile/core/navigation/app_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_navigator.g.dart';

/// Navigation port (S06 plan A2): features and view models navigate through
/// this, never through go_router or `app/`.
///
/// ```dart
/// ref.read(appNavigatorProvider).go(const ProgressRoute());
/// ```
abstract interface class AppNavigator {
  /// Shows [route], replacing the current location (tabs keep their state).
  void go(AppRoute route);

  /// Shows [route] on top of the current screen, so [pop] (or the system
  /// back gesture) returns to it. For detail screens nested in a tab.
  void push(AppRoute route);

  /// Closes the topmost pushed screen. Does nothing when there is none.
  void pop();
}

/// The app's [AppNavigator]. `main` overrides it with the router
/// (`lib/app/app_scope.dart`); tests may override it with a fake.
@Riverpod(keepAlive: true)
AppNavigator appNavigator(Ref ref) => throw UnimplementedError(
  'appNavigatorProvider must be overridden (see lib/app/app_scope.dart).',
);
