import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fb_catalog/src/load/load_library.dart';
import 'package:fb_catalog/src/load/yaml_json.dart';
import 'package:fb_catalog/src/model/library_data.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const regionCountries = {
  'IL',
  'LB',
  'SY',
  'EG',
  'SA',
  'IQ',
  'AE',
  'BH',
  'KW',
  'OM',
  'QA',
  'YE',
  'TR',
};

/// Language-certified current names, ranked independently of dump row order.
class CityNames {
  new(Iterable<String> lines) {
    for (final text in lines) {
      if (text.isEmpty) continue;
      final c = text.split('\t');
      if (c.length != 10) {
        throw const FormatException('GeoNames alternate: expected 10 columns');
      }
      if (!const {'ar', 'en'}.contains(c[2]) ||
          c[3].trim().isEmpty ||
          c[7] == '1' ||
          c[9].isNotEmpty) {
        continue;
      }
      final name = c[2] == 'ar'
          ? normalizeArabicCityName(c[3])
          : normalizeEnglishCityName(c[3]);
      if (c[2] == 'ar' ? !isArabicCityName(name) : !isEnglishCityName(name)) {
        continue;
      }
      final key = '${c[1]}:${c[2]}';
      final rank = c[4] == '1' ? 0 : 1;
      // EN only overrides asciiname when explicitly preferred; AR may use
      // a nonpreferred Arabic-language name, never another language's script.
      if (c[2] == 'en' && rank != 0) continue;
      final previous = _names[key];
      if (previous == null ||
          rank < previous.$1 ||
          (rank == previous.$1 && name.compareTo(previous.$2) < 0)) {
        _names[key] = (rank, name);
      }
    }
  }

  final _names = <String, (int, String)>{};

  String? get(String id, String language) => _names['$id:$language']?.$2;
}

/// Keep GeoNames apostrophe/dash variants within the display punctuation set.
String normalizeEnglishCityName(String name) => name
    .trim()
    .replaceAll(RegExp('[`‘’ʼʻ]'), "'")
    .replaceAll(RegExp('[‐‑–—]'), '-');

/// Fold equivalent Persian/Kurdish letter forms without stripping tashkeel.
String normalizeArabicCityName(String name) {
  const letters = {
    'ک': 'ك',
    'ڪ': 'ك',
    'ی': 'ي',
    'ے': 'ي',
    'ہ': 'ه',
    'ھ': 'ه',
    'ە': 'ه',
    'ۀ': 'ه',
  };
  var result = name.trim();
  for (final entry in letters.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result.replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e]'), '');
}

/// Reviewed ID exclusions; country and time zone never imply exclusion.
Set<String> loadCityExclusions(File file) {
  final lines = file
      .readAsLinesSync()
      .where((l) => !l.startsWith('#') && l.isNotEmpty)
      .toList();
  if (lines.isEmpty || lines.first != 'geonameid\tname') {
    throw const FormatException('expected GeoNames exclusion header');
  }
  final ids = <String>{};
  for (final line in lines.skip(1)) {
    final c = line.split('\t');
    if (c.length != 2 ||
        !RegExp(r'^[1-9][0-9]*$').hasMatch(c[0]) ||
        c[1].trim().isEmpty ||
        !ids.add(c[0])) {
      throw const FormatException('invalid or duplicate city exclusion');
    }
  }
  return ids;
}

