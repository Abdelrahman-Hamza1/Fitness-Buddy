import 'dart:convert';
import 'dart:typed_data';

/// RFC 4180, Excel UTF-8 BOM, CRLF and text-only formula protection.
Uint8List encodeCsv(List<String> header, Iterable<List<Object?>> rows) {
  String cell(Object? value) {
    var text = value?.toString() ?? '';
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    }
    // Spreadsheet importers can discard whitespace, controls and invisible
    // format characters before interpreting formulas. Prefix the original.
    final effective = text.replaceFirst(
      RegExp(
        r'^[\s\x00-\x20\x7f-\x9f\u00a0\u1680\u180e\u2000-\u200f\u2028-\u202f\u205f\u2060-\u206f\u3000\ufeff]*',
      ),
      '',
    );
    if (value is String &&
        text.isNotEmpty &&
        (effective.isNotEmpty && '=+-@'.contains(effective[0]) ||
            text.startsWith('\t') ||
            text.startsWith('\r'))) {
      text = "'$text";
    }
    return text.contains(RegExp('[",\r\n]'))
        ? '"${text.replaceAll('"', '""')}"'
        : text;
  }

  final records = [header, ...rows].map((r) => r.map(cell).join(','));
  return Uint8List.fromList(utf8.encode('\ufeff${records.join('\r\n')}\r\n'));
}
