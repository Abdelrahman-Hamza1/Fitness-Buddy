using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace FitnessBuddy.Modules.Buddy.Domain;

// B25 WP1: the SSE event union of the agent turn routes (06 §3.3). Each event goes out as one `data:` line
// with the SSE `id:` {turnId}:{round}:{seq}; the id is framing, not part of the JSON.

internal enum BuddyStepCode { SearchingFoods, ReadingDiary, ReadingYourFoods, ReadingBody, ReadingWorkouts, ReadingMemory, Computing, CheckingFit, WritingReply, Summarizing, SearchingExercises }
internal enum BuddyDoneReason { Answered, Asked, Declined, Limit, Quota }
internal enum BuddyTurnErrorCode { Unavailable, Timeout, Invalid, RoundAlreadyRan, Expired }

[JsonPolymorphic(TypeDiscriminatorPropertyName = "type")]
[JsonDerivedType(typeof(BuddyStepEvent), "step")]
[JsonDerivedType(typeof(BuddyTextEvent), "text")]
[JsonDerivedType(typeof(BuddyProposalEvent), "proposal")]
[JsonDerivedType(typeof(BuddyQuestionEvent), "question")]
[JsonDerivedType(typeof(BuddyPhoneToolsEvent), "phoneTools")]
[JsonDerivedType(typeof(BuddySummaryEvent), "summary")]
[JsonDerivedType(typeof(BuddyTraceEvent), "trace")]
[JsonDerivedType(typeof(BuddyDoneEvent), "done")]
[JsonDerivedType(typeof(BuddyErrorEvent), "error")]
internal abstract record BuddyTurnEvent;
internal sealed record BuddyStepEvent(BuddyStepCode Code) : BuddyTurnEvent;
internal sealed record BuddyTextEvent([property: MinLength(1), MaxLength(4000)] string Text) : BuddyTurnEvent;
/// <summary>A card: <c>proposalId</c> = UUIDv5(turnId, round, attempt, index); an update keeps the ID with revision + 1 (06 §3.4).</summary>
internal sealed record BuddyProposalEvent(Guid ProposalId, [property: Range(1, int.MaxValue)] int Revision, BuddyCardRevision? Replaces, BuddyIntent Intent) : BuddyTurnEvent;
internal sealed record BuddyCardRevision(Guid ProposalId, [property: Range(1, int.MaxValue)] int ExpectedRevision);
internal sealed record BuddyQuestionEvent([property: MinLength(1), MaxLength(1000)] string Text, [property: MinLength(2), MaxLength(4)] string[] Options) : BuddyTurnEvent;
internal sealed record BuddyPhoneToolsEvent([property: Range(1, 3)] int Round, [property: MinLength(1), MaxLength(262144)] string Continuation,
    [property: MinLength(1), MaxLength(6)] BuddyPhoneToolCall[] Calls) : BuddyTurnEvent;
internal sealed record BuddySummaryEvent([property: MinLength(1), MaxLength(1500)] string Text, [property: Range(1, int.MaxValue)] int Revision, Guid Watermark) : BuddyTurnEvent;
internal sealed record BuddyTraceEvent([property: MaxLength(64)] BuddyTraceStep[] Steps) : BuddyTurnEvent;
internal sealed record BuddyTraceStep(string Tool, string Args, string ResultSummary, int Ms, int Tokens, double Usd);
internal sealed record BuddyDoneEvent(BuddyDoneReason Reason, BuddyTurnUsage Usage) : BuddyTurnEvent;
internal sealed record BuddyTurnUsage(int Sends, int InputTokens, int OutputTokens);
internal sealed record BuddyErrorEvent(BuddyTurnErrorCode Code) : BuddyTurnEvent;
