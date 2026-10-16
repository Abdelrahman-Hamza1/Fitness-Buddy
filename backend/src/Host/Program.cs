// Entry point: picks the role (api | worker | migrate) from the first argument, S03 plan D14 + A1.
// The generated Program class is public in .NET 10 (ASP0027), so tests can use WebApplicationFactory<Program>.
// The api role also runs at build time, when the OpenAPI document is generated (GetDocument.Insider):
// keep startup free of side effects, see backend/README.md "OpenAPI conventions".
using FitnessBuddy.Host.Roles;

if (!RoleParser.TryParse(args, out var role, out var hostArgs))
{
    await Console.Error.WriteLineAsync(RoleParser.Usage);
    return RoleParser.UsageExitCode;
}

return role switch
{
    HostRole.Api => await ApiRole.RunAsync(hostArgs),
    HostRole.Worker => await WorkerRole.RunAsync(hostArgs),
    HostRole.Migrate => await MigrateRole.RunAsync(hostArgs),
    _ => RoleParser.UsageExitCode,
};
