using ArchUnitNET.Loader;
using FitnessBuddy.BuildingBlocks;
using FitnessBuddy.Host;
using ArchitectureModel = ArchUnitNET.Domain.Architecture;

namespace FitnessBuddy.Architecture.Tests;

// Proves 04 §3 / S03 A7: clean layers, module isolation, internal visibility and injected time/ids.
[Trait("Rule", "04.3-module-boundaries")]
public sealed class LayerRulesTests
{
    // The admin console (B23) is a module outside the catalogue (admin role only); the same rules apply to it.
    private static readonly ModuleBoundary[] Modules = [.. ModuleCatalog.All.Select(module =>
        new ModuleBoundary(module.GetType().Namespace!, module.GetType().Assembly)),
        new ModuleBoundary(typeof(FitnessBuddy.Modules.Admin.AdminModule).Namespace!, typeof(FitnessBuddy.Modules.Admin.AdminModule).Assembly)];

    private static readonly ArchitectureModel Architecture = new ArchLoader()
        .LoadAssemblies([BuildingBlocksAssembly.Assembly, typeof(Program).Assembly, .. Modules.Select(module => module.Assembly)])
        .Build();

    public static TheoryData<string> RuleNames => new(ArchitectureRules.Create(Architecture,
        "FitnessBuddy.BuildingBlocks", "FitnessBuddy.Host", Modules).Keys);

    [Theory]
    [MemberData(nameof(RuleNames))]
    public void Production_code_obeys_each_architecture_rule(string ruleName)
    {
        Assert.NotEmpty(Modules);
        var rule = ArchitectureRules.Create(Architecture, "FitnessBuddy.BuildingBlocks", "FitnessBuddy.Host", Modules)[ruleName];
        var violations = rule.Evaluate(Architecture).Where(result => !result.Passed).ToArray();
        Assert.True(violations.Length == 0, string.Join('\n', violations.Select(result => result.Description)));
    }
}
