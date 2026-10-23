import 'package:flutter/widgets.dart';

/// At text scale 1.4 or more, a row moves its trailing number into its
/// subtitle, so the name keeps the room it needs (UX-040: the app
/// follows the system text size up to 2.0 without clipping).
bool usesLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.4;
