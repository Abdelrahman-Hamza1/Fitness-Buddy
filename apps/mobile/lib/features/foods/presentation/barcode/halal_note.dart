import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';

/// The halal flags as one calm line (FD-081): "unknown" stays unknown, and
/// it's a warning, never a block. Null when there's nothing to say.
String? halalMessage(AppLocalizations l10n, Set<HalalFlag> flags) {
  if (flags.isEmpty) return null;
  final items = [
    if (flags.contains(HalalFlag.pork)) l10n.halalMayContainPork,
    if (flags.contains(HalalFlag.alcohol)) l10n.halalMayContainAlcohol,
    if (flags.contains(HalalFlag.unknownSource)) l10n.halalUnknownSource,
  ];
  return l10n.halalCheckMessage(items.join(l10n.halalItemSeparator));
}
