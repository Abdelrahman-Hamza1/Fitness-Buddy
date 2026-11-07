import 'dart:typed_data';

import 'package:fb_mobile/core/photos/jpeg_check.dart';
import 'package:flutter_test/flutter_test.dart';

/// A JPEG's header bytes: SOI, an APP0 segment, then a SOF0 frame header
/// of [width] × [height] ([sof] picks another frame marker).
Uint8List jpeg(int width, int height, {int sof = 0xC0, int padding = 0}) =>
    Uint8List.fromList([
      0xFF, 0xD8, //
      0xFF, 0xE0, 0x00, 0x04, 0x00, 0x00, // APP0, 2 payload bytes
      0xFF, 0xC4, 0x00, 0x02, // DHT (no payload): not a frame
      0xFF, sof, 0x00, 0x08, 0x08, //
      height >> 8, height & 0xFF, width >> 8, width & 0xFF, 0x03,
      ...List.filled(padding, 0),
      0xFF, 0xD9,
    ]);

void main() {
  test('AI-011 a JPEG up to 1024 px on its long side is accepted', () {
    expect(JpegCheck.accept(jpeg(1024, 768)), (1024, 768));
    expect(JpegCheck.accept(jpeg(600, 1024, sof: 0xC2)), (600, 1024));
  });

  test('larger, empty, non-JPEG or too-heavy pictures are refused', () {
    expect(JpegCheck.accept(jpeg(1025, 800)), isNull);
    expect(JpegCheck.accept(jpeg(0, 800)), isNull);
    expect(
      JpegCheck.accept(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])),
      isNull,
    );
    expect(
      JpegCheck.accept(jpeg(800, 600, padding: JpegCheck.maxBytes)),
      isNull,
    );
    // A scan before any frame header: not readable.
    expect(
      JpegCheck.dimensions(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xDA, 0x00, 0x02, 0xFF, 0xD9]),
      ),
      isNull,
    );
  });

  test('A69 review: EXIF (APP1), other APPn and comments are stripped; '
      'JFIF, tables, frame and scan stay byte for byte', () {
    final exif = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00, 0x47, 0x50, 0x53];
    final input = Uint8List.fromList([
      0xFF, 0xD8, //
      0xFF, 0xE0, 0x00, 0x04, 0x4A, 0x46, // APP0 (kept)
      0xFF, 0xE1, 0x00, exif.length + 2, ...exif, // APP1 Exif
      0xFF, 0xEE, 0x00, 0x03, 0x41, // APP14 Adobe
      0xFF, 0xFE, 0x00, 0x04, 0x68, 0x69, // COM
      0xFF, 0xDB, 0x00, 0x03, 0x01, // DQT (kept)
      0xFF, 0xC0, 0x00, 0x08, 0x08, 0x00, 0x10, 0x00, 0x20, 0x03, // SOF0
      0xFF, 0xDA, 0x00, 0x03, 0x01, 0x12, 0x34, 0xFF, 0x00, 0x56, // scan
      0xFF, 0xD9,
    ]);
    final out = JpegCheck.stripMetadata(input)!;
    expect(out, [
      0xFF, 0xD8, //
      0xFF, 0xE0, 0x00, 0x04, 0x4A, 0x46,
      0xFF, 0xDB, 0x00, 0x03, 0x01,
      0xFF, 0xC0, 0x00, 0x08, 0x08, 0x00, 0x10, 0x00, 0x20, 0x03,
      0xFF, 0xDA, 0x00, 0x03, 0x01, 0x12, 0x34, 0xFF, 0x00, 0x56,
      0xFF, 0xD9,
    ]);
    expect(String.fromCharCodes(out).contains('Exif'), isFalse);
    expect(JpegCheck.dimensions(out), (32, 16));
    expect(JpegCheck.stripMetadata(Uint8List.fromList([1, 2, 3, 4])), isNull);
    // A segment longer than the file: not walkable.
    expect(
      JpegCheck.stripMetadata(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0x10, 0x00, 0x00]),
      ),
      isNull,
    );
  });

  test('A69 fix-check: metadata between scans and bytes after EOI go; '
      'stuffing and restarts stay in the scan data', () {
    const sof = [0xFF, 0xC2, 0x00, 0x08, 0x08, 0x00, 0x10, 0x00, 0x20, 0x03];
    const scan1 = [0xFF, 0xDA, 0x00, 0x03, 0x01, 0x11, 0xFF, 0x00, 0x22];
    const rst = [0xFF, 0xD0, 0x33];
    const scan2 = [0xFF, 0xDA, 0x00, 0x03, 0x02, 0x44, 0xFF, 0x00];
    final exif = 'Exif'.codeUnits;
    final input = Uint8List.fromList([
      0xFF, 0xD8, ...sof, ...scan1, ...rst, //
      0xFF, 0xE1, 0x00, exif.length + 2, ...exif, // APP1 between scans
      0xFF, 0xFE, 0x00, 0x03, 0x21, // COM between scans
      ...scan2,
      0xFF, 0xD9,
      ...'GPS trailer'.codeUnits, // after EOI
    ]);
    final out = JpegCheck.stripMetadata(input)!;
    expect(out, [
      0xFF, 0xD8, ...sof, ...scan1, ...rst, ...scan2, 0xFF, 0xD9, //
    ]);
    expect(String.fromCharCodes(out).contains('Exif'), isFalse);
    expect(String.fromCharCodes(out).contains('GPS'), isFalse);
    // No EOI: not a whole JPEG.
    expect(
      JpegCheck.stripMetadata(Uint8List.fromList([0xFF, 0xD8, ...scan1])),
      isNull,
    );
  });
}
