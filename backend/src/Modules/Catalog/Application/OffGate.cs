namespace FitnessBuddy.Modules.Catalog.Application;

/// <summary>Bounded OFF settings (<c>Catalog:OpenFoodFacts</c>).</summary>
internal sealed class OffOptions
{
    public bool Enabled { get; set; } = true;
    public Uri BaseUrl { get; set; } = new("https://world.openfoodfacts.org/");
    public string UserAgent { get; set; } = "FitnessBuddy/0.1 (+https://github.com/Abdelrahman-Hamza1/Fitness-Buddy)";
    public int TimeoutSeconds { get; set; } = 5;
    /// <summary>Process-wide upstream reads per minute (OFF allows about 15 product reads per minute per IP, `07` §3).</summary>
    public int ReadsPerMinute { get; set; } = 10;
    /// <summary>Upstream fetches one account may cause per hour; cache hits are free.</summary>
    public int UserFetchesPerHour { get; set; } = 30;

    public bool IsValid() => BaseUrl is { IsAbsoluteUri: true, Scheme: "https" or "http" } && UserAgent.Length is > 0 and <= 200
        && !UserAgent.Any(char.IsControl) && TimeoutSeconds is >= 1 and <= 30 && ReadsPerMinute is >= 1 and <= 60 && UserFetchesPerHour is >= 1 and <= 500;
}

internal enum GateDenial { None, UserLimited, Unavailable }

/// <summary>Process-wide OFF politeness: a sliding-window budget, a cool-down after OFF says 429/503, a per-account
/// budget for upstream fetches and one in-flight read per code (joiners are free). Time comes from the injected clock.</summary>
internal sealed class OffGate(TimeProvider clock, Microsoft.Extensions.Options.IOptions<OffOptions> options)
{
    private const int MaxTrackedUsers = 10_000;
    private readonly Lock sync = new();
    private readonly Queue<DateTimeOffset> reads = new();
    private readonly Dictionary<Guid, Queue<DateTimeOffset>> users = [];
    private readonly Dictionary<string, Task<OffFetch>> inflight = new(StringComparer.Ordinal);
    private DateTimeOffset coolDownUntil = DateTimeOffset.MinValue;

    /// <summary>The time left before OFF may be asked again, or null.</summary>
    public TimeSpan? CoolDown
    {
        get { lock (sync) { var left = coolDownUntil - clock.GetUtcNow(); return left > TimeSpan.Zero ? left : null; } }
    }

    /// <summary>Joins the running read of <paramref name="code"/>, or starts one if every budget allows it.</summary>
    public Task<OffFetch>? Begin(string code, Guid user, Func<Task<OffFetch>> fetch, out GateDenial denial)
    {
        TaskCompletionSource<OffFetch> started;
        lock (sync)
        {
            denial = GateDenial.None;
            if (inflight.TryGetValue(code, out var running)) { return running; }
            var now = clock.GetUtcNow();
            if (coolDownUntil > now) { denial = GateDenial.Unavailable; return null; }
            Trim(reads, now - TimeSpan.FromMinutes(1));
            if (reads.Count >= options.Value.ReadsPerMinute) { denial = GateDenial.Unavailable; return null; }
            if (!users.TryGetValue(user, out var mine))
            {
                if (users.Count >= MaxTrackedUsers) { PruneUsers(now); }
                mine = new Queue<DateTimeOffset>(); users[user] = mine;
            }
            Trim(mine, now - TimeSpan.FromHours(1));
            if (mine.Count >= options.Value.UserFetchesPerHour) { denial = GateDenial.UserLimited; return null; }
            reads.Enqueue(now); mine.Enqueue(now);
            started = new TaskCompletionSource<OffFetch>(TaskCreationOptions.RunContinuationsAsynchronously);
            inflight[code] = started.Task;
        }
        _ = RunAsync(code, fetch, started);
        return started.Task;
    }

    /// <summary>Seconds until this account may cause another upstream fetch (for Retry-After).</summary>
    public TimeSpan UserRetryAfter(Guid user)
    {
        lock (sync)
        {
            return users.TryGetValue(user, out var mine) && mine.Count > 0
                ? Max(mine.Peek() + TimeSpan.FromHours(1) - clock.GetUtcNow(), TimeSpan.FromSeconds(1)) : TimeSpan.FromSeconds(1);
        }
    }

    /// <summary>Seconds until the process-wide budget frees one read.</summary>
    public TimeSpan GlobalRetryAfter()
    {
        lock (sync)
        {
            var now = clock.GetUtcNow();
            if (coolDownUntil > now) { return coolDownUntil - now; }
            return reads.Count > 0 ? Max(reads.Peek() + TimeSpan.FromMinutes(1) - now, TimeSpan.FromSeconds(1)) : TimeSpan.FromSeconds(1);
        }
    }

    private async Task RunAsync(string code, Func<Task<OffFetch>> fetch, TaskCompletionSource<OffFetch> started)
    {
        try
        {
            var result = await fetch();
            if (result.RetryAfter is { } wait)
            {
                lock (sync) { coolDownUntil = Max(coolDownUntil, clock.GetUtcNow() + wait); }
            }
            Complete(code); started.TrySetResult(result);
        }
#pragma warning disable CA1031 // A failed read or cache write becomes "unavailable" for every joiner; the next request retries.
        catch (Exception)
#pragma warning restore CA1031
        {
            Complete(code); started.TrySetResult(new OffFetch(OffFetchStatus.Unavailable));
        }
    }

    private void Complete(string code) { lock (sync) { inflight.Remove(code); } }

    private void PruneUsers(DateTimeOffset now)
    {
        foreach (var (id, queue) in users.ToArray())
        {
            Trim(queue, now - TimeSpan.FromHours(1));
            if (queue.Count == 0) { users.Remove(id); }
        }
        if (users.Count >= MaxTrackedUsers) { users.Clear(); }
    }

    private static void Trim(Queue<DateTimeOffset> queue, DateTimeOffset cutoff)
    {
        while (queue.Count > 0 && queue.Peek() <= cutoff) { queue.Dequeue(); }
    }

    private static TimeSpan Max(TimeSpan a, TimeSpan b) => a > b ? a : b;
    private static DateTimeOffset Max(DateTimeOffset a, DateTimeOffset b) => a > b ? a : b;
}
