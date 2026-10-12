import 'dart:io';

import 'package:fb_trace/fb_trace.dart';

/// Prints the requirement traceability report. See `tools/trace/README.md`.
void main(List<String> arguments) {
  exitCode = runTrace(arguments, out: stdout, err: stderr);
}
