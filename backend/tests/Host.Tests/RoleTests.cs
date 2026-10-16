using FitnessBuddy.Host.Roles;

namespace FitnessBuddy.Host.Tests;

public sealed class RoleTests
{
    public static TheoryData<string[], string, string[]> ValidArgs => new()
    {
        { [], nameof(HostRole.Api), [] },
        { ["api"], nameof(HostRole.Api), [] },
        { ["worker"], nameof(HostRole.Worker), [] },
        { ["migrate"], nameof(HostRole.Migrate), [] },
        { ["--contentRoot", "/x"], nameof(HostRole.Api), ["--contentRoot", "/x"] },
        { ["--environment=Testing"], nameof(HostRole.Api), ["--environment=Testing"] },
        { ["migrate", "--foo=1"], nameof(HostRole.Migrate), ["--foo=1"] },
        { ["api", "--urls", "http://localhost:5198"], nameof(HostRole.Api), ["--urls", "http://localhost:5198"] },
    };

    [Theory]
    [MemberData(nameof(ValidArgs))]
    public void Role_parser_selects_api_by_default_and_strips_the_role(string[] args, string expected, string[] expectedHostArgs)
    {
        Assert.True(RoleParser.TryParse(args, out var role, out var hostArgs));
        Assert.Equal(expected, role.ToString());
        Assert.Equal(expectedHostArgs, hostArgs);
    }

    [Theory]
    [InlineData("web")]
    [InlineData("API")]
    [InlineData("migrations")]
    [InlineData("")]
    public void Role_parser_selects_api_by_default_and_rejects_unknown_roles(string first)
    {
        Assert.False(RoleParser.TryParse([first, "--foo=1"], out _, out _));
        Assert.Equal(2, RoleParser.UsageExitCode);
    }

    [Fact]
    public async Task Migrate_role_exits_zero()
    {
        Assert.Equal(0, await MigrateRole.RunAsync(["--foo=1"]));
    }
}
