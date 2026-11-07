using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

/// <summary>The turn budget and limits (TD-124, config <c>Buddy:Agent</c>).</summary>
internal sealed class BuddyAgentOptions
{
    /// <summary>Absolute path of the 32-byte continuation key (base64 in the file); empty = the agent routes answer 503.</summary>
    public string SealKeyFile { get; set; } = "";
    public bool TraceEnabled { get; set; }
    public int DeadlineSeconds { get; set; } = 60;
    public int MaxSends { get; set; } = 10;
    public int MaxPhoneRounds { get; set; } = 3;
    public int MaxInputTokens { get; set; } = 64_000;
    public int MaxOutputTokens { get; set; } = 8_000;
    public int StepOutputTokens { get; set; } = 2_000;
    public int StepTimeoutSeconds { get; set; } = 25;
    public int MaxCallsPerStep { get; set; } = 6;
    public int ContinuationMinutes { get; set; } = 10;
    public int HeartbeatSeconds { get; set; } = 10;
    public int Concurrency { get; set; } = 4;
    public int RegisteredDailyMessages { get; set; } = 100;
    public int RegisteredDailySends { get; set; } = 400;
    public int GuestDailyMessages { get; set; } = 30;
    public int GuestDailySends { get; set; } = 120;

    public bool Valid() => DeadlineSeconds is >= 5 and <= 300 && MaxSends is >= 1 and <= 30 && MaxPhoneRounds is >= 0 and <= 3
        && MaxInputTokens is >= 1000 and <= 400_000 && MaxOutputTokens is >= 200 and <= 64_000 && StepOutputTokens is >= 200 and <= 8_000
        && StepTimeoutSeconds is >= 1 and <= 120 && MaxCallsPerStep is >= 1 and <= 6 && ContinuationMinutes is >= 1 and <= 30
        && HeartbeatSeconds is >= 1 and <= 60 && Concurrency is >= 1 and <= 32
        && GuestDailyMessages is >= 1 and <= 1000 && RegisteredDailyMessages >= GuestDailyMessages && RegisteredDailyMessages <= 1000
        && GuestDailySends is >= 1 and <= 4000 && RegisteredDailySends >= GuestDailySends && RegisteredDailySends <= 4000
        && (SealKeyFile.Length == 0 || Path.IsPathFullyQualified(SealKeyFile));
}

internal enum RoundGateStatus { Run, AlreadyRan, Expired, Limited, Unauthorized, Invalid }
/// <summary>Phone results a continue brings: their digest (a retry must repeat them) and size for the turn's disclosure budget.</summary>
internal sealed record PhoneDisclosure(string Digest, int Rows, int Bytes);
/// <summary>Whether a round may run (TD-125): attempt 1, or 2 for a retry; <see cref="Budget"/> is the ledger's (authoritative) view.</summary>
internal sealed record RoundGate(RoundGateStatus Status, int Attempt = 0, TurnBudget? Budget = null, int? Limit = null, bool DisclosureExceeded = false);
internal enum SendGate { Reserved, Limit, Quota, Unauthorized, Superseded }

/// <summary>Content-free turn and round rows (06 §3.4). Every method rechecks the live session.</summary>
internal interface IAgentLedger
{
    /// <summary>Round 0. A new turn reserves its one allowance message (denied → Limited); <paramref name="ackTurn"/> acknowledges the previous turn.</summary>
    Task<RoundGate> BeginStartAsync(Guid turnId, Guid? ackTurn, bool guest, CancellationToken cancellationToken);
    /// <summary>
    /// Round 1–3; acknowledges round − 1, whose current attempt must be <paramref name="producerAttempt"/> (a continuation from a
    /// superseded attempt is invalid). A first post records the results' digest and adds them to the turn's disclosure counters;
    /// a retry must bring the same digest and reuses that reservation.
    /// </summary>
    Task<RoundGate> BeginContinueAsync(Guid turnId, int round, int producerAttempt, PhoneDisclosure disclosure, CancellationToken cancellationToken);
    /// <summary>
    /// One physical send for this round's current attempt (else Superseded): admits it only if recorded input + every outstanding
    /// reservation + <paramref name="projectedInput"/> fits the turn's input budget, then reserves that bound and an allowance send.
    /// </summary>
    Task<SendGate> ReserveSendAsync(Guid turnId, int round, int attempt, bool guest, BuddyAgentOptions limits, long projectedInput, CancellationToken cancellationToken);
    /// <summary>Reconciles a send's input reservation to the reported usage; a send with no reported usage keeps its reservation as spent.</summary>
    Task RecordSendAsync(Guid turnId, long reservedInput, TokenUsage? usage, decimal? estimatedUsd, CancellationToken cancellationToken);
    Task<TurnBudget?> ReadBudgetAsync(Guid turnId, CancellationToken cancellationToken);
    /// <summary>The terminal event was flushed (completed) or the stream broke first (cancelled); a superseded attempt changes nothing.</summary>
    Task CompleteRoundAsync(Guid turnId, int round, int attempt, bool cancelled, CancellationToken cancellationToken);
}

/// <summary>AES-256-GCM continuation (TD-125), bound to user, turn, round and API version.</summary>
internal interface IContinuationSealer
{
    bool Available { get; }
    string Seal(ContinuationState state);
    /// <summary>Null when the text was tampered with, sealed by another key, or bound to another user/turn/round.</summary>
    ContinuationState? Open(string sealedText, Guid userId, Guid turnId, int round);
}

/// <summary>Writes one event to the stream and flushes it (06 §3.3).</summary>
internal interface ITurnEventSink
{
    ValueTask EmitAsync(BuddyTurnEvent turnEvent, CancellationToken cancellationToken);
}

internal enum AgentModelStatus { Success, Refused, Incomplete, Timeout, Cancelled, Unavailable }
internal sealed record AgentToolSpec(string Name, string Description, System.Text.Json.JsonElement Schema);
internal sealed record AgentModelRequest(string System, IReadOnlyList<AgentMessage> Transcript, string? ImageBase64,
    IReadOnlyList<AgentToolSpec> Tools, int MaxOutputTokens, TimeSpan Timeout);
internal sealed record AgentModelResult(AgentModelStatus Status, string Text, AgentToolCall[] Calls, TokenUsage? Usage, decimal? EstimatedUsd, double ElapsedMs);

/// <summary>One model step over declared tools only (no automatic invocation, TD-124).</summary>
internal interface IAgentModel
{
    Task<AgentModelResult> SendAsync(AgentModelRequest request, CancellationToken cancellationToken);
}
