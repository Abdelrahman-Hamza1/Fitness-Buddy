import 'dart:convert';
import 'dart:io';

/// Streams the records of an RFC 4180 CSV file as lists of fields, one record
/// at a time, so the 36 MB FDC files never sit in memory. Handles quoted
/// fields, doubled quotes (`""`), commas and line breaks inside quotes, and
/// `\n` or `\r\n` record ends. A trailing record without a final line break is
/// returned; a blank line is skipped.
Stream<List<String>> readCsv(Stream<String> chunks) async* {
  final field = StringBuffer();
  var record = <String>[];
  var inQuotes = false;
  // A quote seen inside a quoted field: either the end of the field or the
  // first half of `""`. Decided by the next character, even across chunks.
  var pendingQuote = false;
  var fieldStarted = false;

  List<String>? endRecord() {
    if (!fieldStarted && record.isEmpty) return null; // blank line
    record.add(field.toString());
    field.clear();
    fieldStarted = false;
    final done = record;
    record = <String>[];
    return done;
  }

  await for (final chunk in chunks) {
    for (var i = 0; i < chunk.length; i++) {
      final c = chunk[i];
      if (pendingQuote) {
        pendingQuote = false;
        if (c == '"') {
          field.write('"');
          continue;
        }
        inQuotes = false; // the quote closed the field; handle `c` below
      }
      if (inQuotes) {
        if (c == '"') {
          pendingQuote = true;
        } else {
          field.write(c);
        }
        continue;
      }
      switch (c) {
        case '"':
          inQuotes = true;
          fieldStarted = true;
        case ',':
          record.add(field.toString());
          field.clear();
          fieldStarted = true;
        case '\n':
          final done = endRecord();
          if (done != null) yield done;
        case '\r':
          break; // part of \r\n
        default:
          field.write(c);
          fieldStarted = true;
      }
    }
  }
  if (inQuotes && !pendingQuote) {
    throw const FormatException('CSV ends inside a quoted field');
  }
  final done = endRecord();
  if (done != null) yield done;
}

/// Streams the records of a CSV file as maps from header name to value. The
/// first record is the header. A record with a different field count than the
/// header throws a [FormatException] naming the file and record number.
Stream<Map<String, String>> readCsvFile(File file) async* {
  List<String>? header;
  var number = 0;
  await for (final record in readCsv(file.openRead().transform(utf8.decoder))) {
    number++;
    if (header == null) {
      // Drop a UTF-8 byte order mark if the file has one.
      header = [...record];
      if (header.first.startsWith('﻿')) {
        header[0] = header.first.substring(1);
      }
      continue;
    }
    if (record.length != header.length) {
      throw FormatException(
        '${file.path}: record $number has ${record.length} fields, '
        'expected ${header.length}',
      );
    }
    yield {for (var i = 0; i < header.length; i++) header[i]: record[i]};
  }
  if (header == null) {
    throw FormatException('${file.path}: empty CSV file');
  }
}
