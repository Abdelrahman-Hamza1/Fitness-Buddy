import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:material_ui/material_ui.dart';

/// A list row: title, optional subtitle, leading and trailing widgets
/// (HM-007). Tappable when [onTap] is set.
///
/// A row that ends in a button gives it as [trailingAction] (A65 m18): at
/// the end of the row normally, and under the text from text scale
/// [largeTextScale] on, so the title isn't squeezed.
class FbListRow extends StatelessWidget {
  /// Creates a row.
  const new({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingAction,
    this.onTap,
    super.key,
  }) : assert(
         trailing == null || trailingAction == null,
         'a row has a trailing widget or a trailing action, not both',
       );

  /// From this text scale on, [trailingAction] moves under the text.
  static const double largeTextScale = 1.3;

  /// The main text.
  final String title;

  /// A second, muted line.
  final String? subtitle;

  /// At the start of the row.
  final Widget? leading;

  /// At the end of the row.
  final Widget? trailing;

  /// A button at the end of the row, under the text at large text sizes.
  final Widget? trailingAction;

  /// Makes the row tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final action = trailingAction;
    final below =
        action != null &&
        MediaQuery.textScalerOf(context).scale(1) >= largeTextScale;
    final subtitleText = subtitle == null ? null : Text(subtitle!);
    return ListTile(
      title: Text(title),
      subtitle: !below
          ? subtitleText
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?subtitleText,
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: FbSpace.s1),
                  child: action,
                ),
              ],
            ),
      leading: leading,
      trailing: below ? null : trailing ?? action,
      onTap: onTap,
    );
  }
}
