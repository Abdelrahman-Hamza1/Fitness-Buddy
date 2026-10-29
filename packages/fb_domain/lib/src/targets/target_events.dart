import 'package:fb_domain/src/changes/domain_event.dart';

/// The parts of the targets data an op writes.
enum TargetsPart {
  /// The profile row.
  profile,

  /// Goal phase rows.
  goals,

  /// Target settings version rows.
  settings,
}

/// Targets data changed (also on undo). Carries the parts only, never
/// values.
final class TargetsChanged extends DomainEvent {
  /// The [parts] that changed.
  new(Iterable<TargetsPart> parts) : parts = Set.unmodifiable(parts);

  /// The changed parts. Unmodifiable.
  final Set<TargetsPart> parts;

  @override
  bool operator ==(Object other) =>
      other is TargetsChanged &&
      other.parts.length == parts.length &&
      other.parts.containsAll(parts);

  @override
  int get hashCode => Object.hashAllUnordered(parts);

  @override
  String toString() {
    final names = [
      for (final part in TargetsPart.values)
        if (parts.contains(part)) part.name,
    ];
    return 'TargetsChanged(${names.join(', ')})';
  }
}
