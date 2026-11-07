using FitnessBuddy.Modules.Buddy.Api;

namespace FitnessBuddy.Persistence.Tests;

// R1 security audit (Buddy low): a turn's meal photo gets the label route's whole-payload check (a real JPEG, at most 1024 px a
// side) in the request checks that run before any allowance is reserved; anything else is a 400 on "message".
[Trait("Rule", "09.4-turn-image-validation")]
public sealed class BuddyTurnImageTests
{
    [Fact]
    public void A_turn_photo_must_be_a_whole_jpeg_of_at_most_1024_px()
    {
        var good = BuddyApiTests.Photo();
        var noScan = Convert.FromBase64String(good); noScan = [.. noScan[..^18], 0xFF, 0xD9];
        foreach (var bad in new[] { BuddyApiTests.Photo(side: 4096), good[..^8], Convert.ToBase64String(noScan), Convert.ToBase64String([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]) })
        { Assert.Equal("message", TurnRequestMapping.Invalid(Start(bad))); }
        // A valid photo passes the message check (the deliberately missing snapshot is what fails next).
        Assert.Equal("snapshot", TurnRequestMapping.Invalid(Start(good)));
    }

    private static BuddyTurnStart Start(string image) => new(Guid.CreateVersion7(), BuddyTurnMode.Chat, new BuddyTurnMessage("lunch", image),
        [], null, null, [], null!, null!, null, null, false);
}
