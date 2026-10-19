using Microsoft.Extensions.Logging;
using System.Diagnostics.Metrics;
using FitnessBuddy.Modules.UserData.Application;

namespace FitnessBuddy.Modules.UserData.Infrastructure;

internal sealed partial class SyncTelemetry(ILogger<SyncTelemetry> logger) : ISyncTelemetry
{
    private static readonly Meter Meter = new("FitnessBuddy.Sync");
    private static readonly Counter<long> Requests = Meter.CreateCounter<long>("sync.requests");
    private static readonly Histogram<int> Changes = Meter.CreateHistogram<int>("sync.changes");
    private static readonly Counter<long> Stale = Meter.CreateCounter<long>("sync.stale");
    private static readonly Counter<long> Invalid = Meter.CreateCounter<long>("sync.invalid");
    private static readonly Histogram<double> Latency = Meter.CreateHistogram<double>("sync.duration", "ms");
    public void Record(string operation, int changes, int stale, int invalid, double milliseconds)
    {
        var tag = new KeyValuePair<string, object?>("operation", operation);
        LogDuration(logger, operation, milliseconds);
        Requests.Add(1, tag); Changes.Record(changes, tag); Stale.Add(stale, tag); Invalid.Add(invalid, tag); Latency.Record(milliseconds, tag);
    }
    [LoggerMessage(Level = LogLevel.Debug, Message = "Sync {Operation} duration {Milliseconds} ms")]
    private static partial void LogDuration(ILogger logger, string operation, double milliseconds);
}
