using ArchUnitNET.Fluent;
using ArchUnitNET.Loader;
using ArchUnitNET.xUnitV3;
using FitnessBuddy.BuildingBlocks;
using static ArchUnitNET.Fluent.ArchRuleDefinition;
using ArchitectureModel = ArchUnitNET.Domain.Architecture;
using Assembly = System.Reflection.Assembly;

namespace FitnessBuddy.Architecture.Tests;

/// <summary>Layer rules from 04-backend: dependencies point inward, Host is the composition root.</summary>
public sealed class LayerRulesTests
{
    private static readonly Assembly HostAssembly = typeof(Program).Assembly;

    private static readonly ArchitectureModel Architecture = new ArchLoader()
        .LoadAssemblies(BuildingBlocksAssembly.Assembly, HostAssembly)
        .Build();

    [Fact]
    public void BuildingBlocks_does_not_depend_on_Host()
    {
        IArchRule rule = Types().That().ResideInAssembly(BuildingBlocksAssembly.Assembly)
            .Should().NotDependOnAny(Types().That().ResideInAssembly(HostAssembly));

        rule.Check(Architecture);
    }
}
