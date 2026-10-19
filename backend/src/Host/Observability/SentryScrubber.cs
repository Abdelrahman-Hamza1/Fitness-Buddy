namespace FitnessBuddy.Host.Observability;

/// <summary>TD-058: the final privacy boundary before an error event leaves the process.</summary>
internal static class SentryScrubber
{
    private static readonly HashSet<string> AllowedHeaders = new(StringComparer.OrdinalIgnoreCase)
    {
        "X-App-Version", "X-Platform", "Content-Type", "Content-Length",
    };

    public static SentryEvent Scrub(SentryEvent sentryEvent)
    {
        var request = sentryEvent.Request;
        foreach (var key in request.Headers.Keys.Where(key => !AllowedHeaders.Contains(key)).ToArray())
        {
            request.Headers.Remove(key);
        }

        // URL/transaction names can contain unmatched paths as well as route arguments.
        request.Url = null;
        sentryEvent.TransactionName = null;
        foreach (var tag in sentryEvent.Tags.Keys.ToArray()) { sentryEvent.UnsetTag(tag); }
        request.QueryString = null;
        request.Data = null;
        request.Cookies = null;
        request.Env.Clear();
        request.Other.Clear();
        sentryEvent.User = new SentryUser();
        foreach (var exception in sentryEvent.SentryExceptions ?? [])
        {
            exception.Value = null;
            exception.Mechanism?.Data.Clear();
        }

        if (sentryEvent.Message is { } message)
        {
            message.Formatted = null;
            message.Params = null;
        }

        // The pinned SDK exposes read-only views backed by dictionaries (verified by the envelope test).
        ((IDictionary<string, object?>)sentryEvent.Extra).Clear();
        return sentryEvent;
    }
}
