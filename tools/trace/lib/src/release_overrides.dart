import 'package:fb_trace/src/requirement.dart';

/// A release assigned in code to a requirement the spec leaves untagged.
class ReleaseOverride {
  /// Creates an override to [release], justified by [reason].
  const new(this.release, this.reason);

  /// The release the requirement is counted in.
  final Release release;

  /// Why: the spec rule that puts the requirement in [release].
  final String reason;
}

// AT-004: the speed targets in 30-ux-principles.md §1 are R1 acceptance
// criteria, but their table has no Release column.
const _speedTarget = ReleaseOverride(
  Release.r1,
  'AT-004: the speed targets are R1 acceptance criteria',
);

// AT-002: the AI test set must meet every threshold in
// 40-acceptance-criteria.md §2 for R1, but that table has no Release column.
const _aiThreshold = ReleaseOverride(
  Release.r1,
  'AT-002: the AI quality thresholds are R1 acceptance criteria',
);

/// Releases for table-defined requirements whose table has no Release column.
///
/// Applied only to untagged IDs. An entry for a tagged or unknown ID is
/// ignored with a warning, so stale entries surface after a spec change.
/// Remove entries once the spec tags these rows itself.
const Map<String, ReleaseOverride> releaseOverrides = {
  'UX-001': _speedTarget,
  'UX-002': _speedTarget,
  'UX-003': _speedTarget,
  'UX-004': _speedTarget,
  'UX-005': _speedTarget,
  'UX-006': _speedTarget,
  'UX-007': _speedTarget,
  'AQ-01': _aiThreshold,
  'AQ-02': _aiThreshold,
  'AQ-03': _aiThreshold,
  'AQ-04': _aiThreshold,
  'AQ-05': _aiThreshold,
  'AQ-06': _aiThreshold,
  'AQ-07': _aiThreshold,
  'AQ-08': _aiThreshold,
  'AQ-09': _aiThreshold,
  'AQ-10': _aiThreshold,
  // AQ-11's own text calls it the "R2 gate" (D-080): in R1 the per-language
  // scores are only reported.
  'AQ-11': ReleaseOverride(
    Release.r2,
    'AQ-11 is the R2 gate for Arabic/Arabizi parity (D-080)',
  ),
  'AQ-12': _aiThreshold,
};

/// Applies [overrides] to the untagged entries of [requirements].
///
/// Returns the updated requirements (same order) and a warning for every
/// override that targets a tagged ID or an ID that is not in the spec.
({List<Requirement> requirements, List<String> warnings}) applyOverrides(
  List<Requirement> requirements,
  Map<String, ReleaseOverride> overrides,
) {
  final byId = {for (final r in requirements) r.id: r};
  final warnings = <String>[];
  for (final MapEntry(key: id, value: override) in overrides.entries) {
    final target = byId[id];
    final ignored = 'Override $id -> ${override.release.label} ignored';
    if (target == null) {
      warnings.add('$ignored: no such ID in the spec');
    } else if (target.release != Release.untagged) {
      warnings.add(
        '$ignored: ${target.location} already tags it '
        '${target.release.label}',
      );
    }
  }
  final updated = [
    for (final r in requirements)
      if (overrides[r.id] case final override?
          when r.release == Release.untagged)
        r.withRelease(override.release)
      else
        r,
  ];
  return (requirements: updated, warnings: warnings);
}
