using System.Globalization;
using System.Security.Cryptography;
using System.Text;

namespace FitnessBuddy.Modules.Buddy.Domain;

// B25: the agent's pure state (06 §2–§4). Nothing here does I/O; the sealed continuation carries these records between rounds.

internal enum AgentRole { User, Assistant, Tool }
/// <summary>A tool call as the provider named it; <paramref name="CallId"/> is the provider's ID and never reaches the phone.</summary>
internal sealed record AgentToolCall(string CallId, string Name, string ArgumentsJson);
internal sealed record AgentToolResult(string CallId, string ResultJson);
/// <summary>One transcript entry. Images are never part of it (only round 0 sees the photo, and it is never sealed).</summary>
internal sealed record AgentMessage(AgentRole Role, string? Text, AgentToolCall[] Calls, AgentToolResult[] Results)
{
    public static AgentMessage User(string text) => new(AgentRole.User, text, [], []);
    public static AgentMessage Tools(AgentToolResult[] results) => new(AgentRole.Tool, null, [], results);
}

/// <summary>A code-labelled claim (06 §4, §7): the model writes <c>{fact:id}</c>; code renders value, unit and label together.</summary>
internal sealed record Claim(string Id, string Metric, string Operation, string? Period, double? Value, DateOnly? Date, string Unit, string Label);

/// <summary>A card emitted in this turn or an open card from the snapshot/prior attempt, addressable by its handle.</summary>
internal sealed record CardRef(string Handle, Guid ProposalId, int Revision, string Kind, string Label, bool Pending);

/// <summary>What a turn-scoped handle points at: kind f (food candidate), d (dish), e (entry), p (personal item), m (saved meal),
/// b (batch), c (card), x (exercise), w (workout session). <paramref name="Id"/> is the catalog key or local ID.</summary>
internal sealed record HandleTarget(string Kind, string Id, string Label);

/// <summary>The one turn budget (TD-124), as read from the ledger (authoritative) and mirrored in the continuation.</summary>
/// <remarks><paramref name="ReservedInput"/>: input tokens reserved by sends that haven't reported usage yet (counted in admission).</remarks>
internal sealed record TurnBudget(DateTimeOffset StartedAt, int Sends, long InputTokens, long OutputTokens, long ReservedInput = 0);

internal static class ProposalIds
{
    // A fixed namespace for Buddy proposal IDs (RFC 9562 UUIDv5); only determinism matters, the phone never derives them.
    private static readonly Guid Namespace = new("6f1c8a52-3b0e-5d47-9a61-0c2e7b4d9f13");

    /// <summary>UUIDv5 of (turnId, round, attempt, index) (TD-125): a retry's cards never reuse an earlier attempt's IDs.</summary>
    public static Guid For(Guid turnId, int round, int attempt, int index) =>
        V5(Namespace, string.Create(CultureInfo.InvariantCulture, $"{turnId:D}:{round}:{attempt}:{index}"));

    internal static Guid V5(Guid ns, string name)
    {
        var bytes = ns.ToByteArray(bigEndian: true).Concat(Encoding.UTF8.GetBytes(name)).ToArray();
#pragma warning disable CA5350 // UUIDv5 is defined over SHA-1; it is an identifier, not a security hash.
        var hash = SHA1.HashData(bytes);
#pragma warning restore CA5350
        hash[6] = (byte)((hash[6] & 0x0F) | 0x50); hash[8] = (byte)((hash[8] & 0x3F) | 0x80);
        return new Guid(hash.AsSpan(0, 16), bigEndian: true);
    }
}

/// <summary>Numbers a user message states (TD-092 literal check), and the closed day grammar check (B09 D8): interpret's own rules.</summary>
internal static class MessageNumbers
{
    public static HashSet<decimal> Parse(string text) => ParsedIntentRules.Numbers(text);
    public static bool Day(string? hint) => ParsedIntentRules.Day(hint);
}
