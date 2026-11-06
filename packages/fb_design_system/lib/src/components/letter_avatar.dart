import 'package:fb_design_system/src/tokens/icons.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// A circle with the first letter of [source] (A63 D11), e.g. a person's
/// name or email: the first grapheme, upper-cased where the script has
/// cases, so an Arabic name shows its first letter. With no [source] (or
/// only spaces) it shows [fallbackIcon]. Decorative: the name next to it is
/// what a screen reader reads.
class FbLetterAvatar extends StatelessWidget {
  /// Creates a letter avatar of [size] dp.
  const new({
    required this.source,
    this.fallbackIcon = FbIcons.me,
    this.size = 40,
    super.key,
  });

  /// The text whose first letter is shown, or null for the icon.
  final String? source;

  /// Shown when there is no letter.
  final IconData fallbackIcon;

  /// The circle's diameter.
  final double size;

  /// The letter shown for [source], or null for none.
  static String? letterOf(String? source) {
    final trimmed = source?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = letterOf(source);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: letter == null
                ? Icon(
                    fallbackIcon,
                    size: size * 0.55,
                    color: scheme.onPrimaryContainer,
                  )
                : Text(
                    letter,
                    // The circle stays round at any text size.
                    textScaler: TextScaler.noScaling,
                    style: FbType.title.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontSize: size * 0.45,
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
