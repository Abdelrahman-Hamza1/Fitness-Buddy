import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final String fixtureDir = p.join('test', 'fixtures');
final String realSchemaDir = p.join('..', '..', 'data', 'schema');
final String contractDir = p.join('..', '..', 'contracts', 'catalog');

/// A temporary `data/` folder built from the test fixtures: three basics,
/// five dishes (one reviewed), no yields or portion words. [extraDishes] are
/// fixture files (relative to `test/fixtures`) copied in as well.
Directory makeDataDir({List<String> extraDishes = const []}) {
  final dir = Directory.systemTemp.createTempSync('data_dir');
  addTearDown(() => dir.deleteSync(recursive: true));
  void copy(String from, String to) {
    File(to).parent.createSync(recursive: true);
    File(from).copySync(to);
  }

  copy(
    p.join(fixtureDir, 'selection.yaml'),
    p.join(dir.path, 'usda_selection.yaml'),
  );
  copy(
    p.join(fixtureDir, 'extract.jsonl'),
    p.join(dir.path, 'usda', 'extract.jsonl'),
  );
  copy(
    p.join(fixtureDir, 'must_cover.yaml'),
    p.join(dir.path, 'must_cover.yaml'),
  );
  for (final f in Directory(realSchemaDir).listSync().whereType<File>()) {
    copy(f.path, p.join(dir.path, 'schema', p.basename(f.path)));
  }
  for (final f in Directory(
    p.join(fixtureDir, 'pack'),
  ).listSync().whereType<File>()) {
    copy(f.path, p.join(dir.path, 'reference_dishes', p.basename(f.path)));
  }
  for (final extra in extraDishes) {
    copy(
      p.join(fixtureDir, extra),
      p.join(dir.path, 'reference_dishes', p.basename(extra)),
    );
  }
  return dir;
}
