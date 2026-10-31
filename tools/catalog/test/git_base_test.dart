import 'package:fb_catalog/fb_catalog.dart';
import 'package:test/test.dart';

void main() {
  // The tool runs inside the repo, so HEAD names a commit.
  test('a given base ref that names a commit is used as is', () {
    expect(resolveBaseRef(flag: 'HEAD'), 'HEAD');
  });

  test('a mistyped base ref fails instead of passing as "no lock" (#70)', () {
    expect(
      () => resolveBaseRef(flag: 'origin/mian-does-not-exist'),
      throwsA(isA<FormatException>()),
    );
  });

  test('a base ref that looks like an option is refused', () {
    expect(
      () => resolveBaseRef(flag: '--all'),
      throwsA(isA<FormatException>()),
    );
  });
}
