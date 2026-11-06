import 'package:fb_mobile/core/navigation/app_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'start_route.g.dart';

/// Where the next router opens instead of Today, once (backlog #272): the
/// first run sets it before its account step's sign-in, because signing in
/// to an existing account switches the profile, and the new profile's
/// router would otherwise open at Today ("I want a plan" then skipped the
/// starter plans). Memory only; the flow clears it when it ends normally.
final class StartRouteHolder {
  AppRoute? _route;

  /// Holds [route] for the next router (null clears it).
  // A command method keeps the value private.
  // ignore: use_setters_to_change_properties
  void hold(AppRoute? route) => _route = route;

  /// The held route, cleared as it is read.
  AppRoute? take() {
    final route = _route;
    _route = null;
    return route;
  }
}

/// The one [StartRouteHolder]; it outlives profile switches.
@Riverpod(keepAlive: true)
StartRouteHolder startRouteHolder(Ref ref) => StartRouteHolder();
