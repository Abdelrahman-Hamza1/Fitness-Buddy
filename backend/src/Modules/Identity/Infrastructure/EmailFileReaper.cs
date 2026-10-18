using FitnessBuddy.Modules.Identity.Application;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace FitnessBuddy.Modules.Identity.Infrastructure;

internal sealed class EmailFileReaper(IOptions<IdentityOptions> options, TimeProvider clock) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!options.Value.Enabled || !options.Value.PrivateLaptop || !options.Value.Email.LocalFile.Enabled) { return; }
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1), clock);
        do { Prune(options.Value.Email.LocalFile.Directory, clock); }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
    internal static void Prune(string path, TimeProvider clock)
    {
        if (!Path.IsPathFullyQualified(path) || !Directory.Exists(path) || new DirectoryInfo(path).LinkTarget is not null) { throw new InvalidOperationException("Invalid private email directory."); }
        foreach (var file in new DirectoryInfo(path).EnumerateFiles("*.json"))
        {
            if (file.LinkTarget is not null) { throw new InvalidOperationException("Linked email files are forbidden."); }
            if (file.LastWriteTimeUtc <= clock.GetUtcNow().AddMinutes(-10).UtcDateTime) { file.Delete(); }
        }
    }
}
