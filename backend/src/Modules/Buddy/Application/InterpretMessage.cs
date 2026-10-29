using FitnessBuddy.Modules.Buddy.Domain;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Buddy.Application;

internal sealed class BuddyConcurrency(IOptions<BuddyOptions> options) : IDisposable
{
    private readonly SemaphoreSlim gate = new(options.Value.Concurrency);
    public bool Enter() => gate.Wait(0);
    public void Leave() => gate.Release();
    public void Dispose() => gate.Dispose();
}
internal sealed class InterpretMessage(IInterpretLedger ledger, IProductionLlmClient provider, ResolveInterpretation resolver,
    BuddyConcurrency concurrency, IOptions<BuddyOptions> options)
{
    public async Task<InterpretResult> ExecuteAsync(InterpretInput input, CancellationToken cancellationToken)
    {
        if (!options.Value.Enabled || !concurrency.Enter()) { return new(InterpretStatus.Unavailable); }
        try
        {
            var existing = await ledger.ClaimAsync(input, cancellationToken); if (existing is not null) { return existing; }
            var result = await provider.ParseAsync(input, repairOf: null, cancellationToken);
            if (!await PersistAsync(ct => ledger.RecordAsync(input.RequestId, 1, result, ct))) { return new(InterpretStatus.Unauthorized); }
            if (result.Status == LlmStatus.InvalidOutput)
            {
                var permission = await ledger.ReserveRepairAsync(input.RequestId, cancellationToken);
                if (permission != InterpretStatus.Success) { return new(permission == InterpretStatus.Limited ? InterpretStatus.Pending : permission); }
                result = await provider.ParseAsync(input, repairOf: result.Invalid ?? InvalidOutput.Shape, cancellationToken);
                if (!await PersistAsync(ct => ledger.RecordAsync(input.RequestId, 2, result, ct))) { return new(InterpretStatus.Unauthorized); }
            }
            BuddyInterpretation interpretation;
            if (result.Status == LlmStatus.InvalidOutput)
            { interpretation = new(ParsedGrammar.Version, "gpt-6-luna", [new BuddyClarify("unknown", "unknown", "invalidInterpretation")]); }
            else if (result.Status == LlmStatus.Success && result.Message is { } parsed)
            { interpretation = await resolver.ResolveAsync(parsed, input, cancellationToken); }
            else { return new(InterpretStatus.Pending); }
            return await PersistAsync(ct => ledger.CompleteAsync(input.RequestId, interpretation, ct)) ? new(InterpretStatus.Success, interpretation) : new(InterpretStatus.Unauthorized);
        }
        catch (FitnessBuddy.BuildingBlocks.Recovery.RecoveryUnavailableException) { return new(InterpretStatus.Unavailable); }
        finally { concurrency.Leave(); }
    }
    private static async Task<bool> PersistAsync(Func<CancellationToken, Task<bool>> action)
    {
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5)); return await action(timeout.Token);
    }
}
