namespace FitnessBuddy.TestData;

// B19 PA1: a row ID every sync entity admits. The row-ID wire rule (contracts/README.md
// § "Targets semantic rules") needs the natural profile ID and UUIDv7 goalPhase/targetSettings
// IDs, and W5 (B21) the natural weeklyPlanDay ID of the fixture's weekday; a UUIDv7 is also a valid ID for every other entity. Compile-linked into Persistence.Tests.
internal static class SyncTestIds
{
    // naturalId('profile', 'self'), pinned to the corpus constant in BodyTargetsPayloadTests.
    public static readonly Guid ProfileRowId = new("f0b8e132-056c-5b98-8c9b-ff9a6dc1bb96");

    // naturalId('weeklyPlanDay', '6'): the fixture's Saturday (W5, B21), pinned to the corpus in WorkoutPayloadTests.
    public static readonly Guid SaturdayPlanDayRowId = new("ff8f65bc-5c85-521a-a8e9-7fb18060ccfe");

    public static Guid For(string entity) => entity switch
    {
        "profile" => ProfileRowId,
        "weeklyPlanDay" => SaturdayPlanDayRowId,
        _ => Guid.CreateVersion7(),
    };
}
