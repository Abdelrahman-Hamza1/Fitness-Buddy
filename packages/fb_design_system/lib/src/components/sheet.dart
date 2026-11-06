import 'package:fb_design_system/l10n/gen/fb_localizations.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// The content shell of a bottom sheet (UX-011): drag handle, optional
/// title, scrollable content, safe area. Shown with [showFbSheet].
class FbSheet extends StatelessWidget {
  /// Creates a sheet body.
  const new({
    required this.child,
    this.title,
    this.actions,
    this.showHandle = true,
    super.key,
  });

  /// Shows the drag handle; off for a sheet shown with `enableDrag: false`
  /// (a form that asks before its edits are discarded, A65 m8).
  final bool showHandle;

  /// The (already translated) title.
  final String? title;

  /// The content.
  final Widget child;

  /// Optional footer kept visible while content scrolls (UX-070).
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!showHandle)
            const SizedBox(height: FbSpace.s5)
          else
            Center(
              child: Semantics(
                label: FbLocalizations.of(context).fbSheetDragHandle,
                child: Container(
                  margin: const EdgeInsetsDirectional.only(
                    top: FbSpace.s3,
                    bottom: FbSpace.s2,
                  ),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: FbSpace.s5,
                end: FbSpace.s5,
                bottom: FbSpace.s2,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title!,
                  style: FbType.title.copyWith(color: scheme.onSurface),
                ),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.only(
                start: FbSpace.s5,
                end: FbSpace.s5,
                bottom: FbSpace.s5,
              ),
              child: child,
            ),
          ),
          if (actions != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                FbSpace.s5,
                FbSpace.s2,
                FbSpace.s5,
                FbSpace.s5,
              ),
              child: actions,
            ),
        ],
      ),
    );
  }
}

/// Shows [FbSheet] as a modal bottom sheet. Resolves when it closes.
///
/// [enableDrag] false keeps a swipe from closing it: a drag-dismiss pops
/// the route directly, past any `PopScope`, so a form that asks before
/// discarding edits turns it off (A65 m8). A tap outside and Back still
/// close it through the route's pop checks.
Future<T?> showFbSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  WidgetBuilder? actionsBuilder,
  bool enableDrag = true,
}) => showModalBottomSheet<T>(
  context: context,
  enableDrag: enableDrag,
  // Above the app shell (tabs, and the shell scaffold's snackbars): an Undo
  // snackbar from the previous action must never cover the sheet's buttons.
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  builder: (context) => FbSheet(
    title: title,
    actions: actionsBuilder?.call(context),
    showHandle: enableDrag,
    child: builder(context),
  ),
);

/// Shows a modal bottom sheet whose [builder] returns the whole [FbSheet]
/// itself, for a sheet that has state: its title, content and pinned
/// [FbSheet.actions] then follow that state (a Save that is disabled until
/// the form is valid). Opens on the root navigator like [showFbSheet];
/// [enableDrag] as there (the builder's [FbSheet] then hides its handle).
Future<T?> showFbStatefulSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool enableDrag = true,
}) => showModalBottomSheet<T>(
  context: context,
  enableDrag: enableDrag,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  builder: builder,
);
