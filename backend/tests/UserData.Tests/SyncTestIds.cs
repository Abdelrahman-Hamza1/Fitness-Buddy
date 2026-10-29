namespace FitnessBuddy.TestData;

// B19 PA1: a row ID every sync entity admits. The row-ID wire rule (contracts/README.md
// § "Targets semantic rules") needs the natural profile ID and UUIDv7 goalPhase/targetSettings
// IDs; a UUIDv7 is also a valid ID for every other entity. Compile-linked into Persistence.Tests.
internal static class SyncTestIds
{
    // naturalId('profile', 'self'), pinned to the corpus constant in BodyTargetsPayloadTests.
    public static readonly Guid ProfileRowId = new("f0b8e132-056c-5b98-8c9b-ff9a6dc1bb96");

    public static Guid For(string entity) => entity == "profile" ? ProfileRowId : Guid.CreateVersion7();
}
