using FitnessBuddy.BuildingBlocks.Auth;
using FitnessBuddy.BuildingBlocks.Features;
using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Application;

internal enum TurnProblem { None, Unauthorized, AlreadyRan, Limited, Unavailable }

/// <summary>A round ready to stream: the ledger let it run as <paramref name="Attempt"/>, with the ledger's budget.</summary>
internal sealed record TurnRun(Guid TurnId, bool Guest, int Round, int Attempt, TurnBudget Budget, TurnWorkspace Workspace, string? Image,
    PendingCall[] Answered, PhoneResultInput[] Results, TurnPriorAttempt? PriorAttempt, bool DisclosureExceeded = false);

/// <summary>Either a problem before streaming, a stream that carries only one error event, or a round to run.</summary>
internal sealed record TurnPrepared(TurnProblem Problem, int? Limit = null, BuddyTurnErrorCode? StreamError = null, TurnRun? Run = null);

/// <summary>
/// In-process attempt fencing (TD-125): when attempt 2 of a round starts, attempt 1 of the same user/turn/round is cancelled
/// before it can emit more. The ledger fences sends and completion by attempt too (across processes).
/// </summary>
internal sealed class AttemptFences
{
    private readonly Lock gate = new();
    private readonly Dictionary<(Guid User, Guid Turn, int Round), (int Attempt, CancellationTokenSource Stop)> running = [];

    public Lease Enter(Guid user, Guid turn, int round, int attempt)
    {
        var stop = new CancellationTokenSource();
        lock (gate)
        {
            if (running.TryGetValue((user, turn, round), out var current))
            {
                if (current.Attempt > attempt) { stop.Cancel(); return new(this, (user, turn, round), stop); }
                current.Stop.Cancel();
            }
            running[(user, turn, round)] = (attempt, stop);
        }
        return new(this, (user, turn, round), stop);
    }

    private void Leave((Guid, Guid, int) key, CancellationTokenSource stop)
    {
        lock (gate) { if (running.TryGetValue(key, out var current) && current.Stop == stop) { running.Remove(key); } }
        stop.Dispose();
    }

    internal sealed class Lease(AttemptFences owner, (Guid, Guid, int) key, CancellationTokenSource stop) : IDisposable
    {
        public CancellationToken Token => stop.Token;
        public void Dispose() => owner.Leave(key, stop);
    }
}

internal sealed class AgentConcurrency(IOptions<BuddyAgentOptions> options) : IDisposable
{
    private readonly SemaphoreSlim gate = new(options.Value.Concurrency);
    public bool Enter() => gate.Wait(0);
    public void Leave() => gate.Release();
    public void Dispose() => gate.Dispose();
}

