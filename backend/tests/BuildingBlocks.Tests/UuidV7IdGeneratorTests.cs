using FitnessBuddy.BuildingBlocks.Ids;

namespace FitnessBuddy.BuildingBlocks.Tests;

public sealed class UuidV7IdGeneratorTests
{
    [Fact]
    public void UuidV7IdGenerator_returns_version_7_ids_ordered_by_time()
    {
        var time = new ManualTimeProvider(new DateTimeOffset(2026, 10, 16, 8, 0, 0, TimeSpan.Zero));
        var generator = new UuidV7IdGenerator(time);

        var ids = new List<Guid>();
        for (var i = 0; i < 50; i++)
        {
            ids.Add(generator.NewId());
            time.Advance(TimeSpan.FromMilliseconds(1));
        }

        Assert.All(ids, id => Assert.Equal(7, id.Version));
        // The canonical lowercase text sorts like the timestamp (that is what UUIDv7 is for).
        Assert.Equal(ids.Select(id => id.ToString()), ids.Select(id => id.ToString()).Order(StringComparer.Ordinal));
        Assert.Equal(ids.Count, ids.Distinct().Count());

        // The first 48 bits are the injected clock's Unix milliseconds.
        var first = ids[0].ToString("N");
        var unixMs = Convert.ToInt64(first[..12], 16);
        Assert.Equal(new DateTimeOffset(2026, 10, 16, 8, 0, 0, TimeSpan.Zero).ToUnixTimeMilliseconds(), unixMs);
    }

    private sealed class ManualTimeProvider(DateTimeOffset now) : TimeProvider
    {
        private DateTimeOffset now = now;

        public override DateTimeOffset GetUtcNow() => now;

        public void Advance(TimeSpan by) => now += by;
    }
}
