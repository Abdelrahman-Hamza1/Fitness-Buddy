import 'package:material_ui/material_ui.dart';

/// One state of a component in the gallery: [name] (an identifier shown
/// above it, like the golden tests' state names) and the widget.
final class GalleryState {
  /// Creates a state.
  const new(this.name, this.child);

  /// What this state is called.
  final String name;

  /// The component in this state.
  final Widget child;
}

/// One gallery section: a design-system component (or a few that belong
/// together) in all its states.
final class GallerySection {
  /// Creates a section.
  const new({required this.name, required this.covers, required this.states});

  /// The section's heading: the component's class name (or the family's).
  final String name;

  /// The public design-system types this section shows. The gallery test
  /// fails when a public component is in no section's [covers].
  final List<Type> covers;

  /// The states, built in the gallery's context (theme, locale, scaffold).
  final List<GalleryState> Function(BuildContext context) states;
}
