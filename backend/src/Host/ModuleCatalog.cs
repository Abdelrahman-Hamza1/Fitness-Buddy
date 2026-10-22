using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Catalog;
using FitnessBuddy.Modules.Account;
using FitnessBuddy.Modules.Identity;
using FitnessBuddy.Modules.UserData;
using FitnessBuddy.Modules.Buddy;

namespace FitnessBuddy.Host;

/// <summary>
/// Every module of the API, listed explicitly (no assembly scanning, S03 plan D12). A new module is one line here.
/// The architecture tests check the rules over these modules' assemblies.
/// </summary>
public static class ModuleCatalog
{
    public static IReadOnlyList<IModule> All { get; } = [new IdentityModule(), new AccountModule(), new UserDataModule(), new BuddyModule(), new CatalogModule(), new FitnessBuddy.Modules.Usage.UsageModule()];
}
