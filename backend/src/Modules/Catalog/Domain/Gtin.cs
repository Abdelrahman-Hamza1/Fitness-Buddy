namespace FitnessBuddy.Modules.Catalog.Domain;

/// <summary>GS1 barcode rules shared with the app's <c>Gtin</c> (fb_domain): GTIN-8/12/13/14 with a valid
/// check digit. The lookup key is OFF's canonical form: GTIN-12 gains a leading zero, a zero-padded
/// GTIN-14 loses one. UPC-E is expanded by the app before it reaches the API.</summary>
internal static class Gtin
{
    public static string? Normalize(string? raw)
    {
        if (raw is null || raw.Length is not (8 or 12 or 13 or 14) || !raw.All(char.IsAsciiDigit) || !HasValidCheckDigit(raw)) { return null; }
        return raw.Length switch
        {
            12 => "0" + raw,
            14 when raw[0] == '0' => raw[1..],
            _ => raw,
        };
    }

    private static bool HasValidCheckDigit(string value)
    {
        var sum = 0;
        for (int i = value.Length - 2, weight = 3; i >= 0; i--, weight = 4 - weight) { sum += (value[i] - '0') * weight; }
        return (sum + value[^1] - '0') % 10 == 0;
    }
}
