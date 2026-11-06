using System.Globalization;
using System.Text;

namespace FitnessBuddy.Modules.Admin.Domain;

/// <summary>
/// AD-016 CSV export (RFC 4180). Fields that a spreadsheet would run as a formula (starting with = + - @, tab or CR) get a
/// leading apostrophe, so an operator-typed reason can't become a formula when the file is opened.
/// </summary>
internal static class AuditCsv
{
    public static readonly string[] Header = ["id", "occurred_at_utc", "actor", "area", "action", "target", "outcome", "reason", "before", "after"];

    public static string Line(IEnumerable<string?> fields) => string.Join(',', fields.Select(Field)) + "\r\n";

    public static string Field(string? value)
    {
        if (string.IsNullOrEmpty(value)) { return ""; }
        if (value[0] is '=' or '+' or '-' or '@' or '\t' or '\r') { value = "'" + value; }
        return value.AsSpan().IndexOfAny(",\"\r\n") >= 0 ? "\"" + value.Replace("\"", "\"\"", StringComparison.Ordinal) + "\"" : value;
    }

    public static string Time(DateTimeOffset value) => value.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture);

    public static StringBuilder Start() => new(Line(Header));
}
