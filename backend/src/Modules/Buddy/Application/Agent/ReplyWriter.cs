using System.Security.Cryptography;
using System.Text;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.Logging;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>
/// Everything the user reads from a turn: replies, questions, declines, the fast-path one-liner and the compaction summary.
/// Text is buffered and only then streamed in chunks (06 §3.3). Logs carry IDs, codes and counts only (09 §4).
/// </summary>
internal sealed partial class ReplyWriter(ILogger<ReplyWriter> logger)
{
    public static async Task ReplyAsync(TurnRun run, BuddyAgent agent, string text, ITurnEventSink sink, RoundLog log, CancellationToken ct)
    {
        var ws = run.Workspace;
        var check = Guard(string.IsNullOrWhiteSpace(text) ? Fallback(ws) : text.Trim(), ws);
        if (!check.Clean)
        {
            // One rewrite naming only the closed issue codes, then a template (AI-175).
            var issues = check.Issues;
            if (await RewriteAsync(run, agent, issues, log, ct) is { } rewritten) { check = Guard(rewritten, ws); }
            if (!check.Clean) { log.Outcome = "template"; check = Guard(Template(ws, check.Referenced.Length > 0 ? check.Referenced : null), ws); }
        }
        await StreamAsync(check.Rendered, sink, ct);
    }

    public static async Task<BuddyDoneReason> TerminalAsync(TurnRun run, BuddyAgent agent, TerminalCall terminal, ITurnEventSink sink, RoundLog log, CancellationToken ct)
    {
        if (terminal.Args is DeclineArgs decline)
        {
            await StreamAsync(Decline(decline.Reason), sink, ct);
            return BuddyDoneReason.Declined;
        }
        var ws = run.Workspace; var ask = (AskUserArgs)terminal.Args;
        var text = Guard(ask.Text.Trim(), ws);
        var options = ask.Options.Select(o => Guard(o.Trim(), ws)).Where(o => o.Clean && o.Rendered.Length is > 0 and <= 80).Select(o => o.Rendered).Distinct().Take(4).ToArray();
        if (options.Length < 2)
        {
            await StreamAsync(text.Clean ? text.Rendered : "Could you tell me a bit more?", sink, ct);
            return BuddyDoneReason.Answered;
        }
        ws.Questions++;
        await sink.EmitAsync(new BuddyQuestionEvent(text.Clean ? text.Rendered : "Could you tell me a bit more?", options), ct);
        return BuddyDoneReason.Asked;
    }

    /// <summary>The fast path (06 §2): "Here's your card · 640 kcal left today after this" when code can compute it, else a plain line.</summary>
    public static Task OneLinerAsync(TurnRun run, RoundLog log, ITurnEventSink sink, CancellationToken ct)
    {
        var ws = run.Workspace;
        var line = ws.CardsEmitted > 1 ? "Here are your cards: check them and confirm." : "Here's your card: check it and confirm.";
        var left = ws.Claims.Take(ws.ContextClaims).FirstOrDefault(c => c is { Metric: "kcal", Operation: "remaining", Period: "today" });
        if (left?.Value is { } remaining && log.FoodCardKcal.Count > 0 && log.FoodCardKcal.All(k => k is not null))
        {
            var after = ws.AddClaim("kcal", "remaining", "today", ClaimSet.Round(remaining - log.FoodCardKcal.Sum(k => k!.Value)), null, "kcal", "left today after this");
            line = (ws.CardsEmitted > 1 ? "Here are your cards · " : "Here's your card · ") + ReplyGuard.Render(after, ws.MassUnit, ws.LengthUnit);
        }
        return StreamAsync(line, sink, ct).AsTask();
    }

