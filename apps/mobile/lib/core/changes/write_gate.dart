/// Whether the open profile's database may be written (A33 §6): no while an
/// account transition runs, for a read-only kept copy, or for a profile that
/// is no longer the active one. Implemented by the account layer.
abstract interface class WriteGate {
  /// `null` when [profileKey] may be written by an applier created for
  /// profile [generation], else a fixed reason code (`transition`,
  /// `staleProfile`, `readOnlyProfile`, `inactiveProfile`). A `null`
  /// [profileKey] is a pinned database (an explicit switch, tests): no
  /// active-profile comparison; the generation still applies.
  Future<String?> denial(String? profileKey, {int? generation});
}