/// Applies A05 D16 with language-tagged names and reviewed ID exclusions.
List<CitySeed> selectCities(
  Iterable<String> lines, {
  required bool localDataset,
  required Set<String> zones,
  CityNames? names,
  Map<String, Map<String, String>> nameOverrides = const {},
  Set<String> excludedIds = const {},
}) {
  final result = <CitySeed>[];
  final ids = <String>{};
  var line = 0;
  for (final text in lines) {
    line++;
    if (text.isEmpty) continue;
    final c = text.split('\t');
    if (c.length != 19) {
      throw FormatException('GeoNames line $line: expected 19 columns');
    }
    final local = c[8] == 'PS' || c[8] == 'JO';
    final population = int.tryParse(c[14]);
    if (population == null || population < 0) {
      throw FormatException('GeoNames line $line: invalid population');
    }
    final keep = localDataset
        ? local
        : !local && (regionCountries.contains(c[8]) || population >= 1000000);
    if (!keep || excludedIds.contains(c[0])) continue;
    if (c[6] != 'P') {
      throw FormatException('GeoNames line $line: not a populated place');
    }
    final city = parseCity([
      'city:${c[0]}',
      names?.get(c[0], 'en') ??
          nameOverrides[c[0]]?['en'] ??
          normalizeEnglishCityName(c[2]),
      names?.get(c[0], 'ar') ?? nameOverrides[c[0]]?['ar'] ?? '',
      c[8],
      c[10],
      c[4],
      c[5],
      c[17],
      c[14],
    ], zones);
    if (!ids.add(city.id)) {
      throw FormatException('duplicate GeoNames ID ${city.id}');
    }
    result.add(city);
  }
  return result;
}

/// Verifies pinned text extracts before importing them. Exact reproduction
/// requires retaining those downloads; the upstream daily URLs are mutable.
Future<List<CitySeed>> importCities({
  required Directory directory,
  required File sources,
  required Set<String> zones,
}) async {
  final Object? plain;
  try {
    plain = yamlToPlain(loadYamlNode(sources.readAsStringSync()));
  } on YamlException catch (e) {
    throw FormatException('${sources.path}: invalid YAML: ${e.message}');
  }
  if (plain is! Map<String, dynamic> || plain['datasets'] is! List<dynamic>) {
    throw FormatException('${sources.path}: expected a datasets list');
  }
  final datasets = plain['datasets']! as List<dynamic>;
  for (final pin in datasets) {
    if (pin is! Map<String, dynamic> ||
        pin['name'] is! String ||
        pin['text_sha256'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(pin['text_sha256']! as String)) {
      throw FormatException(
        '${sources.path}: invalid dataset name/text_sha256',
      );
    }
  }
  final expected = {
    'cities1000',
    'cities15000',
    'PS',
    'JO',
    ...regionCountries,
  };
  if (datasets.length != expected.length ||
      !expected.every(
        (name) =>
            datasets
                .cast<Map<String, dynamic>>()
                .where((d) => d['name'] == name)
                .length ==
            1,
      )) {
    throw FormatException(
      '${sources.path}: expected city dumps and all local/regional alternate pins',
    );
  }
  final texts = <String, List<String>>{};
  for (final pin in datasets.cast<Map<String, dynamic>>()) {
    final name = pin['name']! as String;
    final file = File(p.join(directory.path, '$name.txt'));
    final hash = (await sha256.bind(file.openRead()).first).toString();
    if (hash != pin['text_sha256']) {
      throw FormatException(
        '$name: text checksum mismatch; retain the pinned download or '
        'explicitly review and refresh sources.yaml',
      );
    }
    texts[name] = await file.readAsLines();
  }
  final names = CityNames(
    expected.where((n) => n.length == 2).expand((n) => texts[n]!),
  );
  final exclusions = loadCityExclusions(
    File(p.join(sources.parent.path, 'excluded_cities.tsv')),
  );
  final overrides = <String, Map<String, String>>{};
  final rawOverrides = plain['name_overrides'];
  if (rawOverrides is Map<String, dynamic>) {
    for (final entry in rawOverrides.entries) {
      overrides[entry.key] = (entry.value as Map<String, dynamic>)
          .cast<String, String>();
    }
  }
  final all = <CitySeed>[];
  for (final name in ['cities1000', 'cities15000']) {
    all.addAll(
      selectCities(
        texts[name]!,
        names: names,
        excludedIds: exclusions,
        nameOverrides: overrides,
        localDataset: name == 'cities1000',
        zones: zones,
      ),
    );
  }
  if (all.map((c) => c.id).toSet().length != all.length) {
    throw const FormatException('duplicate city IDs across source datasets');
  }
  return all..sort((a, b) => a.id.compareTo(b.id));
}
