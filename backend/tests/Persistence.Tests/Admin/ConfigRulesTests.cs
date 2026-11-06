using FitnessBuddy.BuildingBlocks.Clients;
using FitnessBuddy.Modules.Account.Contracts;
using FitnessBuddy.Modules.Admin.Domain;
using FitnessBuddy.Modules.Identity.Contracts;

namespace FitnessBuddy.Persistence.Tests.Admin;

// B23 T1 (pure): the diff, the canonical hash, the validation rules and the minimum-version ceiling.
[Trait("Req", "AD-006")]
[Trait("Req", "AD-012")]
public sealed class ConfigRulesTests
{
    private static readonly RemoteConfigDocument Base = new("1.0.0", new Dictionary<string, bool> { ["a"] = true },
        new Dictionary<string, double> { ["proposalQuestionKcalDelta"] = 50 }, new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase) { ["buddy.ai"] = true });

    [Fact]
    public void The_diff_lists_added_removed_and_changed_keys_and_the_hash_is_canonical()
    {
        var next = Base with
        {
            MinimumAppVersion = "1.1.0",
            FeatureFlags = new Dictionary<string, bool> { ["b"] = true },
            ServerFlags = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase) { ["buddy.ai"] = false },
        };
        var changes = ConfigDiff.Compute(Base, next);
        Assert.Equal(["minimumAppVersion", "a", "b", "buddy.ai"], changes.Select(change => change.Key));
        Assert.Null(changes.Single(change => change.Key == "b").Old);
        Assert.Null(changes.Single(change => change.Key == "a").New);
        Assert.Empty(ConfigDiff.Compute(Base, Base));
        var reordered = Base with { FeatureFlags = new Dictionary<string, bool> { ["z"] = false, ["a"] = true } };
        var sorted = Base with { FeatureFlags = new Dictionary<string, bool> { ["a"] = true, ["z"] = false } };
        Assert.Equal(ConfigDiff.Hash(sorted), ConfigDiff.Hash(reordered));
        Assert.NotEqual(ConfigDiff.Hash(Base), ConfigDiff.Hash(next));
        Assert.Equal(next.ToJson(), RemoteConfigDocument.FromJson(next.ToJson())!.ToJson());
    }

    [Theory]
    [InlineData("1.0", false)]
    [InlineData("1.0.0", true)]
    public void Validation_checks_versions_names_ranges_and_switches(string minimum, bool valid)
    {
        Assert.Equal(valid, RemoteConfigRules.Validate(Base with { MinimumAppVersion = minimum }, Base).Count == 0);
        Assert.NotEmpty(RemoteConfigRules.Validate(Base with { FeatureFlags = new Dictionary<string, bool> { ["Bad Name"] = true } }, Base));
        Assert.NotEmpty(RemoteConfigRules.Validate(Base with { Thresholds = new Dictionary<string, double> { ["proposalQuestionRelativeDelta"] = 1.5 } }, Base));
        Assert.NotEmpty(RemoteConfigRules.Validate(Base with { Thresholds = new Dictionary<string, double> { ["madeUp"] = 1 } }, Base));
        Assert.NotEmpty(RemoteConfigRules.Validate(Base with { Thresholds = new Dictionary<string, double> { ["proposalQuestionKcalDelta"] = double.NaN } }, Base));
        Assert.NotEmpty(RemoteConfigRules.Validate(Base with { ServerFlags = new Dictionary<string, bool> { ["invented"] = true } }, Base));
    }

    [Fact]
    public void The_ceiling_is_the_newest_reported_version_and_reach_counts_older_installs()
    {
        var reach = InstallReach.From([new InstallCount("1.4.0", "android", 1), new InstallCount("1.2.0", "android", 4), new InstallCount("bad", "ios", 9)]);
        Assert.Equal(new AppVersion(1, 4, 0), reach.Newest);
        Assert.Equal(CeilingRefusal.None, reach.CheckRaise(new AppVersion(1, 4, 0)));
        Assert.Equal(CeilingRefusal.AboveNewestReported, reach.CheckRaise(new AppVersion(1, 4, 1)));
        Assert.Equal(4, reach.BlockedBy(new AppVersion(1, 4, 0)));
        Assert.Equal(CeilingRefusal.NoActiveInstalls, InstallReach.From([]).CheckRaise(new AppVersion(0, 0, 1)));
        Assert.True(InstallReach.Raises("1.0.0", "1.0.1"));
        Assert.False(InstallReach.Raises("1.0.1", "1.0.0"));
    }
}
