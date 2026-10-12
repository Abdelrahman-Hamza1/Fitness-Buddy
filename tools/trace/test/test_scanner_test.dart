import 'package:fb_trace/fb_trace.dart';
import 'package:fb_trace/src/comment_stripper.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final dartSource = fixture('dart_tests.txt');
  final csharpSource = fixture('csharp_tests.txt');

  group('Dart:', () {
    test('AT-001 scans leading IDs in Dart test()/testWidgets()/group() '
        'names', () {
      expect(idsInDartTests(dartSource), {
        'ZZ-001', 'ZZ-002', // group, two leading IDs
        'ZZ-003', 'ZZ-004', // comma-separated
        'ZZ-005', // double quotes
        'ZZ-006', 'ZZ-007', // raw strings, literal on the next line
        'ZZ-008', // triple quotes
        'ZZ-010', 'ZZ-011', 'ZZ-012', // testWidgets, patrolTest, goldenTest
        'ZZ-030', 'ZZ-031', 'ZZ-032', // covers lists
      });
    });

    test('AT-001 does not count an ID in the middle of a test name', () {
      final ids = idsInDartTests(dartSource);

      expect(ids, isNot(contains('ZZ-020'))); // mid-name
      expect(ids.where((id) => id.startsWith('ZZ-021')), isEmpty);
      expect(ids, isNot(contains('ZZ-022'))); // expect(), not a test call
      expect(ids, isNot(contains('ZZ-023'))); // mytest()
      expect(ids, isNot(contains('ZZ-024'))); // harness.test()
    });
  });

  group('comments:', () {
    final dartComments = fixture('dart_comments.txt');
    final csharpComments = fixture('csharp_comments.txt');

    test('AT-001 ignores tests in line and block comments (Dart)', () {
      final ids = idsInDartTests(dartComments);

      for (final id in [
        'ZZ-050', 'ZZ-051', // line and doc comments
        'ZZ-052', 'ZZ-053', 'ZZ-054', // block, multi-line, nested
        'ZZ-055', 'ZZ-056', 'ZZ-057', // after code on the same line
      ]) {
        expect(ids, isNot(contains(id)), reason: id);
      }
    });

    test('AT-001 keeps the covers lists that are themselves comments', () {
      expect(idsInDartTests(dartComments), contains('ZZ-070'));
      expect(idsInCSharpTests(csharpComments), contains('ZZ-096'));
    });

    test('AT-001 does not take // or /* inside a string for a comment '
        '(Dart)', () {
      expect(idsInDartTests(dartComments), {
        'ZZ-060', // after a block comment
        'ZZ-061', 'ZZ-062', // after a URL and an opening marker in a string
        'ZZ-063', 'ZZ-064', // in a test name
        'ZZ-065', // raw string ending in a backslash
        'ZZ-066', 'ZZ-067', // escaped quote
        'ZZ-068', 'ZZ-069', // triple quotes holding a quote
        'ZZ-070', // covers list
        'ZZ-071', 'ZZ-072', // string in an interpolation
        'ZZ-073', // multi-line triple-quoted name
      });
    });

    test('AT-001 ignores commented-out C# Trait', () {
      final ids = idsInCSharpTests(csharpComments);

      for (final id in [
        'ZZ-080', 'ZZ-081', 'ZZ-082', 'ZZ-083', // line, doc, block comments
        'ZZ-084', 'ZZ-085', 'ZZ-086', 'ZZ-087', 'ZZ-088', // after code
      ]) {
        expect(ids, isNot(contains(id)), reason: id);
      }
    });

    test(
      'AT-001 does not take // or /* inside a string for a comment (C#)',
      () {
        expect(idsInCSharpTests(csharpComments), {
          'ZZ-090', // a real trait before a line comment
          'ZZ-091', 'ZZ-092', // after a URL and an opening marker in a string
          'ZZ-093', 'ZZ-094', // verbatim with "" escapes, raw string
          'ZZ-095', // block comments don't nest
          'ZZ-096', // covers list
        });
      },
    );

    test('AT-001 blanks comments but keeps offsets and line breaks', () {
      const source = "a /* b\nc */ d // e\r\nf '// g' h";
      final expected = "a${' ' * 5}\n${' ' * 5}d${' ' * 5}\r\nf '// g' h";

      expect(stripDartComments(source), expected);
      expect(
        stripCSharpComments(source.replaceAll("'", '"')),
        expected.replaceAll("'", '"'),
      );
    });
  });

  test('AT-001 scans // covers: lists in Dart and C#', () {
    expect(idsInDartTests(dartSource), containsAll(['ZZ-030', 'ZZ-031']));
    expect(idsInDartTests(dartSource), contains('ZZ-032'));
    expect(idsInCSharpTests(csharpSource), containsAll(['ZZ-043', 'ZZ-044']));
  });

  test('AT-001 scans C# [Trait("Req", "AC-012")]', () {
    expect(idsInCSharpTests(csharpSource), {
      'ZZ-040',
      'ZZ-041',
      'ZZ-043',
      'ZZ-044',
    });
  });

  group('walking the repo:', () {
    test('AT-001 only scans test folders under apps, packages, tools and '
        'backend/tests', () {
      final root = tempRepo({
        'apps/app/test/a_test.dart': dartSource,
        'apps/app/integration_test/b_test.dart': dartSource,
        'packages/p/test/unit/c_test.dart': dartSource,
        'tools/t/test/d_test.dart': dartSource,
        'backend/tests/X.Tests/ZzTests.cs': csharpSource,
        'apps/app/lib/not_a_test.dart': dartSource,
        'packages/p/test/e_test.txt': dartSource,
        'other/test/f_test.dart': dartSource,
        'backend/src/Y/NotATest.cs': csharpSource,
      });

      final coverage = const TestScanner().scan(root);

      expect(coverage['ZZ-001'], [
        'apps/app/integration_test/b_test.dart',
        'apps/app/test/a_test.dart',
        'packages/p/test/unit/c_test.dart',
        'tools/t/test/d_test.dart',
      ]);
      expect(coverage['ZZ-040'], ['backend/tests/X.Tests/ZzTests.cs']);
    });

    test('AT-001 skips .dart_tool, build, bin, obj and trace fixtures', () {
      final root = tempRepo({
        'packages/p/.dart_tool/test/a_test.dart': dartSource,
        'packages/p/build/test/b_test.dart': dartSource,
        'packages/p/bin/test/c_test.dart': dartSource,
        'backend/tests/X.Tests/bin/Debug/ZzTests.cs': csharpSource,
        'backend/tests/X.Tests/obj/ZzTests.cs': csharpSource,
        'tools/trace/test/fixtures/d_test.dart': dartSource,
      });

      expect(const TestScanner().scan(root), isEmpty);
    });
  });
}
