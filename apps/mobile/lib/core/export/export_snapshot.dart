/// Plain, isolate-sendable database snapshot; no database handle escapes.
final class ExportSnapshot {
  /// Captures plain live rows under their sync wire entities.
  const new({required this.schemaVersion, required this.rows});

  /// Schema version of the database that was read.
  final int schemaVersion;

  /// Live rows, with no install identity or HLC fields.
  final Map<String, List<Map<String, Object?>>> rows;
}
