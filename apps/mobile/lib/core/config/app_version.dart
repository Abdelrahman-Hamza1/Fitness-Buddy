import 'package:flutter/foundation.dart';

/// A `MAJOR.MINOR.PATCH` app version, compared numerically (S06 plan D10):
/// `0.1.10` is newer than `0.1.9`.
///
/// Used by the update gate to compare the installed version with the
/// server's `minimumAppVersion`. Anything else (a suffix, a fourth part,
/// a sign, an empty part) doesn't parse, and the gate then fails open:
/// a typo in the server config must never lock everyone out.
@immutable
final class AppVersion implements Comparable<AppVersion> {
  /// Creates a version from its parts (each zero or more).
  const new(this.major, this.minor, this.patch)
    : assert(major >= 0 && minor >= 0 && patch >= 0, 'negative part');

  /// The lowest version, `0.0.0`: no installed version is below it.
  static const zero = AppVersion(0, 0, 0);

  /// Parses `MAJOR.MINOR.PATCH` (digits only, at most 9 per part), or
  /// returns null.
  static AppVersion? tryParse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    int part(int group) => int.parse(match.group(group)!);
    return AppVersion(part(1), part(2), part(3));
  }

  /// Whether an app at [installed] is too old for a server that requires
  /// [minimum]. False when either doesn't parse (fail open, S06 plan A8).
  static bool isBelowMinimum({
    required String installed,
    required String minimum,
  }) {
    final own = tryParse(installed);
    final required = tryParse(minimum);
    return own != null && required != null && own < required;
  }

  // At most 9 digits per part, so a part always fits in an int.
  static final _pattern = RegExp(r'^(\d{1,9})\.(\d{1,9})\.(\d{1,9})$');

  /// The major part.
  final int major;

  /// The minor part.
  final int minor;

  /// The patch part.
  final int patch;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  /// Whether this version is older than [other].
  bool operator <(AppVersion other) => compareTo(other) < 0;

  /// Whether this version is newer than [other].
  bool operator >(AppVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
