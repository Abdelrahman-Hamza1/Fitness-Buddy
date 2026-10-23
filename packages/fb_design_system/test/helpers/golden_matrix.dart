import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Phone width of a golden cell, in dp.
const double fbGoldenCellWidth = 360;

/// The text scales of a component matrix (UX-070; A02 D9).
const List<double> fbGoldenTextScales = [1, 2];

/// The four theme/direction columns of a matrix row, in order.
const List<(String, Brightness, TextDirection)> fbGoldenColumns = [
  ('light LTR', Brightness.light, TextDirection.ltr),
  ('light RTL', Brightness.light, TextDirection.rtl),
  ('dark LTR', Brightness.dark, TextDirection.ltr),
  ('dark RTL', Brightness.dark, TextDirection.rtl),
];

/// Wraps [child] as a screen cell: [brightness] theme,
/// [direction], [textScale], animations off, the phone width and the theme's
/// surface behind it.
Widget fbGoldenCell({
  required Widget child,
  required Brightness brightness,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  double width = fbGoldenCellWidth,
}) {
  final theme = brightness == Brightness.light
      ? FbTheme.light()
      : FbTheme.dark();
  return Theme(
    data: theme,
    child: Localizations(
      locale: const Locale('en'),
      delegates: const [
        FbLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      child: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: DefaultTextStyle(
              style: theme.textTheme.bodyMedium!,
              child: SizedBox(
                width: width,
                child: Material(color: theme.colorScheme.surface, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One golden PNG for a component (A02 D8): every state in light and dark,
/// LTR and RTL, at text scale 1.0 and then 2.0.
///
/// Rows are the [states] (builders), four columns per row in the order of
/// [fbGoldenColumns]. Text is drawn as blocks laid out with the real fonts
/// (alchemist CI variant); animations are off.
Future<void> fbGoldenMatrix(
  String description, {
  required String fileName,
  required Map<String, WidgetBuilder> states,
  List<double> textScales = fbGoldenTextScales,
  Interaction? whilePerforming,
}) => goldenTest(
  description,
  fileName: fileName,
  whilePerforming: whilePerforming,
  // Nothing animates, but settle anyway so sheets and routes are complete.
  pumpBeforeTest: precacheImages,
  builder: () => GoldenTestGroup(
    columns: fbGoldenColumns.length,
    children: [
      for (final scale in textScales)
        for (final MapEntry(key: state, value: build) in states.entries)
          for (final (label, brightness, direction) in fbGoldenColumns)
            GoldenTestScenario(
              name: '$state, $label, x$scale',
              child: fbGoldenCell(
                brightness: brightness,
                direction: direction,
                textScale: scale,
                child: Builder(builder: build),
              ),
            ),
    ],
  ),
);

/// Pads a golden state like a screen would, so edges are not cropped.
Widget fbGoldenPad(Widget child) =>
    Padding(padding: const EdgeInsetsDirectional.all(FbSpace.s4), child: child);
