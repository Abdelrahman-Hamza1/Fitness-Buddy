import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/testing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file in this package (flutter_test convention).
///
/// Goldens: CI variant only (S06 plan D17). It renders text as blocks, so
/// the images are the same on the laptop and in CI; platform goldens would
/// differ per OS. The design system's fonts are loaded first (A02 D19), so
/// the blocks have the real Inter / Noto Sans Arabic widths.
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
