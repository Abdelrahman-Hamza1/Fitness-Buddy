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

  /// An `// app-check: allow` comment without a rule id or a reason, or
  /// naming a rule that can't be allowed (the import boundaries 1 to 7).
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
