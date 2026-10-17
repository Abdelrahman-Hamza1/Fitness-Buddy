/// Where the offline catalog pack is (A01 D14): the seam A05 fills.
///
/// The database attaches the pack read-only as the `catalog` schema when it
/// opens. Catalog tables are read with `customSelect('… FROM catalog.<t>')`
/// or views A05 defines; A01 defines no catalog schema.
abstract interface class CatalogPackSource {
  /// The absolute path of the current pack file, or `null` when there is
  /// none (nothing is attached).
  ///
  /// Must not query `user.db` (it runs while the database opens); resolve
  /// from files only, never the network.
  Future<String?> currentPackPath();
}

/// A catalog pack couldn't be attached: [reason] says why (no paths, no
/// values).
final class CatalogAttachException implements Exception {
  /// The pack wasn't attached because of [reason].
  const new(this.reason);

  /// Why, like `the pack file does not exist`.
  final String reason;

  @override
  String toString() => 'CatalogAttachException: $reason';
}

/// No pack: nothing is attached (the default until A05).
final class NoCatalogPack implements CatalogPackSource {
  /// The empty source.
  const new();

  @override
  Future<String?> currentPackPath() async => null;
}
