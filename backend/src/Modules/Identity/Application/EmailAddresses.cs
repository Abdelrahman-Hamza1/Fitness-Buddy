namespace FitnessBuddy.Modules.Identity.Application;

/// <summary>
/// How Identity keys an email address: sign-in, linking, erasure and the console's exact lookup must agree, or an account
/// stops being found. Email sign-in stores only the keyed hash (<see cref="LookupDomain"/>) as the identity subject.
/// </summary>
internal static class EmailAddresses
{
    /// <summary>The HMAC domain of an address (the pepper keys it; see <c>IIdentityTokens.ProtectLookup</c>).</summary>
    public const string LookupDomain = "email-address";

    public static string Normalize(string address) => address.Trim().ToLowerInvariant();
}
