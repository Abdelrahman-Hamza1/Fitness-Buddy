import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_providers.g.dart';

/// Light, dark or follow the system (UX-040). [ThemeMode.system] until the
/// design preview switches it; in memory, never persisted.
@Riverpod(keepAlive: true, name: 'themeModeProvider')
class ThemeModeSetting extends _$ThemeModeSetting {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Uses [mode] from now on.
  // ignore: use_setters_to_change_properties, a Notifier can't have a setter
  void select(ThemeMode mode) => state = mode;
}
