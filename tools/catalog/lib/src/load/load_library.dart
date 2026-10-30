import 'dart:io';

import 'package:fb_catalog/src/load/schema.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:fb_catalog/src/model/library_data.dart';
import 'package:fb_text/fb_text.dart';
import 'package:json_schema/json_schema.dart';

/// Schema-checks the author-owned exercise seed before releasing any rows.
List<ExerciseSeed> loadExercises(
  File file,
  JsonSchema schema,
  List<CatalogIssue> issues,
) {
  final checked = readChecked(file, schema, issues);
  if (checked == null) return const [];
  final rows = (checked as Map<String, dynamic>)['exercises'] as List<dynamic>;
  final ids = <String>{};
  final result = <ExerciseSeed>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i] as Map<String, dynamic>;
    final id = row['id'] as String;
    final names =
        ((row['names'] as Map<String, dynamic>)['en'] as List<dynamic>)
            .cast<String>();
    if (!ids.add(id)) {
      issues.add(CatalogIssue(file.path, '/exercises/$i/id', 'duplicate $id'));
    }
    final keys = <String>{};
    for (final name in names) {
      final key = normalizeKey(name);
      if (key.isEmpty || !keys.add(key)) {
        issues.add(
          CatalogIssue(
            file.path,
            '/exercises/$i/names/en',
            'empty or duplicate normalized alias "$name"',
          ),
        );
      }
    }
    final primary = row['primary_muscle'] as String;
    final secondaries = (row['secondary_muscles'] as List<dynamic>)
        .cast<String>();
    // The schema checks the vocabulary and the count; these two rules span
    // fields (A37 D3).
    if (secondaries.toSet().length != secondaries.length ||
        secondaries.contains(primary)) {
      issues.add(
        CatalogIssue(
          file.path,
          '/exercises/$i/secondary_muscles',
          'secondary muscles must be distinct and differ from the primary',
        ),
      );
    }
    result.add(
      ExerciseSeed(
        id: id,
        names: List.unmodifiable(names),
        type: row['type'] as String,
        equipment: row['equipment'] as String,
        primaryMuscle: primary,
        secondaryMuscles: List.unmodifiable(secondaries),
      ),
    );
  }
  return result;
}

/// Pinned IANA Zone and Link names, including backward-compatible aliases.
Set<String> loadTimezones(File file) => file
    .readAsLinesSync()
    .where((line) => line.isNotEmpty && !line.startsWith('#'))
    .toSet();

const cityHeader =
    'id\tname_en\tname_ar\tcountry_code\tadmin1\tlat\tlon\t'
    'timezone\tpopulation';

/// Parses the committed subset. A malformed row never reaches the pack.
List<CitySeed> loadCities(
  File file,
  Set<String> zones,
  List<CatalogIssue> issues,
) {
  final lines = file.readAsLinesSync();
  if (lines.isEmpty || lines.first != cityHeader) {
    issues.add(CatalogIssue(file.path, '', 'invalid city TSV header'));
    return const [];
  }
  final ids = <String>{};
  final cities = <CitySeed>[];
  for (var i = 1; i < lines.length; i++) {
    try {
      final city = parseCity(lines[i].split('\t'), zones);
      if (!ids.add(city.id)) throw const FormatException('duplicate city ID');
      cities.add(city);
    } on FormatException catch (e) {
      issues.add(CatalogIssue(file.path, '/line/${i + 1}', e.message));
    }
  }
  return cities;
}

/// City display English is ASCII with a small, searchable punctuation set.
bool isEnglishCityName(String name) =>
    name.trim().isNotEmpty && !RegExp(r"[^A-Za-z0-9 '. ,\-]").hasMatch(name);

/// Arabic display names contain letters/marks, never tagged Latin transliteration.
bool isArabicCityName(String name) {
  final script = RegExp(r'^\p{Script=Arabic}$', unicode: true);
  final letter = RegExp(r'^\p{L}$', unicode: true);
  final mark = RegExp(r'^\p{M}$', unicode: true);
  var hasLetter = false;
  for (final rune in name.runes) {
    if (rune == 0x20) continue;
    final char = String.fromCharCode(rune);
    if (script.hasMatch(char) && letter.hasMatch(char)) {
      hasLetter = true;
    } else if (!(mark.hasMatch(char) &&
        (script.hasMatch(char) || (rune >= 0x64b && rune <= 0x65f)))) {
      return false;
    }
  }
  return hasLetter;
}

/// Validates a TSV row from either the importer or the committed subset.
CitySeed parseCity(List<String> c, Set<String> zones) {
  if (c.length != 9) throw const FormatException('city needs nine columns');
  if (!isEnglishCityName(c[1])) {
    throw const FormatException(
      'city name_en must use plain Latin ASCII and simple punctuation',
    );
  }
  if (c[2].isNotEmpty && !isArabicCityName(c[2])) {
    throw const FormatException(
      'city name_ar must use Arabic letters, spaces and diacritics',
    );
  }
  final lat = double.tryParse(c[5]);
  final lon = double.tryParse(c[6]);
  final pop = c[8].isEmpty ? null : int.tryParse(c[8]);
  if (!RegExp(r'^city:[1-9][0-9]*$').hasMatch(c[0]) ||
      c[0].length > 64 ||
      c[1].trim().isEmpty ||
      !RegExp(r'^[A-Z]{2}$').hasMatch(c[3]) ||
      lat == null ||
      !lat.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lon == null ||
      !lon.isFinite ||
      lon < -180 ||
      lon > 180 ||
      !zones.contains(c[7]) ||
      (c[8].isNotEmpty && (pop == null || pop < 0))) {
    throw const FormatException(
      'invalid city ID, name, country, coordinates, '
      'IANA timezone or population',
    );
  }
  return CitySeed(
    id: c[0],
    nameEn: c[1],
    nameAr: c[2].isEmpty ? null : c[2],
    countryCode: c[3],
    admin1: c[4].isEmpty ? null : c[4],
    lat: lat,
    lon: lon,
    timezone: c[7],
    population: pop,
  );
}

/// Canonical TSV, stable across input ordering and operating systems.
String encodeCities(Iterable<CitySeed> cities) {
  final sorted = cities.toList()..sort((a, b) => a.id.compareTo(b.id));
  final lines = [
    for (final c in sorted)
      [
        c.id,
        c.nameEn,
        c.nameAr ?? '',
        c.countryCode,
        c.admin1 ?? '',
        c.lat,
        c.lon,
        c.timezone,
        c.population ?? '',
      ].join('\t'),
  ];
  return '$cityHeader\n${lines.join('\n')}\n';
}
