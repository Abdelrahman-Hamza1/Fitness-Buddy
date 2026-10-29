/// Layout density (A44 D6, TD-098): the canvas's **compact** values are the
/// default (owner backlog #74: "a lot of scrolling"). The comfortable values
/// sit beside them; switching is the one-line change of [_compact]. No
/// runtime switch: there is no density picker in R1.
abstract final class FbDensity {
  static const bool _compact = true;

  /// Inner padding of a card (comfortable: 16).
  static const double cardPadding = _compact ? 12 : 16;

  /// Vertical gap between stacked cards (comfortable: 12).
  static const double cardGap = _compact ? 8 : 12;

  /// Gap between the parts of one block, e.g. the key number and its bar
  /// (comfortable: 12).
  static const double blockGap = _compact ? 8 : 12;

  /// Gap between two sections of one block, e.g. the budget line and the
  /// macros (comfortable: 16).
  static const double sectionGap = _compact ? 12 : 16;

  /// Minimum height of a list row (comfortable: 56). Never below the 44 dp
  /// touch target.
  static const double rowMinHeight = _compact ? 44 : 56;

  /// Font size of the display number (comfortable: 48).
  static const double displaySize = _compact ? 40 : 48;

  /// Line height of the display number (comfortable: 56).
  static const double displayLineHeight = _compact ? 48 : 56;

  /// Whether the macro bars sit in one row of columns when they fit
  /// (comfortable: one row per macro).
  static const bool macroColumns = _compact;

  /// Thickness of a macro bar (comfortable: 8). Fibre's is thinner.
  static const double macroBarHeight = _compact ? 6 : 8;
}
