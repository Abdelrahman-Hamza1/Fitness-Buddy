using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>A terminal call (ask_user, decline) that ends the turn after its event.</summary>
internal sealed record TerminalCall(string Name, object Args);
/// <summary>What a model step's calls produced.</summary>
internal sealed record StepResult((PendingCall Pending, BuddyPhoneToolCall Call)[] Phone, TerminalCall? Terminal, bool ActionsOnly, int Proposed);

/// <summary>
/// Runs one step's tool calls (06 §2 step 4): at most six are honoured (the rest get <c>tooMany</c>); server tools run one
/// after another (each ≤ 5 s), actions in call order (their index makes the proposal IDs), phone calls are collected for the pause,
/// and the first terminal call ends the turn. Every honoured call gets a result for the model; phone results come with the
/// next round.
/// </summary>
internal sealed partial class ToolRunner(IOptions<BuddyAgentOptions> options, TimeProvider clock, ServerTools server, ActionTools actions,
    FitnessBuddy.BuildingBlocks.Ids.IIdGenerator ids, Microsoft.Extensions.Logging.ILogger<ToolRunner> logger)
{
    public async Task<StepResult> RunStepAsync(TurnRun run, AgentModelResult step, ITurnEventSink sink, RoundLog log, CancellationToken ct)
    {
        var ws = run.Workspace;
        ws.Transcript.Add(new(AgentRole.Assistant, step.Text.Length > 0 ? step.Text : null, step.Calls, []));
        var results = new Dictionary<string, string>(StringComparer.Ordinal);
        var phone = new List<(PendingCall, BuddyPhoneToolCall)>();
        var serverCalls = new List<(AgentToolCall Call, ToolDef Def)>();
        TerminalCall? terminal = null; var actionsOnly = true; var proposed = 0;
        for (var i = 0; i < step.Calls.Length; i++)
        {
            var call = step.Calls[i];
            var definition = AgentTools.Find(call.Name);
            log.Tools.Add(definition?.Name ?? "unknown");
            if (definition is null) { results[call.CallId] = AgentTools.Error("unknownTool"); actionsOnly = false; continue; }
            if (i >= options.Value.MaxCallsPerStep) { results[call.CallId] = AgentTools.Error("tooMany"); continue; }
            var started = clock.GetTimestamp();
            switch (definition.Kind)
            {
                case ToolKind.Server:
                    actionsOnly = false;
                    serverCalls.Add((call, definition));
                    continue;
                case ToolKind.Phone:
                    actionsOnly = false;
                    if (PhoneTools.Prepare(call, ws, ids.NewId()) is { } prepared) { phone.Add(prepared); }
                    else { results[call.CallId] = AgentTools.Error("invalidArgs"); }
                    break;
                case ToolKind.Action:
                    var mark = ws.Claims.Count;
                    var outcome = await Guarded(call.Name, () => actions.RunAsync(call, run, log, ct), e => new ActionOutcome(null, AgentTools.Error(e)));
                    results[call.CallId] = AgentTools.WithFacts(outcome.ResultJson, ws.Claims[mark..]);
                    if (outcome.Proposal is { } proposal) { await sink.EmitAsync(proposal, ct); proposed++; }
                    break;
                case ToolKind.Terminal:
                    actionsOnly = false;
                    if (terminal is not null) { results[call.CallId] = AgentTools.Error("oneTerminalPerStep"); break; }
                    terminal = Terminal(call, ws, out var refused);
                    results[call.CallId] = refused ?? AgentTools.Result(new { ok = true });
                    break;
            }
            Trace(log, call, results.GetValueOrDefault(call.CallId), started);
        }
        foreach (var code in serverCalls.Select(c => c.Def.Step).OfType<BuddyStepCode>().Distinct()) { await sink.EmitAsync(new BuddyStepEvent(code), ct); }
        // Sequential, not parallel: the tools share the workspace (handles, claims) and the scoped catalog connection.
        foreach (var (call, _) in serverCalls)
        {
            var started = clock.GetTimestamp(); var before = ws.Claims.Count;
            results[call.CallId] = AgentTools.WithFacts(await RunServerAsync(call, ws, ct), ws.Claims[before..]);
            Trace(log, call, results[call.CallId], started);
        }
        if (phone.Count > 0)
        {
            foreach (var code in phone.Select(p => AgentTools.Find(step.Calls.First(c => c.CallId == p.Item1.ProviderCallId).Name)!.Step).OfType<BuddyStepCode>().Distinct())
            { await sink.EmitAsync(new BuddyStepEvent(code), ct); }
        }
        // A terminal call wins over phone reads in the same step: those are answered as skipped.
        if (terminal is not null)
        {
            foreach (var (pending, _) in phone) { results[pending.ProviderCallId] = AgentTools.Error("skipped"); }
            phone.Clear();
        }
        // Phone calls get their results from the phone; everything else answers now.
        var answered = step.Calls.Where(c => results.ContainsKey(c.CallId)).Select(c => new AgentToolResult(c.CallId, results[c.CallId])).ToArray();
        if (answered.Length > 0) { ws.Transcript.Add(AgentMessage.Tools(answered)); }
        return new([.. phone], terminal, actionsOnly && phone.Count == 0 && terminal is null, proposed);
    }

    /// <summary>A server tool, bounded to 5 s (TD-124); a failure is a result for the model, never an exception for the turn.</summary>
    private async Task<string> RunServerAsync(AgentToolCall call, TurnWorkspace ws, CancellationToken ct)
    {
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(ct, timeout.Token);
        try { return await Guarded(call.Name, () => server.RunAsync(call, ws, linked.Token), AgentTools.Error); }
        catch (OperationCanceledException) when (!ct.IsCancellationRequested) { return AgentTools.Error("timeout"); }
    }

    /// <summary>
    /// A dependency failure (database, catalog, OFF) becomes the closed tool error <c>unavailable</c> for the model, logged by type
    /// only; cancellation (disconnect, newer attempt, the turn deadline) still propagates.
    /// </summary>
    private async Task<T> Guarded<T>(string tool, Func<Task<T>> run, Func<string, T> failed)
    {
        try { return await run(); }
        catch (OperationCanceledException) { throw; }
#pragma warning disable CA1031 // A tool's dependency failure is a closed result for the model, never a broken stream.
        catch (Exception e)
#pragma warning restore CA1031
        {
            LogToolFailure(logger, tool, e.GetType().Name, e);
            return failed("unavailable");
        }
    }

    [Microsoft.Extensions.Logging.LoggerMessage(Level = Microsoft.Extensions.Logging.LogLevel.Warning, Message = "Buddy tool {Tool} failed: {ExceptionType}")]
    private static partial void LogToolFailure(Microsoft.Extensions.Logging.ILogger logger, string tool, string exceptionType, Exception exception);

    /// <summary>Phone results of the round being continued, as tool results for the model (IDs → handles, numbers → claims).</summary>
    public static AgentToolResult[] IngestPhone(TurnRun run, TurnWorkspace ws, RoundLog log)
    {
        var results = PhoneTools.Ingest(run, ws);
        foreach (var pending in run.Answered) { log.Tools.Add(pending.Tool); }
        return results;
    }

    private static TerminalCall? Terminal(AgentToolCall call, TurnWorkspace ws, out string? refused)
    {
        refused = null;
        if (call.Name == "ask_user")
        {
            var ask = AgentTools.Bind<AskUserArgs>(call);
            if (ask is null || string.IsNullOrWhiteSpace(ask.Text) || ask.Options is not { Length: >= 2 and <= 4 }) { refused = AgentTools.Error("invalidArgs"); return null; }
            if (ws.Questions >= 2) { refused = AgentTools.Error("questionLimit"); return null; }
            return new(call.Name, ask);
        }
        var decline = AgentTools.Bind<DeclineArgs>(call);
        if (decline is null) { refused = AgentTools.Error("invalidArgs"); return null; }
        return new(call.Name, decline);
    }

    internal void Trace(RoundLog log, AgentToolCall call, string? result, long started)
    {
        static string Cap(string? s, int n) => s is null ? "" : s.Length <= n ? s : s[..n];
        log.Steps.Add(new(call.Name, Cap(call.ArgumentsJson, 2000), Cap(result, 500), (int)clock.GetElapsedTime(started).TotalMilliseconds, 0, 0));
    }

}
