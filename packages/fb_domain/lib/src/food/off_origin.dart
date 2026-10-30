import 'package:fb_domain/src/food/halal_check.dart';

/// What a personal food saved from an Open Food Facts scan remembers about
/// its origin (A28a review fix 2): that the data is OFF's (ODbL credit),
/// that fiber was not listed and was stored as 0, and the halal flags the
/// scan computed from the ingredients and tags (which the food itself
/// doesn't carry). Encoded in the existing `createdFrom` code, so no sync
/// field or migration is needed: `off` followed by `F` (fiber assumed 0),
/// `P` (pork), `A` (alcohol), `U` (unknown source), in that order. The wire
/// rule (letters only, at most 32) holds for every code.
final class OffOrigin {
  /// Creates the origin.
  const new({this.fiberAssumed = false, this.halal = const {}});

  /// Fiber wasn't listed and is stored as 0.
  final bool fiberAssumed;

  /// Halal flags computed at the scan.
  final Set<HalalFlag> halal;

  static final RegExp _code = RegExp(r'^off(F?)(P?)(A?)(U?)$');

  /// The `createdFrom` code for this origin.
  String encode() =>
      'off'
      '${fiberAssumed ? 'F' : ''}'
      '${halal.contains(HalalFlag.pork) ? 'P' : ''}'
      '${halal.contains(HalalFlag.alcohol) ? 'A' : ''}'
      '${halal.contains(HalalFlag.unknownSource) ? 'U' : ''}';

  /// The origin in [createdFrom], or null for a food not saved from OFF.
  static OffOrigin? decode(String createdFrom) {
    final m = _code.firstMatch(createdFrom);
    if (m == null) return null;
    return OffOrigin(
      fiberAssumed: m.group(1)!.isNotEmpty,
      halal: {
        if (m.group(2)!.isNotEmpty) HalalFlag.pork,
        if (m.group(3)!.isNotEmpty) HalalFlag.alcohol,
        if (m.group(4)!.isNotEmpty) HalalFlag.unknownSource,
      },
    );
  }

  /// A copy with another fiber assumption.
  OffOrigin withFiberAssumed({required bool assumed}) =>
      OffOrigin(fiberAssumed: assumed, halal: halal);
}
