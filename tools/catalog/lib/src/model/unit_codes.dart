/// The closed vocabulary of serving unit codes the catalog may ship (backlog
/// #88): mass, volume and portion words. The app shows each through its own
/// ARB word (`knownUnitLabel` in `apps/mobile/lib/core/l10n/domain_labels.dart`;
/// a test keeps the two lists in step), so a new code needs a word there
/// first, then an entry here. A code outside this list fails validation
/// instead of reaching the phone as a generic "portion".
const catalogUnitCodes = {
  // Mass and volume.
  'g', 'kg', 'oz', 'lb', 'ml', 'l', 'fl_oz', 'tbsp', 'tsp', 'cup',
  // Portion words.
  'piece', 'loaf', 'plate', 'small_plate', 'large_plate', 'glass',
  'sandwich', 'disc', 'serving', 'can', 'bowl', 'small_bowl', 'half',
  'quarter', 'whole', 'half_loaf', 'large_piece', 'small_piece',
  'large_sandwich', 'small_sandwich', 'meal', 'pan', 'two_pieces', 'slice',
  'wedge', 'container', 'ladle',
};
