/// The append-only ID lock `data/catalog_ids.lock` (A05 D2, TD-071).
///
/// One sorted line per released catalog ID:
/// `<id>\t<kind>\t<first_version>\t<status>`. Kinds: food (a basic), dish,
/// variant, exercise, city. Status: active or retired. Lines starting with
/// `#` are comments.
library;

/// The catalog ID kinds that are locked.
const lockKinds = {'food', 'dish', 'variant', 'exercise', 'city'};

/// `usda:<slug>`, `ref:<slug>`, `ref:<slug>/<variant>` (A05 D1), at most 64
/// ASCII characters. Exercise and city IDs use separate patterns below.
final foodIdPattern = RegExp(
  r'^(usda|ref):[a-z0-9][a-z0-9_]*(/[a-z0-9][a-z0-9_]*)?$',
);

/// Whether [id] is a well-formed food, dish or variant ID.
bool isValidFoodId(String id) => id.length <= 64 && foodIdPattern.hasMatch(id);

/// Whether an ID belongs to any released catalog kind (A05 D1).
bool isValidCatalogId(String id) =>
    id.length <= 64 &&
    (isValidFoodId(id) ||
        RegExp(r'^ex:[a-z0-9_]+$').hasMatch(id) ||
        RegExp(r'^city:[1-9][0-9]*$').hasMatch(id));

/// One released ID.
class LockEntry {
  const new({
    required this.id,
    required this.kind,
    required this.firstVersion,
    this.retired = false,
  });

  final String id;
  final String kind;

  /// The `catalog_version` the ID was first released in.
  final int firstVersion;
  final bool retired;

  String get line =>
      '$id\t$kind\t$firstVersion\t${retired ? 'retired' : 'active'}';
}

/// The lock file is malformed.
class LockFormatException implements FormatException {
  const new(this.message);

  @override
  final String message;

  @override
  int? get offset => null;

  @override
  dynamic get source => null;

  @override
  String toString() => message;
}

class IdLock {
  new(Iterable<LockEntry> entries)
    : entries = {for (final e in entries) e.id: e};

  const new empty() : entries = const {};

  /// Parses the text of the lock file (strict: bad lines throw).
  factory parse(String text, {String source = 'catalog_ids.lock'}) {
    final entries = <LockEntry>[];
    final seen = <String>{};
    var n = 0;
    for (final line in text.split('\n')) {
      n++;
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      final f = line.split('\t');
      final version = f.length == 4 ? int.tryParse(f[2]) : null;
      if (f.length != 4 ||
          !lockKinds.contains(f[1]) ||
          version == null ||
          version < 1 ||
          !const {'active', 'retired'}.contains(f[3])) {
        throw LockFormatException(
          '$source:$n: expected id, kind, version and status separated by '
          'tabs, got "$line"',
        );
      }
      if (!seen.add(f[0])) {
        throw LockFormatException('$source:$n: duplicate id ${f[0]}');
      }
      entries.add(
        LockEntry(
          id: f[0],
          kind: f[1],
          firstVersion: version,
          retired: f[3] == 'retired',
        ),
      );
    }
    return IdLock(entries);
  }

  final Map<String, LockEntry> entries;

  /// The file text: header, then the lines sorted by ID.
  String format() {
    final ids = entries.keys.toList()..sort();
    return '$lockHeader${[for (final id in ids) entries[id]!.line].join('\n')}'
        '${ids.isEmpty ? '' : '\n'}';
  }

  /// A copy with [added] appended (existing entries are never changed).
  IdLock plus(Iterable<LockEntry> added) =>
      IdLock([...entries.values, ...added]);
}

const lockHeader = '''
# Catalog ID lock (A05 D2, TD-071). Append-only: never edit or delete a line.
# <id>	<kind>	<first catalog_version>	<active|retired>
# `make catalog` appends new released IDs. Retire an ID by changing only its
# status to `retired`; a retired ID is never reused. Drafts are never locked.
''';

/// Problems between the lock at the merge base and the lock now: a locked ID
/// was removed or changed, or a retired ID was revived.
List<String> compareWithBase(IdLock base, IdLock head) {
  final problems = <String>[];
  for (final b in base.entries.values) {
    final h = head.entries[b.id];
    if (h == null) {
      problems.add(
        'locked ID ${b.id} was removed from the lock (IDs are forever; '
        'retire it instead)',
      );
    } else if (h.kind != b.kind || h.firstVersion != b.firstVersion) {
      problems.add(
        'locked ID ${b.id} changed: ${b.kind}/v${b.firstVersion} -> '
        '${h.kind}/v${h.firstVersion}',
      );
    } else if (b.retired && !h.retired) {
      problems.add('retired ID ${b.id} is active again (IDs are never reused)');
    }
  }
  return problems;
}

/// What the data says about the lock: [released] maps each released ID to its
/// kind. Problems that `make catalog` cannot fix are in `errors`; IDs it can
/// append are in `missing`.
({List<String> errors, List<String> missing}) compareWithData(
  IdLock lock,
  Map<String, String> released,
) {
  final errors = <String>[];
  final missing = <String>[];
  for (final MapEntry(key: id, value: kind) in released.entries) {
    final e = lock.entries[id];
    if (e == null) {
      missing.add(id);
    } else if (e.retired) {
      errors.add('retired ID $id is back in the data (IDs are never reused)');
    } else if (e.kind != kind) {
      errors.add('ID $id changed kind: locked as ${e.kind}, data says $kind');
    }
  }
  for (final e in lock.entries.values) {
    if (!e.retired && !released.containsKey(e.id)) {
      errors.add(
        'released ID ${e.id} is gone from the data (a rename or a delete); '
        'restore it, or set its lock status to `retired`',
      );
    }
  }
  missing.sort();
  return (errors: errors, missing: missing);
}
