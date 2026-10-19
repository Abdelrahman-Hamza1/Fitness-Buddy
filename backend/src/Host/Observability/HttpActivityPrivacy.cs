using System.Diagnostics;
using OpenTelemetry;

namespace FitnessBuddy.Host.Observability;

// Request URLs are inputs, including arbitrary path segments on failed/unmatched routes.
internal sealed class HttpActivityPrivacy : BaseProcessor<Activity>
{
    private static readonly HashSet<string> AllowedTags = new(StringComparer.Ordinal)
    { "http.request.method", "http.response.status_code", "http.route", "network.protocol.version", "url.scheme", "server.port", "error.type" };

    public override void OnEnd(Activity data)
    {
        if (data.Kind != ActivityKind.Server) { return; }
        Sanitize(data, data.GetTagItem("http.route") as string);
    }

    internal static void Sanitize(Activity activity, string? route)
    {
        foreach (var tag in activity.TagObjects.ToArray())
        {
            if (!AllowedTags.Contains(tag.Key)) { activity.SetTag(tag.Key, null); }
        }
        foreach (var item in activity.Baggage.ToArray()) { activity.SetBaggage(item.Key, null); }
        var method = activity.GetTagItem("http.request.method") as string;
        method = method is "GET" or "POST" or "DELETE" or "PUT" or "PATCH" or "HEAD" or "OPTIONS" ? method : "OTHER";
        activity.SetTag("http.request.method", method);
        activity.SetTag("http.route", route ?? "/{unmatched}");
        activity.DisplayName = method + " " + (route ?? "/{unmatched}");
        activity.SetStatus(activity.Status);
    }
}
