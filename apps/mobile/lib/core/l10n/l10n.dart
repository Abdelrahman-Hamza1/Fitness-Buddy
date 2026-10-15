import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:fb_mobile/l10n/gen/app_localizations.dart';

/// Short access to the app's strings: `Text(context.l10n.tabToday)`.
extension AppLocalizationsContext on BuildContext {
  /// The [AppLocalizations] of this context.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
