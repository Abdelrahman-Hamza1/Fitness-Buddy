import 'package:fb_catalog/fb_catalog.dart';
import 'package:test/test.dart';

Future<List<List<String>>> parse(List<String> chunks) =>
    readCsv(Stream.fromIterable(chunks)).toList();

void main() {
  test(
    'csv reader handles quotes, doubled quotes and commas in fields',
    () async {
      final rows = await parse([
        'a,b,c\n"x, y","say ""hi""",\n"multi\nline",2,3',
      ]);
      expect(rows, [
        ['a', 'b', 'c'],
        ['x, y', 'say "hi"', ''],
        ['multi\nline', '2', '3'],
      ]);
    },
  );

  test('csv reader copes with CRLF, blank lines and split chunks', () async {
    final rows = await parse(['"a""', '",b\r', '\n\r\nc,"d"', '\n']);
    expect(rows, [
      ['a"', 'b'],
      ['c', 'd'],
    ]);
  });

  test('csv reader rejects a file that ends inside quotes', () {
    expect(parse(['a,"b']), throwsFormatException);
  });
}
