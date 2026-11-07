using System.Text.RegularExpressions;
using ArchUnitNET.Loader;
using static ArchUnitNET.Fluent.ArchRuleDefinition;

namespace FitnessBuddy.Architecture.Tests;

// The confirmation guard (TD-128, 06 §1.2): Buddy emits proposals and never writes user data. Only the app's ChangeSetApplier
// writes, after a user tap (D-079). The Buddy module therefore has no path to the user-data module (not even its contracts),
// and every SQL write it issues targets its own content-free `buddy` schema.
[Trait("Req", "AQ-01")]
public sealed partial class ConfirmationGuardTests
{
    private static readonly System.Reflection.Assembly Buddy = typeof(FitnessBuddy.Modules.Buddy.BuddyModule).Assembly;
    private static readonly System.Reflection.Assembly UserData = typeof(FitnessBuddy.Modules.UserData.UserDataModule).Assembly;

    [Fact]
    public void Buddy_module_references_no_user_data_write_path()
    {
        Assert.DoesNotContain(Buddy.GetReferencedAssemblies(), name => name.Name == UserData.GetName().Name);
        var architecture = new ArchLoader().LoadAssemblies(Buddy, UserData).Build();
        var userDataTypes = architecture.Types.Concat(architecture.ReferencedTypes)
            .Where(type => type.FullName.StartsWith("FitnessBuddy.Modules.UserData", StringComparison.Ordinal)).ToArray();
        Assert.NotEmpty(userDataTypes);
        var rule = Types().That().ResideInNamespaceMatching("^FitnessBuddy\\.Modules\\.Buddy(\\.|$)").Should().NotDependOnAny(userDataTypes);
        var violations = rule.Evaluate(architecture).Where(result => !result.Passed).ToArray();
        Assert.True(violations.Length == 0, string.Join('\n', violations.Select(result => result.Description)));
    }

    [Fact]
    public void Buddy_sql_writes_only_its_own_schema()
    {
        var root = Path.Combine(Repo(), "backend", "src", "Modules", "Buddy");
        var files = Directory.EnumerateFiles(root, "*.cs", SearchOption.AllDirectories)
            .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", StringComparison.Ordinal)
                && !f.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.Ordinal)).ToArray();
        Assert.NotEmpty(files);
        var writes = files.SelectMany(f => Write().Matches(File.ReadAllText(f)).Select(m => (File: Path.GetFileName(f), Target: m.Groups[1].Value))).ToArray();
        Assert.NotEmpty(writes);
        Assert.All(writes, w => Assert.True(w.Target.StartsWith("buddy.", StringComparison.Ordinal), $"{w.File} writes {w.Target}"));
    }

    private static string Repo()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null && !File.Exists(Path.Combine(dir.FullName, "backend", "FitnessBuddy.slnx"))) { dir = dir.Parent; }
        return dir?.FullName ?? throw new InvalidOperationException("Repository root not found.");
    }

    // INSERT INTO x, UPDATE x, DELETE FROM x (also with an interpolated {table} under the buddy schema).
    [GeneratedRegex(@"\b(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+([a-z_]+\.[a-z_{}]+)", RegexOptions.IgnoreCase)] private static partial Regex Write();
}
