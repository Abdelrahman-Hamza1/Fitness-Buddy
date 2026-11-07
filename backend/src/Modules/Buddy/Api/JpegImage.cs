namespace FitnessBuddy.Modules.Buddy.Api;

/// <summary>
/// A label photo is checked before any allowance is reserved (Codex B26 S-minor): the whole base64 decodes, the bytes are a JPEG
/// (SOI, a frame header, a scan header followed by entropy data, EOI at the end) and the frame is at most 1024 px on each side.
/// </summary>
internal static class JpegImage
{
    public const int MaxSide = 1024;

    public static bool Valid(string base64)
    {
        if (base64.Length is < 8 or > 400_000 || base64.Length % 4 != 0) { return false; }
        var bytes = new byte[base64.Length / 4 * 3];
        if (!Convert.TryFromBase64String(base64, bytes, out var n)) { return false; }
        var data = bytes.AsSpan(0, n);
        if (data.Length < 4 || data[0] != 0xFF || data[1] != 0xD8 || data[^2] != 0xFF || data[^1] != 0xD9) { return false; }
        // Walk the marker segments: a frame header (SOFn, not DHT/JPG/DAC) with its height and width, then a scan header (SOS)
        // with entropy-coded data before the final EOI.
        var i = 2; var frame = false;
        while (i + 4 <= data.Length)
        {
            if (data[i] != 0xFF) { return false; }
            var marker = data[i + 1];
            if (marker == 0xFF) { i++; continue; }
            if (marker is 0xD8 or 0x01 or (>= 0xD0 and <= 0xD7)) { i += 2; continue; }
            if (marker == 0xD9) { return false; } // end before any scan
            var length = (data[i + 2] << 8) | data[i + 3];
            if (length < 2 || i + 2 + length > data.Length) { return false; }
            if (marker == 0xDA) { return frame && i + 2 + length < data.Length - 2; }
            if (marker is >= 0xC0 and <= 0xCF and not 0xC4 and not 0xC8 and not 0xCC)
            {
                if (length < 7 || frame) { return false; }
                var height = (data[i + 5] << 8) | data[i + 6];
                var width = (data[i + 7] << 8) | data[i + 8];
                if (height is <= 0 or > MaxSide || width is <= 0 or > MaxSide) { return false; }
                frame = true;
            }
            i += 2 + length;
        }
        return false;
    }
}
