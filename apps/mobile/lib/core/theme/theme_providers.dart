import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_providers.g.dart';

/// Which palette variant the app wears (A02 D16). Always [FbPaletteVariant.a]
/// until the design preview (dev flavor only) switches it; in memory, never
/// persisted: the pick is temporary by design (A02 D3).
///
/// Lives in `core/` rather than `app/theme/` so that `app/app.dart` can watch
/// it and the design preview feature can set it: features may not import
/// `app/` (app_check rule 5).
@Riverpod(keepAlive: true)
class ThemeVariant extends _$ThemeVariant {
  @override
  FbPaletteVariant build() => FbPaletteVariant.a;

  /// Wears [variant] from now on.
  // ignore: use_setters_to_change_properties, a Notifier can't have a setter
  void select(FbPaletteVariant variant) => state = variant;
}

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
