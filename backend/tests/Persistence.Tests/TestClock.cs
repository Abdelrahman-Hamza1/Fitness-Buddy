namespace FitnessBuddy.Persistence.Tests;

internal sealed class TestClock : TimeProvider
{
    private DateTimeOffset now = new(2026, 10, 16, 10, 0, 0, TimeSpan.Zero);
    public override DateTimeOffset GetUtcNow() => now;
    public void Advance(TimeSpan amount) => now += amount;
}
