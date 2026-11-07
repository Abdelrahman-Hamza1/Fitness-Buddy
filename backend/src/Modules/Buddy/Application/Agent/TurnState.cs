using System.Text.Json;
using FitnessBuddy.Modules.Buddy.Domain;

namespace FitnessBuddy.Modules.Buddy.Application;

// B25: what the phone sends (mapped from the Api records, so Application never depends on Api) and the turn workspace
// the agent works on. The workspace travels sealed between rounds; nothing of it is stored on the server.

internal sealed record TurnOutcome(Guid ProposalId, string Kind, string Status, string Label);
internal sealed record TurnHistoryEntry(Guid MessageId, string Role, string Text, TurnOutcome[] Outcomes);
internal sealed record TurnSummary(string Text, int Revision, Guid Watermark);
internal sealed record TurnCompact(TurnHistoryEntry[] Evicted, int PreviousRevision);
internal sealed record TurnPortion(string Label, double? G, BuddyNutrients Nutrients);
internal sealed record TurnPersonalItem(Guid Ref, string Kind, string[] Names, string[] Aliases, string? State, BuddyNutrients? Per100,
    BuddyServing[] Servings, TurnPortion[] Portions);
internal sealed record TurnDefault(string Kind, string Subject, string Value);
internal sealed record TurnProfile(ContextMemory[] Memory, TurnDefault[] Defaults, bool Halal, string MassUnit, string LengthUnit, RamadanContext Ramadan);
internal sealed record TurnTargets(double? Kcal, double? ProteinG, double? CarbsG, double? FatG, double? FiberG);
internal sealed record TurnOpenCard(Guid ProposalId, int Revision, string Kind, string Summary);
internal sealed record TurnSnapshot(DateTimeOffset Now, int TzOffsetMin, MealSlot[] Slots, BuddyNutrients Today, TurnTargets? Targets, TurnOpenCard[] OpenCards);
internal sealed record TurnPriorCard(Guid ProposalId, string Status, int Revision, string Line);
internal sealed record TurnPriorAttempt(int Attempt, TurnPriorCard[] Cards);
internal sealed record TurnStartInput(Guid TurnId, bool WeeklyReview, string Text, string? Image, TurnHistoryEntry[] History, TurnSummary? Summary,
    TurnCompact? Compact, TurnPersonalItem[] Personal, TurnProfile Profile, TurnSnapshot Snapshot, Guid? AckTurn, TurnPriorAttempt? PriorAttempt, bool Trace);
/// <summary>A phone-tool result; <paramref name="Data"/> is the tool's data as JSON (already schema-bound), <paramref name="Rows"/> its row count.</summary>
internal sealed record PhoneResultInput(Guid CallId, string Name, bool Ok, string? Error, JsonElement? Data, int Rows);
internal sealed record TurnContinueInput(Guid TurnId, int Round, string Continuation, PhoneResultInput[] Results, TurnPriorAttempt? PriorAttempt);

/// <summary>A phone call the round is waiting for: the server-minted <paramref name="CallId"/>, the provider's call ID and the tool.</summary>
internal sealed record PendingCall(Guid CallId, string ProviderCallId, string Tool, string ArgsJson);
internal sealed record CompactState(string? OldSummary, string[] Evicted, int PreviousRevision, Guid Watermark);

/// <summary>The turn's working state (06 §4): transcript, handle map, claims, cards and the personal data seen so far.</summary>
internal sealed class TurnWorkspace
{
    public string MessageText { get; set; } = "";
    public string Language { get; set; } = "english";
    public string Script { get; set; } = "latin";
    public bool MessageAsks { get; set; }
    public bool Trace { get; set; }
    public string MassUnit { get; set; } = "kg";
    public string LengthUnit { get; set; } = "cm";
    public DateTimeOffset Now { get; set; }
    public int TzOffsetMin { get; set; }
    public RamadanContext Ramadan { get; set; } = new(false, null, null);
    public MealSlot[] Slots { get; set; } = [];
    public ContextMemory[] Memory { get; set; } = [];
    public List<AgentMessage> Transcript { get; set; } = [];
    public Dictionary<string, HandleTarget> Handles { get; set; } = new(StringComparer.Ordinal);
    public Dictionary<string, int> Counters { get; set; } = new(StringComparer.Ordinal);
    public List<Claim> Claims { get; set; } = [];
    /// <summary>How many claims came from the request context (the rest came from tools this turn).</summary>
    public int ContextClaims { get; set; }
    public List<CardRef> Cards { get; set; } = [];
    /// <summary>Food candidates behind f handles (catalog facts as returned by search_foods / get_dish).</summary>
    public Dictionary<string, BuddyCandidate> Foods { get; set; } = new(StringComparer.Ordinal);
    public List<PersonalFood> PersonalFoods { get; set; } = [];
    public List<NamedReference> SavedMeals { get; set; } = [];
    public List<NamedReference> OpenBatches { get; set; } = [];
    public List<RecentEntry> Entries { get; set; } = [];
    public CompactState? Compact { get; set; }
    public int CardsEmitted { get; set; }
    public int Questions { get; set; }

    /// <summary>A new turn-scoped handle for a target (the same target keeps its handle).</summary>
    public string Handle(string kind, string id, string label)
    {
        foreach (var (handle, target) in Handles) { if (target.Kind == kind && target.Id == id) { return handle; } }
        var n = Counters.GetValueOrDefault(kind) + 1; Counters[kind] = n;
        var name = kind + n.ToString(System.Globalization.CultureInfo.InvariantCulture);
        Handles[name] = new(kind, id, label); return name;
    }
    public HandleTarget? Resolve(string? handle, string kind) =>
        handle is not null && Handles.TryGetValue(handle.Trim(), out var target) && target.Kind == kind ? target : null;

    public Claim AddClaim(string metric, string operation, string? period, double? value, DateOnly? date, string unit, string label)
    {
        var claim = new Claim("k" + (Claims.Count + 1).ToString(System.Globalization.CultureInfo.InvariantCulture), metric, operation, period, value, date, unit, label);
        Claims.Add(claim); return claim;
    }
}

/// <summary>The sealed payload (TD-125): bound to user, turn and the round it unlocks; expires after 10 minutes.</summary>
/// <remarks><paramref name="ProducerAttempt"/> is the attempt of round − 1 that sealed it; a newer attempt of that round voids it.</remarks>
internal sealed record ContinuationState(int Version, Guid UserId, Guid TurnId, int Round, int ProducerAttempt, DateTimeOffset ExpiresAt, TurnBudget Budget,
    PendingCall[] Pending, TurnWorkspace Workspace);
