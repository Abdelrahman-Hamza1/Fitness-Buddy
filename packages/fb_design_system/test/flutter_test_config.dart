import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/testing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file in this package (flutter_test convention).
///
/// Goldens: alchemist's CI variant only (S06 plan D17, A02 D7). Text is drawn
/// as blocks, so the images are the same on the laptop and in CI, but its
/// layout uses the real Inter / Noto Sans Arabic metrics: the fonts are
/// loaded here (A02 D19).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadFbTestFonts();
  await AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: () async {
      await testMain();
    },
  );
}
