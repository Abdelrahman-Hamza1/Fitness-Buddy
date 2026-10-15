import 'dart:io';

import 'package:fb_app_check/fb_app_check.dart';

/// Checks the app's lib/ folder. See `tools/app_check/README.md`.
void main(List<String> arguments) {
  exitCode = runAppCheck(arguments, out: stdout, err: stderr);
}
