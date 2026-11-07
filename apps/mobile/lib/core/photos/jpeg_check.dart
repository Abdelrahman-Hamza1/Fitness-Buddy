import 'dart:typed_data';

/// What the contract takes as a photo (A69 D6, `BuddyTurnMessage.image`,
/// `BuddyLabelRequest`): a JPEG at most [maxSide] px on its long side and
/// small enough that its base64 stays within 400 000 characters.
abstract final class JpegCheck {
  /// The longest side, px.
  static const int maxSide = 1024;

  /// The most bytes (base64 of it ≤ 400 000 characters).
  static const int maxBytes = 300000;

  /// The image's (width, height) when [bytes] is a JPEG the contract
  /// accepts, else `null`. Reads the frame header only; never logs.
  static (int, int)? accept(Uint8List bytes) {
    if (bytes.length < 4 || bytes.length > maxBytes) return null;
    final size = dimensions(bytes);
    if (size == null) return null;
    final (w, h) = size;
    return w > 0 && h > 0 && w <= maxSide && h <= maxSide ? size : null;
  }

  /// The (width, height) of JPEG [bytes] from its first frame header
  /// (SOF0–SOF15 but DHT, JPG and DAC), or `null` when it isn't a JPEG.
  static (int, int)? dimensions(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
    var i = 2;
    while (i + 3 < bytes.length) {
      if (bytes[i] != 0xFF) return null;
      final marker = bytes[i + 1];
      if (marker == 0xFF) {
        i++;
        continue;
      }
      // Markers without a length.
      if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
        i += 2;
        continue;
      }
      if (marker == 0xD9 || marker == 0xDA) return null;
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      if (length < 2) return null;
      final isFrame =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isFrame) {
        if (i + 8 >= bytes.length) return null;
        final height = (bytes[i + 5] << 8) | bytes[i + 6];
        final width = (bytes[i + 7] << 8) | bytes[i + 8];
        return (width, height);
      }
      i += 2 + length;
    }
    return null;
  }

  /// [bytes] without its metadata (A69 review: EXIF carries GPS, camera
  /// owner and serial numbers): every APP1–APP15 segment (EXIF, XMP, ICC,
  /// Adobe…) and every comment (COM), before and between scans, is
  /// dropped, and so is anything after EOI. SOI, APP0 (JFIF), the tables,
  /// the frame headers and each scan's entropy-coded data (with its 0xFF00
  /// stuffing and RST0–RST7 markers) stay byte for byte. Adobe APP14 goes
  /// too: the phone's encoder writes plain YCbCr JFIF, which needs no
  /// colour-transform flag. `null` when [bytes] isn't a whole JPEG this can
  /// walk (no EOI, a segment past the end).
  static Uint8List? stripMetadata(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
    final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
    var i = 2;
    while (i + 1 < bytes.length) {
      if (bytes[i] != 0xFF) return null;
      final marker = bytes[i + 1];
      if (marker == 0xFF) {
        i++;
        continue;
      }
      if (marker == 0xD9) {
        // EOI: whatever follows is dropped.
        out.add(const [0xFF, 0xD9]);
        return out.takeBytes();
      }
      if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
        out.add(bytes.sublist(i, i + 2));
        i += 2;
        continue;
      }
      if (i + 3 >= bytes.length) return null;
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      if (length < 2 || i + 2 + length > bytes.length) return null;
      final end = i + 2 + length;
      final metadata = (marker >= 0xE1 && marker <= 0xEF) || marker == 0xFE;
      if (!metadata) out.add(bytes.sublist(i, end));
      i = end;
      if (marker == 0xDA) {
        // The scan's entropy-coded data runs to the next marker that isn't
        // stuffing (FF00) or a restart (FFD0–FFD7).
        final start = i;
        while (i + 1 < bytes.length) {
          if (bytes[i] == 0xFF) {
            final next = bytes[i + 1];
            if (next == 0x00 || (next >= 0xD0 && next <= 0xD7)) {
              i += 2;
              continue;
            }
            if (next != 0xFF) break;
          }
          i++;
        }
        out.add(bytes.sublist(start, i));
      }
    }
    return null;
  }
}
