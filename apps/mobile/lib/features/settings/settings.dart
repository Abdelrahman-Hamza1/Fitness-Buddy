/// The Settings feature (A10): the setting keys, their providers and commands,
/// and the Settings section, city picker and About screens. Other features
/// and `app/` import only this barrel (`03-architecture.md` §3.2).
library;

export 'application/about_info.dart';
export 'application/app_settings.dart';
export 'application/city_search.dart';
export 'application/data_export.dart';
export 'application/settings_actions.dart';
export 'application/settings_providers.dart';
export 'application/test_report.dart';
export 'presentation/about_screen.dart';
export 'presentation/city_pick_sheet.dart';
export 'presentation/city_picker_screen.dart';
export 'presentation/city_search_list.dart';
export 'presentation/export_sheet.dart';
export 'presentation/food_name_text.dart';
export 'presentation/food_names_setting_row.dart';
export 'presentation/settings_feedback.dart' show reportSettingsOutcome;
export 'presentation/settings_section.dart';
