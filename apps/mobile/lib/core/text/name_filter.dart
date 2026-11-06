import 'package:fb_text/fb_text.dart' show normalizeKey;

/// Whether any of [names] contains [query] after search folding (A65 m13):
/// case, Arabic letter forms, tashkeel and digits don't matter, so "Labneh"
/// finds "labneh" and an Arabic name finds its folded form. A blank query
/// matches everything. User content: never logged.
bool namesMatch(Iterable<String?> names, String query) {
  final key = normalizeKey(query);
  if (key.isEmpty) return true;
  for (final name in names) {
    if (name != null && normalizeKey(name).contains(key)) return true;
  }
  return false;
}

/// A list grows a search field once it has more than this many items.
const int listSearchThreshold = 8;
