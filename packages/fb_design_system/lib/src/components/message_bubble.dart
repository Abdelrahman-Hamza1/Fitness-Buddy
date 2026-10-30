import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// One chat message (A22): the user's at the end, Buddy's at the start,
/// at most 85% of the width. An optional decorative [leading] (Buddy's
/// avatar, A44) sits before the bubble, top-aligned.
class FbMessageBubble extends StatelessWidget {
  /// A bubble with [text]; [fromUser] puts it at the end.
  const new({
    required this.text,
    required this.fromUser,
    this.semanticLabel,
    this.leading,
    this.textDirection,
    super.key,
  });

  /// The message's own direction (an Arabic message inside an English UI,
  /// D-080); the ambient direction when null. Placement still follows the
  /// UI direction.
  final TextDirection? textDirection;

  /// A decorative widget before the bubble, e.g. a 24 dp `FbBuddyAvatar`;
  /// not read out (the [semanticLabel] says who is talking).
  final Widget? leading;

  /// What a screen reader says ("You: 2 eggs"); [text] when null.
  final String? semanticLabel;

  /// The message.
  final String text;

  /// The user wrote it.
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: fromUser ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(FbRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: FbSpace.s3,
          vertical: FbSpace.s2,
        ),
        child: Text(
          text,
          textDirection: textDirection,
          style: FbType.body.copyWith(
            color: fromUser ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
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
            child: leading == null
                ? bubble
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading!,
                      const SizedBox(width: FbSpace.s2),
                      Flexible(child: bubble),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
