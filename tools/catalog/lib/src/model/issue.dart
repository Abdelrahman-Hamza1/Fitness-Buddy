/// One problem found in a catalog file: where (file and JSON-pointer-like
/// path inside it) and what.
class CatalogIssue {
  const new(this.file, this.path, this.message);

  final String file;

  /// Path inside the file, e.g. `/variants/0/recipe/1/grams`; empty for the
  /// whole file.
  final String path;
  final String message;

  @override
  String toString() =>
      path.isEmpty ? '$file: $message' : '$file: $path: $message';
}
