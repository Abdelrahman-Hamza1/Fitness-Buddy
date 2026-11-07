using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>The static agent-v1 system prompt (TD-124): rules, tool guidance, claims, safety and tone; first in every send.</summary>
internal static class AgentPrompt
{
    public const string Version = "agent-v1";
    public static readonly string Text = Read();
    private static string Read()
    {
        using var stream = typeof(AgentPrompt).Assembly.GetManifestResourceStream("FitnessBuddy.Modules.Buddy.Prompts.agent-v1.txt")!;
        using var reader = new StreamReader(stream); return reader.ReadToEnd();
    }
}

/// <summary>What one round did, for the trace view and the content-free log line.</summary>
internal sealed class RoundLog
{
    public List<BuddyTraceStep> Steps { get; } = [];
    public List<string> Tools { get; } = [];
    public int Sends { get; set; }
    public int ProposalIndex { get; set; }
    /// <summary>kcal of each food card of this round, when code could compute it (for the fast-path one-liner).</summary>
    public List<double?> FoodCardKcal { get; } = [];
    public string Outcome { get; set; } = "none";
}

/// <summary>The round's tokens: the live transport (final events), and the work token (disconnect, newer attempt or the turn deadline).</summary>
internal sealed record RoundControl(Func<bool> DeadlineHit, CancellationToken Transport, CancellationToken Work);

