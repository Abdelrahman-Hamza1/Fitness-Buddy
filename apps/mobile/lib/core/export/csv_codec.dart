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
    if (value is String && text.isNotEmpty && '=+-@\t\r'.contains(text[0])) {
      text = "'$text";
    }
    return text.contains(RegExp('[",\r\n]'))
        ? '"${text.replaceAll('"', '""')}"'
        : text;
  }

  final records = [header, ...rows].map((r) => r.map(cell).join(','));
  return Uint8List.fromList(utf8.encode('\ufeff${records.join('\r\n')}\r\n'));
}
