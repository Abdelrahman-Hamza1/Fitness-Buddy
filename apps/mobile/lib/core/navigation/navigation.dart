/// Typed routes and the navigation port (S06 plan A2), the tab re-tap
/// signal and the unsaved-edits guard (A45 D12, D13).
library;

export 'app_navigator.dart';
export 'app_route.dart';
export 'tab_reselect.dart';
export 'unsaved_edits.dart'
    show UnsavedEdits, UnsavedEditsGuard, unsavedEditsProvider;
