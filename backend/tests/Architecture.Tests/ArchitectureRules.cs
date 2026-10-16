using System.Text.RegularExpressions;
using ArchUnitNET.Domain;
using ArchUnitNET.Domain.Dependencies;
using ArchUnitNET.Fluent;
using ArchUnitNET.Fluent.Syntax.Elements.Types;
using FitnessBuddy.BuildingBlocks.Web.Modules;
using static ArchUnitNET.Fluent.ArchRuleDefinition;
using ArchitectureModel = ArchUnitNET.Domain.Architecture;
using Assembly = System.Reflection.Assembly;

namespace FitnessBuddy.Architecture.Tests;

internal sealed record ModuleBoundary(string RootNamespace, Assembly Assembly);

/// <summary>04 §3, 09 §4 and S03 A7. Real modules and deliberately broken fixtures use these same rules.</summary>
internal static class ArchitectureRules
{
    public static IReadOnlyDictionary<string, IArchRule> Create(ArchitectureModel architecture,
        string buildingBlocksRoot, string hostRoot, IReadOnlyList<ModuleBoundary> modules)
    {
        // ArchUnit's namespace providers only include loaded types. Referenced stubs must also be targets,
        // or framework bans silently pass unless every framework assembly is loaded (expensive and fragile).
        var allTypes = architecture.Types.Concat(architecture.ReferencedTypes).Distinct().ToArray();
        IEnumerable<IType> In(params string[] roots) => allTypes.Where(type => roots.Any(root => Under(type.FullName, root)));
        var moduleRoots = modules.Select(module => module.RootNamespace).ToArray();
        var modulePattern = Union(moduleRoots);
        var hostTypes = In(hostRoot).Concat(allTypes.Where(type => hostRoot == "FitnessBuddy.Host" && type.FullName == "Program"));
        var rules = new Dictionary<string, TypesShouldConjunction>(StringComparer.Ordinal)
        {
            ["BuildingBlocksIsolation"] = Types().That().ResideInNamespaceMatching(Pattern(buildingBlocksRoot))
                .Should().NotDependOnAny(In([hostRoot, .. moduleRoots])),
            ["BuildingBlocksCore"] = Types().That().ResideInNamespaceMatching(Pattern(buildingBlocksRoot))
                .And().DoNotResideInNamespaceMatching(Pattern(buildingBlocksRoot + ".Web"))
                .Should().NotDependOnAny(In("Microsoft.AspNetCore")),
            ["HostIsolation"] = Types().That().DoNotResideInNamespaceMatching(Pattern(hostRoot))
                .And().DoNotHaveFullNameMatching("^Program(\\+|$)")
                .Should().NotDependOnAny(hostTypes),
            ["NoHttpLogging"] = Types().That().ResideInNamespaceMatching($"{Pattern(buildingBlocksRoot)}|{Pattern(hostRoot)}|{modulePattern}")
                .Should().NotDependOnAny(allTypes.Where(type => type.Assembly.FullName.StartsWith("Microsoft.AspNetCore.HttpLogging,", StringComparison.Ordinal))),
            ["InjectedTimeAndIds"] = Types().That().ResideInNamespaceMatching(modulePattern)
                .Should().NotCallAny(architecture.Types.SelectMany(type => type.Members).SelectMany(member => member.Dependencies)
                    .OfType<MethodCallDependency>().Select(call => call.TargetMember).OfType<MethodMember>().Distinct()
                    .Where(method => Regex.IsMatch(method.FullName, @"System\.(DateTime(Offset)?::get_(UtcNow|Now)|TimeProvider::get_System|Guid::NewGuid)\("))),
        };

        foreach (var module in modules)
        {
            var root = module.RootNamespace;
            rules[$"{root}.Domain"] = Types().That().ResideInNamespaceMatching(Pattern(root + ".Domain"))
                .Should().NotDependOnAny(In(root + ".Api", root + ".Application", root + ".Infrastructure", "Microsoft.AspNetCore", "Microsoft.EntityFrameworkCore"));
            rules[$"{root}.Application"] = Types().That().ResideInNamespaceMatching(Pattern(root + ".Application"))
                .Should().NotDependOnAny(In(root + ".Api", root + ".Infrastructure", "Microsoft.AspNetCore"));
            rules[$"{root}.Api"] = Types().That().ResideInNamespaceMatching(Pattern(root + ".Api"))
                .Should().NotDependOnAny(In(root + ".Infrastructure"));
            rules[$"{root}.Infrastructure"] = Types().That().ResideInNamespaceMatching(Pattern(root + ".Infrastructure"))
                .Should().NotDependOnAny(In(root + ".Api"));
            var others = modules.Where(other => other != module).ToArray();
            var foreignInternals = allTypes.Where(type => others.Any(other =>
                Under(type.FullName, other.RootNamespace) && !Under(type.FullName, other.RootNamespace + ".Contracts")));
            rules[$"{root}.ModuleIsolation"] = Types().That().ResideInNamespaceMatching(Pattern(root))
                .Should().NotDependOnAny(foreignInternals);

            // Public Api records are the validation-generator exception (S03 handoff). The module-isolation
            // rule still prevents another module consuming them; response DTOs remain internal by convention.
            var allowed = module.Assembly.GetTypes().Where(type =>
                typeof(IModule).IsAssignableFrom(type) ||
                (Under(type.FullName!, root + ".Api") && type.GetMethod("<Clone>$") is not null));
            rules[$"{root}.PublicSurface"] = Types().That().ResideInNamespaceMatching(Pattern(root))
                .And().ArePublic().And().DoNotResideInNamespaceMatching(Pattern(root + ".Contracts"))
                .And().AreNot(allowed).Should().NotExist();
        }

        // Some modules have no Domain/Infrastructure yet. Broken fixtures prove these same rules fail
        // positively, while real tests assert the module catalogue is populated.
        return rules.ToDictionary(pair => pair.Key, pair => (IArchRule)pair.Value.WithoutRequiringPositiveResults(), StringComparer.Ordinal);
    }

    private static bool Under(string name, string root) => name.StartsWith(root + ".", StringComparison.Ordinal);

    private static string Pattern(string root) => $"^{Regex.Escape(root)}(\\.|$)";

    private static string Union(IEnumerable<string> roots) => string.Join('|', roots.Select(Pattern).DefaultIfEmpty("(?!)"));
}
