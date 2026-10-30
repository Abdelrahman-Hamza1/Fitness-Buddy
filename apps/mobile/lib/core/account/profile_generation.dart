import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_generation.g.dart';

/// Bumped on every profile switch (A33 re-check 3), before the new profile
/// opens: appliers, commands and the app's widget tree created for an older
/// generation are stale, and the write gate rejects their writes.
@Riverpod(keepAlive: true)
class ProfileGeneration extends _$ProfileGeneration {
  @override
  int build() => 0;

  /// Starts a new generation.
  void bump() => state++;
}
