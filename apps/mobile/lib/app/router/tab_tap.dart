/// What a tap on a tab does (UX-010, A45 D11).
enum TabTapAction {
  /// Show the tab's root screen.
  goRoot,

  /// Show the tab as it was left (its top screen holds unsaved edits).
  keepStack,

  /// Ask the screen with unsaved edits first; the root only on a discard.
  confirmThenRoot,

  /// Scroll the root screen's list to the top.
  scrollTop,
}

/// The tab rules (A45 D11): another tab opens at its root, unless its top
/// screen holds unsaved edits ([holdsEdits]), which it keeps. The current
/// tab, when deep, goes back to its root (asking first if a screen holds
/// edits); at its root ([atRoot]) it scrolls to the top.
TabTapAction tabTapAction({
  required bool sameTab,
  required bool atRoot,
  required bool holdsEdits,
}) => switch ((sameTab, atRoot, holdsEdits)) {
  (false, _, true) => TabTapAction.keepStack,
  (false, _, false) => TabTapAction.goRoot,
  (true, true, _) => TabTapAction.scrollTop,
  (true, false, true) => TabTapAction.confirmThenRoot,
  (true, false, false) => TabTapAction.goRoot,
};