    /// <summary>
    /// Compaction (06 §6.1): one send over the old summary and the evicted entries, counted in the turn budget, guarded like a
    /// reply (one rewrite), emitted before <c>done</c>. Out of budget or still failing → no summary; the phone retries next turn.
    /// </summary>
    public static async Task SummaryAsync(TurnRun run, BuddyAgent agent, ITurnEventSink sink, RoundLog log, CancellationToken ct)
    {
        var ws = run.Workspace; var compact = ws.Compact!;
        var request = new StringBuilder("Write the new conversation summary (at most 1200 characters, plain sentences, no numbers for quantities) from the old summary and the older chat entries below. Keep lasting facts about the user's habits, plans and preferences; drop small talk. Reply with the summary only.\n\nOLD SUMMARY:\n")
            .Append(compact.OldSummary ?? "(none)").Append("\n\nOLDER ENTRIES:\n").AppendJoin('\n', compact.Evicted).ToString();
        List<AgentMessage> transcript = [AgentMessage.User(request)];
        if (await agent.ReserveAsync(run, transcript, [], ct) != SendGate.Reserved) { return; }
        await sink.EmitAsync(new BuddyStepEvent(BuddyStepCode.Summarizing), ct);
        var result = await agent.SendAsync(run, [], ct, transcript);
        log.Sends++;
        if (result.Status != AgentModelStatus.Success || string.IsNullOrWhiteSpace(result.Text)) { return; }
        var check = Guard(result.Text.Trim(), ws);
        if (!check.Clean)
        {
            transcript.Add(new(AgentRole.Assistant, result.Text, [], [])); transcript.Add(AgentMessage.User(RewriteNote(check.Issues)));
            if (await agent.ReserveAsync(run, transcript, [], ct) != SendGate.Reserved) { return; }
            result = await agent.SendAsync(run, [], ct, transcript);
            log.Sends++;
            if (result.Status != AgentModelStatus.Success || string.IsNullOrWhiteSpace(result.Text)) { return; }
            check = Guard(result.Text.Trim(), ws);
            if (!check.Clean) { return; }
        }
        var text = check.Rendered.Length > 1500 ? check.Rendered[..1500] : check.Rendered;
        ws.Compact = null;
        await sink.EmitAsync(new BuddySummaryEvent(text, compact.PreviousRevision + 1, compact.Watermark), ct);
    }

    /// <summary>
    /// The weekly review (AI-130/131, B26 D3): the code-made header, then the model's observations, one per line; code keeps at
    /// most two, each rendered and guarded. Lines that still fail after one rewrite are dropped (never a model number). A send
    /// denied by the budget or the allowance keeps the header and ends with <c>done limit|quota</c>.
    /// </summary>
    public static async Task<BuddyDoneReason> WeeklyAsync(TurnRun run, BuddyAgent agent, ITurnEventSink sink, RoundLog log, CancellationToken ct)
    {
        var ws = run.Workspace;
        var first = await ObservationsAsync(run, agent, log, null, ct);
        var kept = first.Lines; var denied = first.Denied;
        if (first.Issues.Length > 0 && denied is null)
        {
            var second = await ObservationsAsync(run, agent, log, first.Issues, ct);
            if (second.Denied is null) { if (second.Lines.Length > 0) { kept = second.Lines; } } else { denied = second.Denied; }
        }
        await StreamAsync(kept.Length > 0 ? ws.WeeklyHeader + "\n\n" + string.Join("\n", kept) : ws.WeeklyHeader, sink, ct);
        return denied switch { SendGate.Quota => BuddyDoneReason.Quota, SendGate.Limit => BuddyDoneReason.Limit, _ => BuddyDoneReason.Answered };
    }

    private sealed record Observations(string[] Lines, GuardIssue[] Issues, SendGate? Denied = null);

    private static async Task<Observations> ObservationsAsync(TurnRun run, BuddyAgent agent, RoundLog log, GuardIssue[]? rewrite, CancellationToken ct)
    {
        var ws = run.Workspace;
        if (rewrite is not null) { ws.Transcript.Add(AgentMessage.User(RewriteNote(rewrite) + " At most two lines.")); }
        var gate = await agent.ReserveAsync(run, ws.Transcript, [], ct);
        if (gate != SendGate.Reserved) { return new([], [], gate); }
        var result = await agent.SendAsync(run, [], ct);
        log.Sends++;
        if (result.Status != AgentModelStatus.Success) { return new([], []); }
        ws.Transcript.Add(new(AgentRole.Assistant, result.Text, [], []));
        var checks = result.Text.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(l => l.TrimStart('-', '*', '•', ' ').Trim()).Where(l => l.Length > 0).Take(2).Select(l => Guard(l.Length <= 300 ? l : l[..300], ws)).ToArray();
        return new([.. checks.Where(c => c.Clean && c.Rendered.Length > 0).Select(c => c.Rendered)], [.. checks.SelectMany(c => c.Issues).Distinct()]);
    }

