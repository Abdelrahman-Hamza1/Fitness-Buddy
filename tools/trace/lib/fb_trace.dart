/// Requirement traceability for Fitness Buddy (AT-001).
///
/// Reads the requirement IDs from `spec/*.md`, finds the tests that claim to
/// cover them, and renders a deterministic Markdown report per release.
library;

export 'src/cli.dart';
export 'src/release_overrides.dart';
export 'src/report.dart';
export 'src/requirement.dart';
export 'src/spec_parser.dart';
export 'src/test_scanner.dart';
