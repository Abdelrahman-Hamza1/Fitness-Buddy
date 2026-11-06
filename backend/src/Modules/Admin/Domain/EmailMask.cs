namespace FitnessBuddy.Modules.Admin.Domain;

/// <summary>AD-002: an email is shown as its first letter and its domain only, e.g. <c>o…@example.com</c>.</summary>
internal static class EmailMask
{
    public static string Mask(string email)
    {
        ArgumentNullException.ThrowIfNull(email);
        var trimmed = email.Trim();
        var at = trimmed.LastIndexOf('@');
        if (at <= 0 || at == trimmed.Length - 1) { return "…"; }
        return string.Concat(trimmed.AsSpan(0, 1), "…@", trimmed.AsSpan(at + 1));
    }
}
