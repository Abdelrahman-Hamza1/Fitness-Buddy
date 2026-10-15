import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Runs before every test file in this package (flutter_test convention).
///
/// Goldens: CI variant only (S06 plan D17). It renders text as blocks
/// (Ahem), so the images are the same on the laptop and in CI; platform
/// goldens would differ per OS.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: () async {
        await testMain();
      },
    );
