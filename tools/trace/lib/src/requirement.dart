/// Pattern of a requirement ID, e.g. `AI-012`, `C-1`, `AQ-01`.
///
/// One to three capital letters, a hyphen, digits. Test-case numbers like
/// `T01` have no hyphen and never match.
const String idPattern = r'[A-Z]{1,3}-\d+';

/// Matches a whole string that is exactly one requirement ID.
final RegExp exactId = RegExp('^$idPattern\$');

/// Matches requirement IDs anywhere in a string (word-bounded).
final RegExp anyId = RegExp('\\b$idPattern\\b');

/// The release a requirement belongs to.
enum Release {
  /// Release 1: the owner.
  r1('R1'),

  /// Release 2: friends.
  r2('R2'),

  /// Release 3: the public.
  r3('R3'),

  /// Some day, not planned for a release.
  later('Later'),

  /// No release tag in the spec and no override.
  untagged('Untagged');

  new(this.label);

  /// The label used in the spec (`[R1]`) and in the report.
  final String label;

  /// The releases a spec tag can name (everything but [untagged]).
  static const List<Release> tagged = [r1, r2, r3, later];

  /// Returns the release whose [label] is exactly [tag], or `null`.
  ///
  /// [untagged] is never returned: "Untagged" is not a valid spec tag.
  static Release? fromTag(String tag) {
    for (final release in tagged) {
      if (release.label == tag) return release;
    }
    return null;
  }
}

/// One requirement found in the spec.
class Requirement {
  /// Creates a requirement.
  const new({
    required this.id,
    required this.release,
    required this.file,
    required this.line,
    required this.title,
  });

  /// The requirement ID, e.g. `DY-011`.
  final String id;

  /// The release it is planned for.
  final Release release;

  /// The spec file it is defined in, relative to the repo root
  /// (e.g. `spec/12-diary-meals-recipes.md`).
  final String file;

  /// The 1-based line number of the definition.
  final int line;

  /// The requirement text, with Markdown emphasis removed.
  final String title;

  /// `file:line`, for messages and the report.
  String get location => '$file:$line';

  /// A copy of this requirement planned for [release].
  Requirement withRelease(Release release) => Requirement(
    id: id,
    release: release,
    file: file,
    line: line,
    title: title,
  );

  @override
  String toString() => '$id [${release.label}] $location';
}
