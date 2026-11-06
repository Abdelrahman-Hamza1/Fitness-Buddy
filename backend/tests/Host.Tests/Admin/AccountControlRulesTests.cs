using FitnessBuddy.Modules.Admin.Application;
using FitnessBuddy.Modules.Admin.Domain;

namespace FitnessBuddy.Host.Tests.Admin;

// B24: the pure confirmation and limit boundaries of the account controls (AD-007 typed id and 15-minute sign-in, AD-011
// limit 0–1000, closed reason codes, opaque device keys).
[Trait("Req", "AD-007")]
[Trait("Req", "AD-011")]
public sealed class AccountControlRulesTests
{
    private static readonly Guid Account = Guid.CreateVersion7();

    [Fact]
    [Trait("Rule", "B24.P2-typed-id")]
    public void The_typed_id_must_be_this_accounts_in_any_uuid_spelling()
    {
        Assert.True(AccountControlRules.TypedIdMatches(Account.ToString("D"), Account));
        Assert.True(AccountControlRules.TypedIdMatches("  " + Account.ToString("D").ToUpperInvariant() + " ", Account));
        Assert.True(AccountControlRules.TypedIdMatches(Account.ToString("N"), Account));
        Assert.True(AccountControlRules.TypedIdMatches(Account.ToString("B"), Account));
        Assert.False(AccountControlRules.TypedIdMatches(Guid.CreateVersion7().ToString(), Account));
        Assert.False(AccountControlRules.TypedIdMatches(Account.ToString("D")[..35], Account));
        Assert.False(AccountControlRules.TypedIdMatches(null, Account));
        Assert.False(AccountControlRules.TypedIdMatches("", Account));
        // Over 64 characters is refused before parsing, even when it would trim to the id.
        Assert.False(AccountControlRules.TypedIdMatches(new string(' ', 30) + Account.ToString("D"), Account));
    }

    [Theory]
    [Trait("Rule", "B24.P3-limit-bounds")]
    [InlineData(null, true, null)]
    [InlineData("", true, null)]
    [InlineData("   ", true, null)]
    [InlineData("0", true, 0)]
    [InlineData(" 7 ", true, 7)]
    [InlineData("1000", true, 1000)]
    [InlineData("1001", false, null)]
    [InlineData("-1", false, null)]
    [InlineData("+5", false, null)]
    [InlineData("5.0", false, null)]
    [InlineData("1e3", false, null)]
    [InlineData("99999999999", false, null)]
    public void The_limit_is_empty_or_a_whole_number_from_0_to_1000(string? input, bool valid, int? expected)
    {
        Assert.Equal(valid, AccountControlRules.TryParseLimit(input, out var dailyCalls));
        Assert.Equal(expected, dailyCalls);
    }

    [Fact]
    [Trait("Rule", "B24.R8-recent-sign-in-boundary")]
    public void A_recent_sign_in_is_strictly_under_15_minutes()
    {
        var signedIn = DateTimeOffset.UnixEpoch.AddDays(20000);
        var principal = new AdminPrincipal(Guid.NewGuid(), "owner", "sub-owner", ConsoleRole.Operator, signedIn);
        Assert.True(principal.SignedInRecently(signedIn));
        Assert.True(principal.SignedInRecently(signedIn + TimeSpan.FromMinutes(15) - TimeSpan.FromTicks(1)));
        Assert.False(principal.SignedInRecently(signedIn + TimeSpan.FromMinutes(15)));
    }

    [Fact]
    public void Reasons_are_the_closed_codes_and_device_keys_are_32_lowercase_hex()
    {
        Assert.All(AccountControlRules.ReasonCodes, code => Assert.True(AccountControlRules.IsReason(code)));
        Assert.False(AccountControlRules.IsReason("Support"));
        Assert.False(AccountControlRules.IsReason("support "));
        Assert.False(AccountControlRules.IsReason(null));
        var key = Guid.NewGuid().ToString("N");
        Assert.True(AccountControlRules.IsDeviceKey(key));
        Assert.False(AccountControlRules.IsDeviceKey("A" + key[1..]));
        Assert.False(AccountControlRules.IsDeviceKey(key[..31]));
        Assert.False(AccountControlRules.IsDeviceKey(key + "0"));
        Assert.False(AccountControlRules.IsDeviceKey(null));
    }
}
