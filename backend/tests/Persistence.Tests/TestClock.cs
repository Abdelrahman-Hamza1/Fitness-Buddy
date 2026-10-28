namespace FitnessBuddy.Persistence.Tests;

internal sealed class TestClock : TimeProvider
{
    private DateTimeOffset now;
    public TestClock() : this(new DateTimeOffset(2026, 10, 16, 10, 0, 0, TimeSpan.Zero)) { }
    public TestClock(DateTimeOffset start) => now = start;
    public override DateTimeOffset GetUtcNow() => now;
    public void Advance(TimeSpan amount) => now += amount;
}
