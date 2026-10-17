/// The checks app_check runs. The [id] appears in every message.
///
/// The README (`tools/app_check/README.md`) explains each rule and its fix.
enum Rule {
  /// 1. Another feature is imported only through its barrel.
  featureBarrel('feature-barrel'),

  /// 2. `features/*/presentation/` never imports `features/*/data/`.
  presentationData('presentation-data'),

  /// 3. I/O and platform packages (dio, fb_api_client, drift*, …) only in
  /// `data/` and `core/`.
  ioPackage('io-package'),

  /// 4. `core/` never imports `features/` or `app/`.
  coreBoundary('core-boundary'),

  /// 5. `features/` never imports `app/` (S06 A2).
  featureApp('feature-app'),

  /// 6. Presentation code never imports `core/api|db|sync` (S06 A3).
  presentationIo('presentation-io'),

  /// 7. `go_router` only in `app/router/` (S06 D2).
  goRouter('go-router'),

  /// 8. No raw string literals in user-visible widget arguments.
  rawString('raw-string'),

  /// 9. No left/right layout APIs: start/end (directional) only.
  directional('directional'),

  /// 10. `core/db/write/` only from the applier (A01 D12).
  dbWriteApi('db-write-api'),

  /// 11. No drift write calls (or `customSelect` writes) outside `core/db/`
  /// and the applier, and the write guard (`runAuthorizedWrite`) and
  /// `seed_rows.dart` and the connection libraries (sqlite3, drift's
  /// backends) only from `core/db/` (A01 D12).
  dbWriteCall('db-write-call'),

  /// 12. `features/*/application/` never imports `core/db/` (A01 D12).
  applicationDb('application-db'),

  /// 13. Presentation code never imports `core/changes/` (A01 D12).
  presentationChanges('presentation-changes'),

  /// An `// app-check: allow` comment without a rule id or a reason, or
  /// naming a rule that can't be allowed (every rule but the lexical
  /// `raw-string` and `directional`).
  invalidAllow('invalid-allow');

  new(this.id);

  /// The rule's name in messages, e.g. `feature-barrel`.
  final String id;
}

/// One rule broken at one line.
final class Violation implements Comparable<Violation> {
  /// Creates a violation of [rule] at [path]:[line].
  const new({
    required this.path,
    required this.line,
    required this.rule,
    required this.message,
  });

  /// The file, relative to the app folder (`lib/...`) unless rewritten by
  /// the caller for display.
  final String path;

  /// 1-based line.
  final int line;

  /// The rule broken.
  final Rule rule;

  /// What is wrong and how to fix it.
  final String message;

  /// A copy with [path] replaced (for display relative to the repo).
  Violation withPath(String path) =>
      Violation(path: path, line: line, rule: rule, message: message);

  @override
  int compareTo(Violation other) {
    final byPath = path.compareTo(other.path);
    if (byPath != 0) return byPath;
    final byLine = line.compareTo(other.line);
    if (byLine != 0) return byLine;
    return rule.index.compareTo(other.rule.index);
  }

  /// `path:line: rule-id: message`.
  @override
  String toString() => '$path:$line: ${rule.id}: $message';
}
