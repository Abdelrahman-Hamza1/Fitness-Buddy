import 'dart:io';

import 'package:fb_catalog/src/load/load_catalog.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/validate/report.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// The data is not fit to build a pack from.
class PackException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What `buildPack` wrote.
class PackSummary {
  const new({
    required this.basics,
    required this.dishes,
    required this.variants,
    required this.skippedDrafts,
    required this.names,
    required this.bytes,
  });

  final int basics;
  final int dishes;
  final int variants;
  final int skippedDrafts;
  final int names;
  final int bytes;
}

const _core = ['kcal', 'protein', 'carbs', 'fat', 'fiber'];

List<double> _values(Nutrients n) => [
  n.kcal,
  n.protein,
  n.carbs,
  n.fat,
  n.fiber,
];

/// Writes the prototype pack (A03 D8, D9) to [out], replacing any old file.
///
/// Draft dishes are left out unless [includeDrafts]. Any loading or
/// validation error stops the build (the pack must not hold unvalidated data).
PackSummary buildPack({
  required CatalogData data,
  required ValidationReport report,
  required String out,
  bool includeDrafts = false,
}) {
  final errors = [...data.issues, ...report.errors];
  if (errors.isNotEmpty) {
    throw PackException(
      'cannot build: ${errors.length} validation error(s), first: '
      '${errors.first}',
    );
  }
  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  if (outFile.existsSync()) outFile.deleteSync();
  final dishes = [
    for (final d in data.dishes)
      if (includeDrafts || !d.isDraft) d,
  ]..sort((a, b) => a.id.compareTo(b.id));
  final basics = [...data.basics]..sort((a, b) => a.id.compareTo(b.id));

  final db = sqlite3.open(out);
  var names = 0;
  var variants = 0;
  try {
    db
      ..execute('PRAGMA journal_mode = OFF')
      ..execute(_ddl)
      ..execute('BEGIN');
    final addMeta = db.prepare('INSERT INTO meta VALUES (?, ?)');
    final addFood = db.prepare(
      'INSERT INTO foods VALUES (${List.filled(19, '?').join(', ')})',
    );
    final addDish = db.prepare('INSERT INTO dishes VALUES (?, ?, ?, ?)');
    final addName = db.prepare(
      'INSERT INTO names (target, lang, name, key, display) '
      'VALUES (?, ?, ?, ?, ?)',
    );
    final addServing = db.prepare(
      'INSERT INTO servings VALUES (?, ?, ?, ?, ?)',
    );

    void addNames(String target, Names byLang) {
      for (final lang in nameLanguages) {
        final list = byLang[lang] ?? const <String>[];
        for (var i = 0; i < list.length; i++) {
          final key = normalizeKey(list[i]);
          if (key.isEmpty) continue;
          addName.execute([target, lang, list[i], key, if (i == 0) 1 else 0]);
          names++;
        }
      }
    }

    for (final b in basics) {
      final n = b.nutrients!;
      final v = _values(n.rounded());
      addFood.execute([b.id, 'basic', null, b.state.name, ...v, ...v, ...v]);
      addNames(b.id, b.names);
    }
    for (final d in dishes) {
      addDish.execute([
        d.id,
        d.defaultVariant?.slug,
        d.review.status,
        d.timeMin,
      ]);
      addNames(d.id, d.names);
      for (final e in d.portions.entries) {
        addServing.execute([
          d.id,
          e.key,
          e.value.g,
          e.value.range.lo,
          e.value.range.hi,
        ]);
      }
      for (final v in d.variants) {
        final id = d.variantId(v);
        final c = report.computed[id];
        if (c == null) throw PackException('$id has no computed values');
        addFood.execute([
          id,
          'variant',
          d.id,
          d.state.name,
          ..._values(c.typical),
          ..._values(c.low),
          ..._values(c.high),
        ]);
        variants++;
        addNames(id, v.names);
        for (final e in v.portions.entries) {
          addServing.execute([
            id,
            e.key,
            e.value.g,
            e.value.range.lo,
            e.value.range.hi,
          ]);
        }
      }
    }
    db.execute(
      'INSERT INTO names_fts (rowid, key) SELECT rowid, key FROM names',
    );
    final skipped = data.dishes.length - dishes.length;
    for (final e in {
      'format': 'prototype-1',
      'includes_drafts': includeDrafts ? '1' : '0',
      'basics': '${basics.length}',
      'dishes': '${dishes.length}',
      'skipped_drafts': '$skipped',
    }.entries) {
      addMeta.execute([e.key, e.value]);
    }
    db.execute('COMMIT');
    for (final s in [addMeta, addFood, addDish, addName, addServing]) {
      s.close();
    }
  } finally {
    db.close();
  }
  return PackSummary(
    basics: basics.length,
    dishes: dishes.length,
    variants: variants,
    skippedDrafts: data.dishes.length - dishes.length,
    names: names,
    bytes: File(out).lengthSync(),
  );
}

String _cols(String prefix) =>
    [for (final c in _core) '${prefix}_$c REAL NOT NULL'].join(', ');

final String _ddl =
    '''
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL) WITHOUT ROWID;
CREATE TABLE foods (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  dish_id TEXT,
  state TEXT NOT NULL,
  ${_cols('typ')},
  ${_cols('lo')},
  ${_cols('hi')}
) WITHOUT ROWID;
CREATE TABLE dishes (
  id TEXT PRIMARY KEY,
  default_variant TEXT,
  review_status TEXT NOT NULL,
  time_min REAL
) WITHOUT ROWID;
CREATE TABLE names (
  target TEXT NOT NULL,
  lang TEXT NOT NULL,
  name TEXT NOT NULL,
  key TEXT NOT NULL,
  display INTEGER NOT NULL
);
CREATE INDEX names_key ON names (key);
CREATE TABLE servings (
  target TEXT NOT NULL,
  word TEXT NOT NULL,
  g REAL NOT NULL,
  lo REAL NOT NULL,
  hi REAL NOT NULL
);
CREATE VIRTUAL TABLE names_fts USING fts5(
  key, content='names', content_rowid='rowid', tokenize='trigram'
);
''';

/// Where `build` writes by default; under `build/`, which is gitignored.
String defaultPackPath(String root) =>
    p.join(root, 'build', 'catalog', 'catalog.db');
