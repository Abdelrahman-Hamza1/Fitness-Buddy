using FitnessBuddy.BuildingBlocks.Web.Modules;
using FitnessBuddy.Modules.Account;
using FitnessBuddy.Modules.UserData;

namespace FitnessBuddy.Host;

/// <summary>
/// Every module of the API, listed explicitly (no assembly scanning, S03 plan D12). A new module is one line here.
/// The architecture tests check the rules over these modules' assemblies.
/// </summary>
public static class ModuleCatalog
{
    public static IReadOnlyList<IModule> All { get; } = [new AccountModule(), new UserDataModule()];
}