    private static async Task<string?> RewriteAsync(TurnRun run, BuddyAgent agent, GuardIssue[] issues, RoundLog log, CancellationToken ct)
    {
        run.Workspace.Transcript.Add(AgentMessage.User(RewriteNote(issues)));
        if (await agent.ReserveAsync(run, run.Workspace.Transcript, [], ct) != SendGate.Reserved) { return null; }
        var result = await agent.SendAsync(run, [], ct);
        log.Sends++;
        if (result.Status != AgentModelStatus.Success || string.IsNullOrWhiteSpace(result.Text)) { return null; }
        run.Workspace.Transcript.Add(new(AgentRole.Assistant, result.Text, [], []));
        return result.Text.Trim();
    }

    /// <summary>The rewrite instruction names closed issue codes only, never the text that failed.</summary>
    internal static string RewriteNote(GuardIssue[] issues) =>
        $"Rewrite your last reply ({string.Join(", ", issues.Select(BuddyAgent.JsonCode))}). Refer to every quantity only as {{fact:ID}} with an ID from this turn's facts; "
        + "no other numbers except clock times, dates, day counts and small counts from 1 to 10; no moral words about food. Reply with the rewritten text only.";

    private static GuardResult Guard(string text, TurnWorkspace ws) => ReplyGuard.Check(text, ws.Claims, ws.MassUnit, ws.LengthUnit);

    /// <summary>The template after a failed rewrite: the claims the reply used, else the cards, else this turn's tool claims.</summary>
    internal static string Template(TurnWorkspace ws, Claim[]? referenced)
    {
        var claims = referenced ?? [.. ws.Claims.Skip(ws.ContextClaims).TakeLast(3)];
        if (referenced is null && ws.CardsEmitted > 0) { return "Here's what I have."; }
        return claims.Length > 0 ? "Here's what I found: " + string.Join("; ", claims.Take(3).Select(c => "{fact:" + c.Id + "}")) + "." : Fallback(ws);
    }

    internal static async ValueTask StreamAsync(string text, ITurnEventSink sink, CancellationToken ct)
    {
        // Chunks end at sentence or word boundaries, in order (06 §3.3).
        var rest = text;
        while (rest.Length > 0)
        {
            var cut = rest.Length <= 400 ? rest.Length : Math.Max(rest.LastIndexOf(' ', 399) + 1, 1);
            if (cut <= 0) { cut = Math.Min(400, rest.Length); }
            await sink.EmitAsync(new BuddyTextEvent(rest[..cut]), ct);
            rest = rest[cut..];
        }
    }

    /// <summary>Templated declines (AI-176, SF-030), never improvised.</summary>
    internal static string Decline(DeclineTopic reason) => reason switch
    {
        DeclineTopic.Medical => "I can't help with medical questions. Please ask a doctor or a registered dietitian.",
        DeclineTopic.Supplements => "I can't advise on supplements or doses. A doctor or pharmacist can help with that.",
        _ => "I can only help with food, body weight and training.",
    };

    internal static string Fallback(TurnWorkspace ws) => ws.CardsEmitted > 0 ? "Here's what I have." : "Sorry, I couldn't put that into words. Try asking again.";

    private static readonly System.Diagnostics.Metrics.Meter Metrics = new("FitnessBuddy.Buddy");
    private static readonly System.Diagnostics.Metrics.Counter<long> Rounds = Metrics.CreateCounter<long>("buddy.agent.rounds");
    private static readonly System.Diagnostics.Metrics.Counter<long> Sends = Metrics.CreateCounter<long>("buddy.agent.sends");

    public void Log(TurnRun run, RoundLog log)
    {
        Rounds.Add(1, new KeyValuePair<string, object?>("buddy.outcome", log.Outcome));
        Sends.Add(log.Sends, new KeyValuePair<string, object?>("buddy.task", "agent"));
        if (!logger.IsEnabled(LogLevel.Information)) { return; }
        var hash = Convert.ToHexString(SHA256.HashData(run.TurnId.ToByteArray()))[..12].ToLowerInvariant();
        var tools = string.Join(',', log.Tools.Take(24));
        LogRound(logger, hash, run.Round, run.Attempt, log.Outcome, log.Sends, tools, run.Workspace.CardsEmitted, AgentPrompt.Version);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Buddy turn {TurnHash} round={Round} attempt={Attempt} outcome={Outcome} sends={Sends} tools={Tools} cards={Cards} prompt={PromptVersion}")]
    private static partial void LogRound(ILogger logger, string turnHash, int round, int attempt, string outcome, int sends, string tools, int cards, string promptVersion);
}