/// <summary>
/// The two turn use cases (06 §3): decide before streaming (problem responses), then run the round and close its ledger row.
/// The ledger is authoritative for the budget; the continuation only carries the workspace and the pending call IDs.
/// </summary>
internal sealed class RunTurn(IAgentLedger ledger, IContinuationSealer sealer, BuddyAgent agent, ICurrentUser user,
    TimeProvider clock, IOptions<BuddyOptions> buddy, IFeatureFlags flags, AgentConcurrency concurrency, AttemptFences fences)
{
    public bool Available => buddy.Value.Enabled && flags.IsEnabled("buddy.ai") && sealer.Available;

    public async Task<TurnPrepared> PrepareStartAsync(TurnStartInput input, bool guest, CancellationToken cancellationToken)
    {
        if (!Available) { return new(TurnProblem.Unavailable); }
        var gate = await ledger.BeginStartAsync(input.TurnId, input.AckTurn, guest, cancellationToken);
        return gate.Status switch
        {
            RoundGateStatus.Run => new(TurnProblem.None, Run: new(input.TurnId, guest, 0, gate.Attempt, gate.Budget!, TurnContextBuilder.Build(input),
                input.Image, [], [], input.PriorAttempt)),
            RoundGateStatus.Limited => new(TurnProblem.Limited, gate.Limit),
            RoundGateStatus.AlreadyRan => new(TurnProblem.AlreadyRan),
            RoundGateStatus.Expired => new(TurnProblem.None, StreamError: BuddyTurnErrorCode.Expired),
            RoundGateStatus.Invalid => new(TurnProblem.None, StreamError: BuddyTurnErrorCode.Invalid),
            _ => new(TurnProblem.Unauthorized),
        };
    }

    public async Task<TurnPrepared> PrepareContinueAsync(TurnContinueInput input, bool guest, CancellationToken cancellationToken)
    {
        if (!Available) { return new(TurnProblem.Unavailable); }
        if (user.UserId is not { } owner) { return new(TurnProblem.Unauthorized); }
        var state = sealer.Open(input.Continuation, owner, input.TurnId, input.Round);
        if (state is null) { return new(TurnProblem.None, StreamError: BuddyTurnErrorCode.Invalid); }
        if (state.ExpiresAt <= clock.GetUtcNow()) { return new(TurnProblem.None, StreamError: BuddyTurnErrorCode.Expired); }
        // Exactly the pending call IDs, each once, each for its own tool (06 §3.2); anything else is invalid with no send.
        var pending = state.Pending.ToDictionary(p => p.CallId);
        if (input.Results.Length != pending.Count || input.Results.Select(r => r.CallId).Distinct().Count() != pending.Count
            || input.Results.Any(r => !pending.TryGetValue(r.CallId, out var call) || call.Tool != r.Name && r.Name != "unsupported" || r.Ok != r.Data.HasValue))
        { return new(TurnProblem.None, StreamError: BuddyTurnErrorCode.Invalid); }
        var gate = await ledger.BeginContinueAsync(input.TurnId, input.Round, state.ProducerAttempt, PhoneTools.Disclosure(input.Results), cancellationToken);
        return gate.Status switch
        {
            RoundGateStatus.Run => new(TurnProblem.None, Run: new(input.TurnId, guest, input.Round, gate.Attempt, gate.Budget!, state.Workspace, null,
                state.Pending, input.Results, input.PriorAttempt, gate.DisclosureExceeded)),
            RoundGateStatus.AlreadyRan => new(TurnProblem.AlreadyRan),
            RoundGateStatus.Expired => new(TurnProblem.None, StreamError: BuddyTurnErrorCode.Expired),
            RoundGateStatus.Invalid => new(TurnProblem.None, StreamError: BuddyTurnErrorCode.Invalid),
            _ => new(TurnProblem.Unauthorized),
        };
    }

    /// <summary>Runs the round; the round row is completed once its terminal event is flushed, else cancelled (retry-eligible).</summary>
    public async Task RunAsync(TurnRun run, ITurnEventSink sink, CancellationToken cancellationToken)
    {
        using var fence = fences.Enter(user.UserId!.Value, run.TurnId, run.Round, run.Attempt);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, fence.Token);
        var tracked = new TerminalTracker(sink, fence.Token);
        var entered = concurrency.Enter();
        try
        {
            if (entered) { await agent.RunAsync(run, tracked, cancellationToken, linked.Token); }
            else { await tracked.EmitAsync(new BuddyErrorEvent(BuddyTurnErrorCode.Unavailable), cancellationToken); }
        }
        catch (OperationCanceledException) when (fence.Token.IsCancellationRequested && !cancellationToken.IsCancellationRequested)
        {
            // Superseded by a newer attempt: stop without another event (the phone already retried).
        }
        finally
        {
            if (entered) { concurrency.Leave(); }
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            await ledger.CompleteRoundAsync(run.TurnId, run.Round, run.Attempt, cancelled: !tracked.Terminal, timeout.Token);
        }
    }

    private sealed class TerminalTracker(ITurnEventSink inner, CancellationToken fence) : ITurnEventSink
    {
        public bool Terminal { get; private set; }
        public async ValueTask EmitAsync(BuddyTurnEvent turnEvent, CancellationToken cancellationToken)
        {
            // A superseded attempt emits nothing more.
            fence.ThrowIfCancellationRequested();
            await inner.EmitAsync(turnEvent, cancellationToken);
            if (turnEvent is BuddyPhoneToolsEvent or BuddyDoneEvent or BuddyErrorEvent) { Terminal = true; }
        }
    }
}
