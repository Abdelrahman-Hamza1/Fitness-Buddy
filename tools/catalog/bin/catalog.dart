import 'dart:io';

import 'package:fb_catalog/fb_catalog.dart';

/// Food catalog tooling. See `tools/catalog/README.md`.
Future<void> main(List<String> arguments) async {
  exitCode = await runCatalog(arguments, out: stdout, err: stderr);
}
