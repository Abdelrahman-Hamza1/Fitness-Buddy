import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// One chat message (A22): the user's at the end, Buddy's at the start,
/// at most 85% of the width.
class FbMessageBubble extends StatelessWidget {
  /// A bubble with [text]; [fromUser] puts it at the end.
  const new({
    required this.text,
    required this.fromUser,
    this.semanticLabel,
    super.key,
  });

  /// What a screen reader says ("You: 2 eggs"); [text] when null.
  final String? semanticLabel;

  /// The message.
  final String text;

  /// The user wrote it.
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: semanticLabel ?? text,
      excludeSemantics: true,
      child: Align(
        alignment: fromUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: 0.85,
          alignment: fromUser
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Align(
            alignment: fromUser
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fromUser
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(FbRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: FbSpace.s3,
                  vertical: FbSpace.s2,
                ),
                child: Text(
                  text,
                  style: FbType.body.copyWith(
                    color: fromUser
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
