import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:flutter_riverpod/misc.dart';

/// No Ramadan decision (A41a): the day's meals are the normal ones without
/// reading the settings database or the city catalog. Rigs that stub the
/// other settings providers (week start, units) use it the same way.
final Override ramadanOff = ramadanSettingsProvider.overrideWith(
  (ref) => Stream.value(RamadanSettings.none),
);
