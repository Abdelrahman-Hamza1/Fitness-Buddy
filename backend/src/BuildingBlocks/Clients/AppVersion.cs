using System.Diagnostics.CodeAnalysis;
using System.Globalization;

namespace FitnessBuddy.BuildingBlocks.Clients;

/// <summary>
/// An app version, strictly <c>MAJOR.MINOR.PATCH</c>: three non-negative integers without leading zeros, no
/// pre-release or build suffix. Ordered numerically (<c>0.10.0 &gt; 0.9.9</c>).
/// </summary>
public readonly record struct AppVersion(int Major, int Minor, int Patch) : IComparable<AppVersion>
{
    /// <summary>The contract's pattern for <c>ClientConfig.minimumAppVersion</c>; <see cref="TryParse"/> accepts exactly these strings.</summary>
    public const string Pattern = @"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$";

    public static bool TryParse([NotNullWhen(true)] string? text, out AppVersion version)
    {
        version = default;
        if (text is null)
        {
            return false;
        }

        var span = text.AsSpan();
        Span<Range> parts = stackalloc Range[4];
        if (span.Split(parts, '.') != 3
            || !TryParsePart(span[parts[0]], out var major)
            || !TryParsePart(span[parts[1]], out var minor)
            || !TryParsePart(span[parts[2]], out var patch))
        {
            return false;
        }

        version = new AppVersion(major, minor, patch);
        return true;
    }

    public int CompareTo(AppVersion other) =>
        Major != other.Major ? Major.CompareTo(other.Major)
        : Minor != other.Minor ? Minor.CompareTo(other.Minor)
        : Patch.CompareTo(other.Patch);

    public static bool operator <(AppVersion left, AppVersion right) => left.CompareTo(right) < 0;

    public static bool operator >(AppVersion left, AppVersion right) => left.CompareTo(right) > 0;

    public static bool operator <=(AppVersion left, AppVersion right) => left.CompareTo(right) <= 0;

    public static bool operator >=(AppVersion left, AppVersion right) => left.CompareTo(right) >= 0;

    public override string ToString() => string.Create(CultureInfo.InvariantCulture, $"{Major}.{Minor}.{Patch}");

    // ASCII digits only (int.TryParse would also take signs, whitespace and other digit scripts).
    private static bool TryParsePart(ReadOnlySpan<char> part, out int value)
    {
        value = 0;
        if (part.IsEmpty || (part.Length > 1 && part[0] == '0'))
        {
            return false;
        }

        foreach (var c in part)
        {
            if (!char.IsAsciiDigit(c))
            {
                return false;
            }
        }

        return int.TryParse(part, NumberStyles.None, CultureInfo.InvariantCulture, out value);
    }
}
