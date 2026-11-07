using System.Globalization;
using System.Text;
using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Application;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Features;

namespace FitnessBuddy.Modules.Buddy.Api;

/// <summary>
/// The turn stream framing (06 §3.3, TD-125): <c>id: {turnId}:{round}:{seq}</c> + one <c>data:</c> JSON line per event, flushed per
/// event; a <c>: ping</c> comment every heartbeat interval; no buffering, no caching, no compression. Writes are serialized,
/// so a heartbeat never interleaves with an event.
/// </summary>
internal sealed class SseTurnWriter : ITurnEventSink, IAsyncDisposable
{
    private static readonly byte[] Ping = Encoding.UTF8.GetBytes(": ping\n\n");
    private readonly HttpResponse response;
    private readonly JsonSerializerOptions json;
    private readonly string prefix;
    private readonly SemaphoreSlim gate = new(1, 1);
    private readonly CancellationTokenSource stop;
    private readonly Task heartbeat;
    private int seq;

    private SseTurnWriter(HttpResponse response, JsonSerializerOptions json, Guid turnId, int round, TimeSpan interval, TimeProvider clock, CancellationToken aborted)
    {
        this.response = response; this.json = json;
        prefix = string.Create(CultureInfo.InvariantCulture, $"id: {turnId:D}:{round}:");
        stop = CancellationTokenSource.CreateLinkedTokenSource(aborted);
        heartbeat = BeatAsync(interval, clock, stop.Token);
    }

    public static async Task<SseTurnWriter> StartAsync(HttpContext context, JsonSerializerOptions json, Guid turnId, int round, TimeSpan interval, TimeProvider clock)
    {
        var response = context.Response;
        response.StatusCode = StatusCodes.Status200OK;
        response.ContentType = "text/event-stream";
        response.Headers.CacheControl = "no-cache";
        response.Headers["X-Accel-Buffering"] = "no";
        context.Features.Get<IHttpResponseBodyFeature>()?.DisableBuffering();
        await response.StartAsync(context.RequestAborted);
        return new SseTurnWriter(response, json, turnId, round, interval, clock, context.RequestAborted);
    }

    public async ValueTask EmitAsync(BuddyTurnEvent turnEvent, CancellationToken cancellationToken)
    {
        var data = JsonSerializer.Serialize(turnEvent, json);
        await gate.WaitAsync(cancellationToken);
        try
        {
            var frame = string.Create(CultureInfo.InvariantCulture, $"{prefix}{seq++}\ndata: {data}\n\n");
            await response.Body.WriteAsync(Encoding.UTF8.GetBytes(frame), cancellationToken);
            await response.Body.FlushAsync(cancellationToken);
        }
        finally { gate.Release(); }
    }

    private async Task BeatAsync(TimeSpan interval, TimeProvider clock, CancellationToken ct)
    {
        try
        {
            while (!ct.IsCancellationRequested)
            {
                await Task.Delay(interval, clock, ct);
                await gate.WaitAsync(ct);
                try { await response.Body.WriteAsync(Ping, ct); await response.Body.FlushAsync(ct); }
                finally { gate.Release(); }
            }
        }
        catch (OperationCanceledException) { }
        catch (IOException) { }
    }

    public async ValueTask DisposeAsync()
    {
        await stop.CancelAsync();
        await heartbeat;
        stop.Dispose(); gate.Dispose();
    }
}
