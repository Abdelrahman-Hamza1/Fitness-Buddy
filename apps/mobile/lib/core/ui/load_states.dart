import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

/// A screen's read failed (A57 A42–A49, UX-051): a calm sentence with
/// Try again, never an empty state that pretends there is nothing.
class LoadFailedView extends StatelessWidget {
  /// Creates the view; [onRetry] re-reads (usually `ref.invalidate`).
  const new({required this.message, required this.onRetry, super.key});

  /// Key of the view, for tests and Patrol.
  static const ValueKey<String> viewKey = ValueKey('load-failed');

  /// What couldn't be loaded.
  final String message;

  /// Reads again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    key: viewKey,
    padding: const EdgeInsetsDirectional.all(FbSpace.s4),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: FbInlineBanner(
        kind: FbInlineBannerKind.error,
        message: message,
        actionLabel: context.l10n.commonTryAgain,
        onAction: onRetry,
      ),
    ),
  );
}

/// Local data still loading (A57 A42–A49): rows shaped like the result,
/// never a spinner and never an empty state (UX-045).
class LoadingRows extends StatelessWidget {
  /// Creates [count] placeholder rows.
  const new({this.count = 4, super.key});

  /// Key of the view, for tests.
  static const ValueKey<String> viewKey = ValueKey('loading-rows');

  /// How many rows.
  final int count;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: viewKey,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsetsDirectional.symmetric(vertical: FbSpace.s2),
    child: Column(children: [for (var i = 0; i < count; i++) FbSkeleton.row()]),
  );
}
