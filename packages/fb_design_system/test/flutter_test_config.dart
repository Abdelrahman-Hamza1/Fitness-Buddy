import 'dart:async';

import 'package:fb_design_system/testing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file in this package (flutter_test convention).
///
/// The fonts are loaded here (A02 D19), so layout-sensitive widget tests use
/// the real Inter / Noto Sans Arabic metrics. There are no golden tests in
/// this package (TD-104).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadFbTestFonts();
  await testMain();
}
