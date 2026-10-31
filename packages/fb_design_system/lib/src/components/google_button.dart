import 'package:fb_design_system/src/brand/brand_path.dart';
import 'package:fb_design_system/src/tokens/spacing.dart';
import 'package:fb_design_system/src/tokens/typography.dart';
import 'package:material_ui/material_ui.dart';

/// "Continue with Google" as Google's sign-in branding asks (A51, research
/// §4): the neutral button (white with a grey edge in light, near-black with
/// a grey edge in dark), the standard four-colour "G" at its start and the
/// approved [label]. Its colours are Google's, not the app's tokens: the
/// branding guidelines fix them, so they live only here.
///
/// Full width, 52 dp tall, a pill like the app's buttons; one button for a
/// screen reader. A null [onPressed] disables it (dimmed).
class FbGoogleButton extends StatelessWidget {
  /// Creates the button.
  const new({required this.label, required this.onPressed, super.key});

  /// The approved wording, translated ("Continue with Google").
  final String label;

  /// Called on tap; null disables the button.
  final VoidCallback? onPressed;

  // Google sign-in branding (developers.google.com/identity/branding-
  // guidelines): the light and dark neutral themes.
  static const Color _lightFill = Color(0xFFFFFFFF);
  static const Color _lightEdge = Color(0xFF747775);
  static const Color _lightText = Color(0xFF1F1F1F);
  static const Color _darkFill = Color(0xFF131314);
  static const Color _darkEdge = Color(0xFF8E918F);
  static const Color _darkText = Color(0xFFE3E3E3);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? _darkFill : _lightFill;
    final edge = dark ? _darkEdge : _lightEdge;
    final text = dark ? _darkText : _lightText;
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : .38,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        onTap: onPressed,
        excludeSemantics: true,
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: FbRadius.pillAll,
            side: BorderSide(color: edge),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: FbSpace.s4,
                  vertical: FbSpace.s2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: FbSpace.s3,
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CustomPaint(painter: _GoogleG()),
                    ),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: FbType.button.copyWith(color: text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google's standard "G", drawn from its 48 × 48 artwork.
class _GoogleG extends CustomPainter {
  const new();

  static final List<(Color, Path)> _parts = [
    (
      const Color(0xFFEA4335),
      parseFbMarkPath(
        'M 24 9.5 C 27.54 9.5 30.71 10.72 33.21 13.1 L 40.06 6.25 '
        'C 35.9 2.38 30.47 0 24 0 C 14.62 0 6.51 5.38 2.56 13.22 '
        'L 10.54 19.41 C 12.43 13.72 17.74 9.5 24 9.5 Z',
      ),
    ),
    (
      const Color(0xFF4285F4),
      parseFbMarkPath(
        'M 46.98 24.55 C 46.98 22.98 46.83 21.46 46.6 20 L 24 20 '
        'L 24 29.02 L 36.94 29.02 C 36.36 31.98 34.68 34.5 32.16 36.2 '
        'L 39.89 42.2 C 44.4 38.02 46.98 31.84 46.98 24.55 Z',
      ),
    ),
    (
      const Color(0xFFFBBC05),
      parseFbMarkPath(
        'M 10.53 28.59 C 10.05 27.14 9.77 25.6 9.77 24 '
        'C 9.77 22.4 10.04 20.86 10.53 19.41 L 2.55 13.22 '
        'C 0.92 16.46 0 20.12 0 24 C 0 27.88 0.92 31.54 2.56 34.78 '
        'L 10.53 28.59 Z',
      ),
    ),
    (
      const Color(0xFF34A853),
      parseFbMarkPath(
        'M 24 48 C 30.48 48 35.93 45.87 39.89 42.19 L 32.16 36.19 '
        'C 30.01 37.64 27.24 38.49 24 38.49 C 17.74 38.49 12.43 34.27 '
        '10.53 28.58 L 2.55 34.77 C 6.51 42.62 14.62 48 24 48 Z',
      ),
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, path) in _parts) {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_GoogleG oldDelegate) => false;
}
