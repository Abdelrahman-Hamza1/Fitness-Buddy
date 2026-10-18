import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// The page frame every mockup uses: screen padding and vertical rhythm.
class MockupPage extends StatelessWidget {
  /// Creates the frame around [children].
  const new({required this.children, super.key});

  /// The mockup's blocks, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: FbSpace.s4,
      vertical: FbSpace.s2,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s3,
      children: children,
    ),
  );
}

/// A no-op for controls that do nothing in a mockup (no navigation).
void mockupNoop() {}
