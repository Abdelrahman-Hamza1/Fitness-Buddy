using ArchUnitNET.Loader;
using ArchitectureModel = ArchUnitNET.Domain.Architecture;

namespace FitnessBuddy.Architecture.Tests;

// Proves the architecture gate rejects real dependencies, rather than only accepting today's code (04 §3).
[Trait("Rule", "04.3-module-boundaries")]
public sealed class FixtureRulesTests
{
    private static readonly ArchitectureModel Architecture = new ArchLoader().LoadAssemblies(typeof(FixtureRulesTests).Assembly).Build();

    [Theory]
    [InlineData("Fixture.Broken.Alpha.Domain", "DomainLeak")]
    [InlineData("Fixture.Broken.Alpha.ModuleIsolation", "ModuleLeak")]
    [InlineData("Fixture.Broken.Alpha.Application", "HttpLeak")]
    [InlineData("Fixture.Broken.Beta.PublicSurface", "PublicLeak")]
    [InlineData("BuildingBlocksCore", "CoreHttpLeak")]
    [InlineData("InjectedTimeAndIds", "StaticTimeLeak")]
    [InlineData("InjectedTimeAndIds", "StaticIdLeak")]
    [InlineData("InjectedTimeAndIds", "DateTimeLeak")]
    [InlineData("InjectedTimeAndIds", "ProviderLeak")]
    [InlineData("Fixture.Broken.Alpha.Api", "ApiLeak")]
    [InlineData("Fixture.Broken.Alpha.Infrastructure", "InfrastructureLeak")]
    [InlineData("HostIsolation", "HostLeak")]
    [InlineData("NoHttpLogging", "HttpLoggingLeak")]
    [InlineData("NoHttpLogging", "HttpLoggingRegistrationLeak")]
    [InlineData("NoHttpLogging", "HttpLoggingMiddlewareLeak")]
    [InlineData("BuildingBlocksIsolation", "CoreModuleLeak")]
    [InlineData("Fixture.Broken.Alpha.ModuleIsolation", "OtherRequestLeak")]
    public void Rule_fails_on_the_broken_fixture_and_names_the_offending_type(string ruleName, string typeName)
    {
        var rules = ArchitectureRules.Create(Architecture, "Fixture.Broken.BuildingBlocks", "Fixture.Broken.Host",
            [new("Fixture.Broken.Alpha", typeof(FixtureRulesTests).Assembly), new("Fixture.Broken.Beta", typeof(FixtureRulesTests).Assembly)]);
        var violations = rules[ruleName].Evaluate(Architecture).Where(result => !result.Passed).ToArray();
        Assert.NotEmpty(violations);
        Assert.Contains(violations, violation => violation.Description.Contains(typeName, StringComparison.Ordinal));
    }

    [Fact]
    public void Rules_pass_on_the_clean_fixture_including_contract_use_and_public_request_records()
    {
        var rules = ArchitectureRules.Create(Architecture, "Fixture.Clean.BuildingBlocks", "Fixture.Clean.Host",
            [new("Fixture.Clean.Alpha", typeof(FixtureRulesTests).Assembly), new("Fixture.Clean.Beta", typeof(FixtureRulesTests).Assembly)]);
        foreach (var rule in rules.Values)
        {
            var violations = rule.Evaluate(Architecture).Where(result => !result.Passed).ToArray();
            Assert.True(violations.Length == 0, string.Join('\n', violations.Select(result => result.Description)));
        }
    }
}
