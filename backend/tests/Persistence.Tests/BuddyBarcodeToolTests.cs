using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using FitnessBuddy.Modules.Catalog.Contracts;

namespace FitnessBuddy.Persistence.Tests;

// R1 security audit (Buddy medium): lookup_barcode is an outbound channel (Open Food Facts), so the model may only look up digits
// the user typed in this message as a whole run, in a message that names a barcode. A composed code (e.g. a date + a weight with a valid check digit) never reaches
// the lookup, cache included.
[Trait("Rule", "09.4-barcode-exfiltration")]
public sealed class BuddyBarcodeToolTests
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    [Theory]
    [InlineData("barcode 6281007025178 what is it", "6281007025178", true)]
    [InlineData("UPC: 6281007025178", "6281007025178", true)]
    [InlineData("شو هاد الباركود 6281007025178", "6281007025178", true)]
    [InlineData("6281007025178", "6281007025178", false)]
    [InlineData("my birthday is 19900117", "19900117", false)]
    [InlineData("I ate lean beef and beans; my birthday is 19900117", "19900117", false)]
    [InlineData("EAN-13: 6281007025178", "6281007025178", true)]
    [InlineData("I weighed 82.5 kg on 20261107", "2026110708252", false)]
    [InlineData("barcode 62810070251789 please", "6281007025178", false)]
    [InlineData("barcode 96281007025178 please", "6281007025178", false)]
    [InlineData("what's in this photo?", "6281007025178", false)]
    public async Task Only_a_barcode_the_user_typed_this_turn_is_looked_up(string message, string code, bool looked)
    {
        var facts = new CountingBarcodes();
        var tools = new ServerTools(null!, facts, new User(), null!, null!);
        var ws = new TurnWorkspace { MessageText = message };
        var result = await tools.RunAsync(new AgentToolCall("call-1", "lookup_barcode", "{\"code\":\"" + code + "\"}"), ws, Ct);
        Assert.Equal(looked ? 1 : 0, facts.Calls);
        if (!looked) { Assert.Contains("\"notStated\"", result, StringComparison.Ordinal); }
    }

    private sealed class CountingBarcodes : IBarcodeFacts
    {
        public int Calls { get; private set; }
        public Task<BarcodeFacts?> LookupAsync(string code, Guid user, CancellationToken cancellationToken) { Calls++; return Task.FromResult<BarcodeFacts?>(null); }
    }

    private sealed class User : ICurrentUser
    {
        public Guid? UserId { get; } = Guid.NewGuid();
        public Guid? SessionId => null;
        public bool IsAuthenticated => true;
    }
}
