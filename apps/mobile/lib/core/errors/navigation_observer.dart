import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// One root observer also receives shell-branch pushes (A11 WP0 / PA7).
/// Routes are named with static templates; arguments are scrubbed separately.
NavigatorObserver createErrorNavigationObserver() => SentryNavigatorObserver(
  enableAutoTransactions: false,
  // Explicit privacy pin even if the SDK changes its default.
  // ignore: avoid_redundant_argument_values
  setRouteNameAsTransaction: false,
);