/// <summary>
/// Our own tool loop (TD-124, 06 §2). Per step: check the turn budget (including this send's projected input) and reserve a send
/// for this attempt (the ledger decides and fences superseded attempts), call the model with the declared tools, honour at most
/// six calls, run server tools inline, emit proposals for action tools, pause for phone tools with a sealed continuation, end on
/// a terminal tool or final text. The turn deadline covers model and tool work alike. At any limit or quota: a templated
/// wrap-up with no send. The stop button closes the stream, which cancels the in-flight send.
/// </summary>
internal sealed partial class BuddyAgent(IAgentLedger ledger, IAgentModel model, IContinuationSealer sealer, ToolRunner tools, ReplyWriter writer,
    FitnessBuddy.BuildingBlocks.Auth.ICurrentUser user, TimeProvider clock, IOptions<BuddyAgentOptions> options, Exercises exercises,
    Microsoft.Extensions.Logging.ILogger<BuddyAgent> logger)
{
    // agent-v1 plus the exercise library: static per catalog release, first in every send (prompt caching, B26 D5).
    private string system = AgentPrompt.Text;

    public async Task RunAsync(TurnRun run, ITurnEventSink sink, CancellationToken transport, CancellationToken fenced)
    {
        var log = new RoundLog();
        var left = run.Budget.StartedAt.AddSeconds(options.Value.DeadlineSeconds) - clock.GetUtcNow();
        using var deadline = new CancellationTokenSource(left > TimeSpan.Zero ? left : TimeSpan.Zero, clock);
        using var work = CancellationTokenSource.CreateLinkedTokenSource(fenced, deadline.Token);
        var control = new RoundControl(() => deadline.IsCancellationRequested && !fenced.IsCancellationRequested, transport, work.Token);
        try
        {
            system = AgentPrompt.Text + Exercises.PromptBlock(await exercises.ListAsync(control.Work));
            await LoopAsync(run, sink, log, control);
        }
        catch (OperationCanceledException) when (control.DeadlineHit() && !transport.IsCancellationRequested)
        {
            // The deadline passed during model or tool work: the deterministic wrap-up (06 §2 step 5) on the live stream.
            await WrapUpAsync(run, sink, log, BuddyDoneReason.Limit, transport);
        }
        catch (Exception e) when (e is not OperationCanceledException)
        {
            // A dependency failure after the stream started: a content-free terminal error, never a broken stream.
            log.Outcome = "failed"; LogFailure(logger, e.GetType().Name, e);
            await sink.EmitAsync(new BuddyErrorEvent(BuddyTurnErrorCode.Unavailable), transport);
        }
        finally { writer.Log(run, log); }
    }

    private async Task LoopAsync(TurnRun run, ITurnEventSink sink, RoundLog log, RoundControl control)
    {
        var ws = run.Workspace; var limits = options.Value; var ct = control.Work;
        if (ws.WeeklyReview)
        {
            // B26 D3: no tools; the code header plus at most two guarded observations; a limit or quota keeps the header alone.
            await sink.EmitAsync(new BuddyStepEvent(BuddyStepCode.WritingReply), ct);
            var reason = await ReplyWriter.WeeklyAsync(run, this, sink, log, ct);
            await FinishAsync(run, sink, log, reason, control);
            return;
        }
        if (run.Round > 0) { ws.Transcript.Add(AgentMessage.Tools(ToolRunner.IngestPhone(run, ws, log))); }
        if (run.Attempt > 1 && run.PriorAttempt is { } prior) { ws.Transcript.Add(AgentMessage.User(TurnContextBuilder.PriorNote(prior, ws))); }
        var stepShown = false;
        while (true)
        {
            var gate = await ReserveAsync(run, ws.Transcript, AgentTools.Specs, ct);
            if (gate == SendGate.Superseded) { log.Outcome = "superseded"; return; }
            if (gate == SendGate.Unauthorized) { log.Outcome = "unauthorized"; await sink.EmitAsync(new BuddyErrorEvent(BuddyTurnErrorCode.Unavailable), control.Transport); return; }
            if (gate != SendGate.Reserved) { await WrapUpAsync(run, sink, log, gate == SendGate.Quota ? BuddyDoneReason.Quota : BuddyDoneReason.Limit, control.Transport); return; }
            if (!stepShown) { await sink.EmitAsync(new BuddyStepEvent(BuddyStepCode.WritingReply), ct); stepShown = true; }
            var result = await SendAsync(run, AgentTools.Specs, ct);
            log.Sends++;
            if (result.Status == AgentModelStatus.Cancelled)
            {
                if (control.DeadlineHit()) { await WrapUpAsync(run, sink, log, BuddyDoneReason.Limit, control.Transport); }
                else { log.Outcome = "cancelled"; }
                return;
            }
            if (result.Status == AgentModelStatus.Incomplete) { await WrapUpAsync(run, sink, log, BuddyDoneReason.Limit, control.Transport); return; }
            if (result.Status != AgentModelStatus.Success)
            {
                log.Outcome = JsonCode(result.Status);
                await TraceAsync(ws, log, sink, control.Transport);
                await sink.EmitAsync(new BuddyErrorEvent(result.Status == AgentModelStatus.Timeout ? BuddyTurnErrorCode.Timeout : BuddyTurnErrorCode.Unavailable), control.Transport);
                return;
            }
            if (result.Calls.Length == 0)
            {
                ws.Transcript.Add(new(AgentRole.Assistant, result.Text, [], []));
                await ReplyWriter.ReplyAsync(run, this, result.Text, sink, log, ct);
                await FinishAsync(run, sink, log, BuddyDoneReason.Answered, control);
                return;
            }
            var step = await tools.RunStepAsync(run, result, sink, log, ct);
            if (step.Phone.Length > 0)
            {
                if (run.Round + 1 > limits.MaxPhoneRounds) { await WrapUpAsync(run, sink, log, BuddyDoneReason.Limit, control.Transport); return; }
                await PauseAsync(run, step.Phone, sink, log, control.Transport);
                return;
            }
            if (step.Terminal is { } terminal)
            {
                var reason = await ReplyWriter.TerminalAsync(run, this, terminal, sink, log, ct);
                await FinishAsync(run, sink, log, reason, control);
                return;
            }
            if (step.ActionsOnly && !ws.MessageAsks && step.Proposed > 0)
            {
                // Fast path (06 §2): every call was an action and the message asked nothing → a templated one-liner, no extra send.
                await ReplyWriter.OneLinerAsync(run, log, sink, ct);
                await FinishAsync(run, sink, log, BuddyDoneReason.Answered, control);
                return;
            }
            stepShown = false;
        }
    }

    // The input bound reserved by the last admitted send, released into recorded usage by SendAsync (one round per scope).
    private long reservedInput;

    /// <summary>
    /// The budget check and the allowance send for this round's current attempt, in one ledger transaction. It reserves a
    /// conservative input bound for this send (UTF-8 bytes of everything sent ÷ 2, which over-counts Arabic and other dense
    /// scripts; a photo counts a fixed 3,000), and admits it only next to every outstanding reservation.
    /// </summary>
    internal async Task<SendGate> ReserveAsync(TurnRun run, IReadOnlyList<AgentMessage> transcript, IReadOnlyList<AgentToolSpec> specs, CancellationToken cancellationToken)
    {
        static long Bytes(string? s) => s is null ? 0 : System.Text.Encoding.UTF8.GetByteCount(s);
        var bytes = Bytes(system) + specs.Sum(t => Bytes(t.Name) + Bytes(t.Description) + Bytes(t.Schema.GetRawText()))
            + transcript.Sum(m => Bytes(m.Text) + m.Calls.Sum(c => Bytes(c.Name) + Bytes(c.ArgumentsJson)) + m.Results.Sum(r => Bytes(r.ResultJson)));
        var bound = bytes / 2 + 64 + (run.Round == 0 && transcript == run.Workspace.Transcript && run.Image is not null && !run.Workspace.WeeklyReview ? 3000 : 0);
        var gate = await ledger.ReserveSendAsync(run.TurnId, run.Round, run.Attempt, run.Guest, options.Value, bound, cancellationToken);
        if (gate == SendGate.Reserved) { reservedInput = bound; }
        return gate;
    }

    /// <summary>One send within the output budget; usage is recorded even when the stream is gone.</summary>
    internal async Task<AgentModelResult> SendAsync(TurnRun run, IReadOnlyList<AgentToolSpec> specs, CancellationToken cancellationToken,
        IReadOnlyList<AgentMessage>? transcript = null)
    {
        var limits = options.Value;
        var budget = await ledger.ReadBudgetAsync(run.TurnId, cancellationToken) ?? run.Budget;
        var maxOutput = (int)Math.Clamp(limits.MaxOutputTokens - budget.OutputTokens, 1, limits.StepOutputTokens);
        var result = await model.SendAsync(new(system, transcript ?? run.Workspace.Transcript, transcript is null && run.Round == 0 && !run.Workspace.WeeklyReview ? run.Image : null, specs,
            maxOutput, TimeSpan.FromSeconds(limits.StepTimeoutSeconds)), cancellationToken);
        using var persist = new CancellationTokenSource(TimeSpan.FromSeconds(5));
        var reserved = reservedInput; reservedInput = 0;
        await ledger.RecordSendAsync(run.TurnId, reserved, result.Usage, result.EstimatedUsd, persist.Token);
        return result;
    }

    /// <summary>Phone tools end the round: seal the workspace with the exact pending call IDs and this attempt, emit <c>phoneTools</c>.</summary>
    private async Task PauseAsync(TurnRun run, (PendingCall Pending, BuddyPhoneToolCall Call)[] phone, ITurnEventSink sink, RoundLog log, CancellationToken ct)
    {
        var budget = await ledger.ReadBudgetAsync(run.TurnId, ct) ?? run.Budget;
        var state = new ContinuationState(1, user.UserId!.Value, run.TurnId, run.Round + 1, run.Attempt, clock.GetUtcNow().AddMinutes(options.Value.ContinuationMinutes),
            budget, phone.Select(p => p.Pending).ToArray(), run.Workspace);
        var sealedText = sealer.Seal(state);
        if (sealedText.Length > 262_144) { await WrapUpAsync(run, sink, log, BuddyDoneReason.Limit, ct); return; }
        await TraceAsync(run.Workspace, log, sink, ct);
        log.Outcome = "phoneTools";
        await sink.EmitAsync(new BuddyPhoneToolsEvent(run.Round + 1, sealedText, phone.Select(p => p.Call).ToArray()), ct);
    }

    /// <summary>At any limit or quota (06 §2 step 5): no model call, a templated line and the cards already emitted.</summary>
    private async Task WrapUpAsync(TurnRun run, ITurnEventSink sink, RoundLog log, BuddyDoneReason reason, CancellationToken transport)
    {
        await sink.EmitAsync(new BuddyTextEvent(run.Workspace.CardsEmitted > 0 ? "Here's what I have so far." : "I couldn't finish that, try again."), transport);
        await DoneAsync(run, sink, log, reason, transport);
    }

    private async Task FinishAsync(TurnRun run, ITurnEventSink sink, RoundLog log, BuddyDoneReason reason, RoundControl control)
    {
        if (run.Workspace.Compact is not null) { await ReplyWriter.SummaryAsync(run, this, sink, log, control.Work); }
        await DoneAsync(run, sink, log, reason, control.Transport);
    }

    private async Task DoneAsync(TurnRun run, ITurnEventSink sink, RoundLog log, BuddyDoneReason reason, CancellationToken transport)
    {
        await TraceAsync(run.Workspace, log, sink, transport);
        var budget = await ledger.ReadBudgetAsync(run.TurnId, transport) ?? run.Budget;
        log.Outcome = JsonCode(reason);
        await sink.EmitAsync(new BuddyDoneEvent(reason, new(budget.Sends, (int)Math.Min(int.MaxValue, budget.InputTokens), (int)Math.Min(int.MaxValue, budget.OutputTokens))), transport);
    }

    private async Task TraceAsync(TurnWorkspace ws, RoundLog log, ITurnEventSink sink, CancellationToken ct)
    {
        if (ws.Trace && options.Value.TraceEnabled && log.Steps.Count > 0) { await sink.EmitAsync(new BuddyTraceEvent([.. log.Steps.Take(64)]), ct); }
    }

    internal static string JsonCode<T>(T value) where T : Enum => System.Text.Json.JsonNamingPolicy.CamelCase.ConvertName(value.ToString());

    [Microsoft.Extensions.Logging.LoggerMessage(Level = Microsoft.Extensions.Logging.LogLevel.Warning, Message = "Buddy turn round failed: {ExceptionType}")]
    private static partial void LogFailure(Microsoft.Extensions.Logging.ILogger logger, string exceptionType, Exception exception);
}
